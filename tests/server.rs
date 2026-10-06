//! The whole structure, run on a PostgreSQL server of the tests' own.
//!
//! Every composed statement in `assets/sql/` and `pt-PT/assets/sql/` runs on the loaded documents
//! and finishes. Then the three answers the structure rests on are read:
//!
//! - every rule on the roster examined rows, and none of them broke it;
//! - every class of every classification stands somewhere: `exercised`, `outside` or `open`,
//!   with the reason wherever nothing lands in it;
//! - every law holds.
//!
//! `tests/shared/server.rs` says how the server is made, and what `PG_CONFIG` and
//! `PROCESS_MODULUS_SERVER_SETUP` choose.

#[path = "shared/server.rs"]
mod server;

use std::fs;
use std::path::{Path, PathBuf};
use std::time::Instant;

use server::Server;

/// Every composed statement, relative to the repository root, in order. The ingest is left out:
/// it is what loaded the documents.
fn statements(dir: &Path, out: &mut Vec<PathBuf>) {
    for entry in fs::read_dir(dir).expect("assets/sql is readable").flatten() {
        let path = entry.path();
        if path.is_dir() {
            statements(&path, out);
        } else if path.extension().is_some_and(|x| x == "sql") && path != Path::new("assets/sql/ingest.sql") {
            out.push(path);
        }
    }
}

/// A composed statement as a subquery: its `--` lines and its final `;` taken off.
fn subquery(path: &str) -> String {
    let sql = fs::read_to_string(path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let body: Vec<&str> = sql.lines().filter(|l| !l.trim_start().starts_with("--")).collect();
    format!("({})", body.join("\n").trim_end().trim_end_matches(';'))
}

#[test]
fn every_statement_runs_and_the_structure_holds() {
    let server = Server::start().unwrap_or_else(|e| panic!("{e}"));
    println!("{}\n", server.describe().unwrap_or_else(|e| panic!("{e}")));
    let mut failures = Vec::new();

    let mut files = Vec::new();
    statements(Path::new("assets/sql"), &mut files);
    statements(Path::new("pt-PT/assets/sql"), &mut files);
    files.sort();
    assert!(!files.is_empty(), "no composed statement was found, so this test examines nothing");
    let started = Instant::now();
    for file in &files {
        let at = Instant::now();
        match server.run_file(file) {
            Ok(_) => println!("{:>8.3}s  {}", at.elapsed().as_secs_f64(), file.display()),
            Err(e) => failures.push(e),
        }
    }
    println!("{} statements in {:.1}s\n", files.len(), started.elapsed().as_secs_f64());

    let rules = server
        .query(&format!(
            "SELECT rule, examined, broken FROM {} r",
            subquery("assets/sql/queries/walk/12-every-rule.sql")
        ))
        .unwrap_or_else(|e| panic!("{e}"));
    assert!(!rules.is_empty(), "the roster lists no rule, so this test examines nothing");
    for rule in &rules {
        if rule[1] == "0" {
            failures.push(format!("rule {} examined nothing, so its clean result says nothing", rule[0]));
        }
        if rule[2] != "0" {
            failures.push(format!("rule {} is broken by {} rows", rule[0], rule[2]));
        }
    }
    println!("{} rules, each examining rows, none broken", rules.len());

    let classes = server
        .query(&format!(
            "SELECT relation, class, standing, reason FROM {} d",
            subquery("assets/sql/queries/walk/12b-every-class.sql")
        ))
        .unwrap_or_else(|e| panic!("{e}"));
    assert!(!classes.is_empty(), "no class was listed, so this test examines nothing");
    for class in &classes {
        let (relation, name, standing, reason) = (&class[0], &class[1], &class[2], &class[3]);
        match standing.as_str() {
            "exercised" => {}
            "outside" | "open" if !reason.is_empty() => {}
            "outside" | "open" => failures.push(format!("{relation}: class {name} is {standing} and gives no reason")),
            other => failures.push(format!("{relation}: class {name} stands nowhere known: {other:?}")),
        }
    }
    println!("{} classes, each standing somewhere", classes.len());

    let laws = server
        .query(&format!(
            "SELECT law, coalesce(subject, ''), holds IS TRUE FROM {} l",
            subquery("assets/sql/algebra/all.sql")
        ))
        .unwrap_or_else(|e| panic!("{e}"));
    assert!(!laws.is_empty(), "no law was examined, so this test examines nothing");
    for law in &laws {
        if law[2] != "t" {
            failures.push(format!("law {} does not hold for {:?}", law[0], law[1]));
        }
    }
    println!("{} laws, every one holding", laws.len());

    assert!(failures.is_empty(), "{}", failures.join("\n"));
}
