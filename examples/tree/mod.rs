//! The source tree as a graph, read once so that the examples asking about it cannot disagree.
//!
//! ⭐⭐⭐ THE COMPOSE DAG IS A FACT ABOUT `assets/sqlc/`, AND EVERY EXAMPLE THAT ASKS ABOUT IT
//! HAS TO GET THE SAME ANSWER. `compositions.rs` asserts that every name resolves and nothing
//! expands to itself, `observations.rs` finds the templates nothing composes, and
//! `soundness.rs` asks whether a population reaches the roster it is differenced against.
//! Different questions, one graph. They were a parser each until 2026-09-08, and
//! `AGENTS.md` §6 already names what that is: restating a closed set in a foreign namespace
//! forks it, and a fork drifts with nothing here able to notice.
//!
//! ⛔⛔ THE FORK HAD ALREADY DRIFTED ON THE INPUT RATHER THAN ON THE PARSER. Three copies of
//! one function were fed three different bodies: `emitted`, `sql_only`, and the raw file.
//! Only the first is right for a graph question, and `assets/sqlc/algebra/searches.sqlc` has
//! a `#` line containing `:union(ALL …)` that yields no edge only because the argument is an
//! ellipsis rather than a path. The parser was never the risk.
//!
//! ⭐⭐ SO THE RULE IS ONE PARSER AND TWO NAMED INPUTS, and which one is a question about what
//! is being asked, not about who is asking:
//!
//!   [`emitted`]  strips `#` only. THE GRAPH QUESTIONS. It is what `sql-composer` sees, so a
//!               call graph built from anything else can disagree with the composed SQL.
//!   [`sql_only`] strips `#` and `--`. THE SQL-TEXT QUESTIONS, where a provenance line is
//!               prose that discusses operators at length and would be counted as SQL.
//!
//! ⛔ EACH EXAMPLE COMPILES THIS WHOLE MODULE AND USES PART OF IT.

#![allow(dead_code)]

use std::fs;
use std::path::Path;

/// Every `.sqlc` under a directory, with its body, named the way a `:compose()` directive
/// names it. ⛔ Callers that need a stable print order sort the result themselves; this walks
/// the filesystem and does not promise one.
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

/// A template's body with the `#` argument stripped, which is what compose emits. ⛔ The `#`
/// lines are prose and they NAME other templates constantly; counting a reference out of one
/// would make the call graph disagree with the composed SQL.
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

/// The `.sqlc` paths a template names, from either directive. Three forms occur:
/// `:compose(path)`, `:union(ALL a, b)`, and a slot fill, `:compose(shape, @scope = path)`.
///
/// ⛔ THE THIRD IS THE ONE WORTH BEING CAREFUL ABOUT: the filler is the only reference a
/// `scope/` relation ever gets, so a parser that stopped at the `@` would report every scope
/// as an orphan. A bare `@scope` inside a shape names no file and drops out on its own.
///
/// ⛔ A DIRECTIVE SPELLING THIS FUNCTION DOES NOT KNOW IS AN EDGE NOBODY SEES. Every spelling
/// the composer has is here. Add one here before adding it to the tree.
pub fn references(sql: &str) -> Vec<String> {
    let mut out = Vec::new();
    for open in [":compose(", ":union("] {
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

/// Does `from` reach `to` through the compose DAG? ⛔ Transitively, because no arm of
/// `checks/all.sqlc` is named by `checks/all.sqlc` directly: the union names the arms and each
/// arm names the roster.
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
