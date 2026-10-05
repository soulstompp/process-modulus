//! Every relation a composed statement names is free for the statement to take.
//!
//! A statement names each relation it reads once, at its head, and the name is unqualified, so it
//! stands in front of anything else that answers to it. A name that is also a table's would be a
//! body meaning the table and getting the relation instead, and that fails as a wrong answer
//! rather than as an error. The names are read from the composed files, which is where the
//! database meets them, less the names a template gives its own `WITH`.

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

/// Every name a `WITH` gives in the files under `dir` with extension `ext`: the `<name>` of each
/// line that opens `<name> AS (`, with or without `WITH`, `RECURSIVE` and a materialisation in
/// front.
fn named(dir: &Path, ext: &str, out: &mut BTreeSet<String>) {
    for entry in fs::read_dir(dir).expect("readable").flatten() {
        let path = entry.path();
        if path.is_dir() {
            named(&path, ext, out);
            continue;
        }
        if path.extension().is_none_or(|x| x != ext) {
            continue;
        }
        let sql = fs::read_to_string(&path).expect("readable");
        for line in sql.lines() {
            let line = line.trim_start_matches("WITH ").trim_start_matches("RECURSIVE ");
            let Some(name) = ["AS (", "AS MATERIALIZED (", "AS NOT MATERIALIZED ("]
                .iter()
                .find_map(|tail| line.strip_suffix(tail))
                .map(str::trim_end)
            else {
                continue;
            };
            if !name.is_empty() && name.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_') {
                out.insert(name.to_string());
            }
        }
    }
}

#[test]
fn no_named_relation_takes_a_tables_name() {
    let ddl = fs::read_to_string("assets/ddl/schema.ddl").expect("the schema is readable");
    let tables: BTreeSet<&str> = ddl
        .lines()
        .filter_map(|l| l.strip_prefix("CREATE TABLE "))
        .map(|rest| rest.trim_end_matches(" (").trim())
        .map(|name| name.rsplit('.').next().unwrap_or(name))
        .collect();
    assert!(!tables.is_empty(), "no table was read from the schema, so this test examines nothing");

    let mut composed = BTreeSet::new();
    named(Path::new("assets/sql"), "sql", &mut composed);
    let mut own = BTreeSet::new();
    named(Path::new("assets/sqlc"), "sqlc", &mut own);
    let given: BTreeSet<&String> = composed.difference(&own).collect();
    assert!(!given.is_empty(), "no composed statement names a relation, so this test examines nothing");

    let taken: Vec<&&String> = given.iter().filter(|n| tables.contains(n.as_str())).collect();
    assert!(taken.is_empty(), "named after a table, so a reference to the table finds the relation: {taken:?}");
}
