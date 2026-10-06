//! The source tree as a graph, read once so that the examples asking about it cannot disagree.
//!
//! Which template composes which is a fact about `assets/sqlc/`, and every example that asks
//! about it gets the same answer. `compositions` asserts that every name resolves and nothing
//! expands to itself, `observations` finds the templates nothing composes, and `soundness` asks
//! whether a population reaches the roster it is differenced against. Different questions, one
//! graph, one parser: a parser in each example would be a copy in each, and copies drift with
//! nothing here able to notice.
//!
//! What the parser is fed matters as much as the parser. A `#` line is prose and can spell a
//! directive while it discusses one; counted, it would add an edge the composed SQL does not have.
//! So there is one parser and two named inputs, and which one is used depends on what is being
//! asked, not on who is asking:
//!
//! - [`emitted`] strips `#` only, for the questions about the graph. It is what `sql-composer`
//!   sees, so a call graph built from anything else can disagree with the composed SQL.
//! - [`sql_only`] strips `#` and `--`, for the questions about SQL text, where a provenance line
//!   is prose that discusses operators at length and would be counted as SQL.
//!
//! Each example compiles this whole module and uses part of it.

#![allow(dead_code)]

use std::fs;
use std::path::Path;

/// Every `.sqlc` under a directory, with its body, named the way a `:compose()` directive
/// names it. Callers that need a stable print order sort the result themselves; this walks the
/// filesystem and does not promise one.
pub fn templates(dir: &Path, root: &Path, out: &mut Vec<(String, String)>) {
    for e in fs::read_dir(dir).expect("assets/sqlc is readable").flatten() {
        let p = e.path();
        if p.is_dir() {
            templates(&p, root, out);
        } else if p.extension().is_some_and(|x| x == "sqlc") {
            let name = p.strip_prefix(root).expect("under assets/sqlc").to_string_lossy().into_owned();
            out.push((name, fs::read_to_string(&p).expect("readable")));
        }
    }
}

/// A template's body with its `#` lines stripped, which is what compose emits. The `#` lines are
/// prose and name other templates constantly; counting a reference out of one would make the
/// call graph disagree with the composed SQL.
pub fn emitted(body: &str) -> String {
    body.lines().filter(|l| !l.trim_start().starts_with('#')).collect::<Vec<_>>().join("\n")
}

/// SQL only. `#` is a stripped template comment and `--` is a provenance line. Both discuss
/// SQL operators at length, and counting them is how a careless grep reports a dozen `EXISTS`
/// in a tree that contains none.
pub fn sql_only(body: &str) -> String {
    body.lines()
        .filter(|l| !l.trim_start().starts_with('#') && !l.trim_start().starts_with("--"))
        .collect::<Vec<_>>()
        .join("\n")
}

/// The `.sqlc` paths a template reads. Three forms occur: `:compose(path)`, `:union(ALL a, b)`,
/// and a slot fill, `:compose(shape, @scope = path)`.
///
/// The third needs care: the filler is the only reference a `scope/` relation ever gets, so a
/// parser that stopped at the `@` would report every scope as composed by nothing. A bare
/// `@scope` inside a shape names no file and drops out on its own.
///
/// A directive spelling this function does not know is an edge nobody sees. Every spelling the
/// composer has is here; add a new one here before using it in the tree.
pub fn references(sql: &str) -> Vec<String> {
    paths(sql, &[":compose(", ":union("])
}

fn paths(sql: &str, opens: &[&str]) -> Vec<String> {
    let mut out = Vec::new();
    for open in opens {
        let mut rest = sql;
        while let Some(i) = rest.find(open) {
            rest = &rest[i + open.len()..];
            let Some(j) = rest.find(')') else { break };
            for token in rest[..j].split(',') {
                let t = token.trim().trim_start_matches("ALL").trim();
                let t = t.split_once('=').map_or(t, |(_, filler)| filler.trim());
                if t.ends_with(".sqlc") {
                    out.push(t.to_string());
                }
            }
            rest = &rest[j..];
        }
    }
    out
}

/// Does `from` reach `to` through the templates it composes, directly or through others? It
/// follows every step, because `checks/all.sqlc` reaches the roster only through its arms: the
/// union names the arms and each arm names the roster.
pub fn reaches(
    edges: &std::collections::BTreeMap<&str, Vec<String>>,
    from: &str,
    to: &str,
    seen: &mut std::collections::BTreeSet<String>,
) -> bool {
    for next in edges.get(from).into_iter().flatten() {
        if next == to {
            return true;
        }
        if seen.insert(next.clone()) && reaches(edges, next, to, seen) {
            return true;
        }
    }
    false
}
