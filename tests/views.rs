//! Every statement composed by two or more others is a view, and so is every fold, and nothing
//! else is. Each is created after every view it reads. And a statement a program reads types
//! defines every view it reaches, in its own `WITH` clause, before reading it.
//!
//! `assets/sqlc/views.sqlc` is the registry `cargo sqlc compose --views` reads: a template it lists
//! is written `SELECT * FROM <view>` wherever it is composed, and `:define` is what puts the body
//! in the registry line itself rather than the name it is defining. Which templates
//! those are is a fact about the tree, so the registry is held to the tree in both directions: a
//! shared statement missing from it is copied into every reader, and a line with no rule behind it
//! is a view the tree never asked for. A view is named after its file, in the schema named after
//! its directory. The parents are read the way the compose DAG is, by `examples/shared/tree`.

#[path = "../examples/shared/tree/mod.rs"]
mod tree;

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::Path;

const SOURCE: &str = "assets/sqlc";
const REGISTRY: &str = "views.sqlc";

/// Every template's emitted body, and the templates each one composes.
fn graph() -> (BTreeMap<String, String>, BTreeMap<String, BTreeSet<String>>) {
    let mut found = Vec::new();
    tree::templates(Path::new(SOURCE), Path::new(SOURCE), &mut found);
    let bodies: BTreeMap<String, String> =
        found.into_iter().map(|(name, body)| (name, tree::emitted(&body))).collect();
    let children = bodies
        .iter()
        .map(|(name, body)| (name.clone(), tree::references(body).into_iter().collect()))
        .collect();
    (bodies, children)
}


/// The registry's lines in order: (view, template).
fn registered() -> Vec<(String, String)> {
    let src = fs::read_to_string(format!("{SOURCE}/{REGISTRY}")).expect("the view registry is readable");
    src.lines()
        .filter(|l| l.starts_with("CREATE VIEW "))
        .map(|l| {
            let (view, rest) = l
                .strip_prefix("CREATE VIEW ")
                .and_then(|r| r.split_once(" AS :define("))
                .unwrap_or_else(|| panic!("a view line is not `CREATE VIEW <view> AS :define(<file>);`: {l}"));
            let file = rest.strip_suffix(");").unwrap_or_else(|| panic!("a view line ends oddly: {l}"));
            (view.to_string(), file.to_string())
        })
        .collect()
}

#[test]
fn every_shared_statement_and_every_fold_is_a_view() {
    let (bodies, children) = graph();
    let mut parents: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for (parent, kids) in &children {
        if parent == REGISTRY {
            continue;
        }
        for kid in kids {
            parents.entry(kid.as_str()).or_default().insert(parent.as_str());
        }
    }
    let open_slot = |name: &str| bodies.get(name).is_some_and(|b| b.contains(":compose(@"));
    let owed: BTreeSet<&str> = bodies
        .keys()
        .map(String::as_str)
        .filter(|name| {
            name.starts_with("folds/")
                || (parents.get(name).is_some_and(|p| p.len() >= 2) && !open_slot(name))
        })
        .collect();

    let lines = registered();
    let mut listed = BTreeSet::new();
    for (view, file) in &lines {
        let (dir, stem) = file
            .strip_suffix(".sqlc")
            .and_then(|f| f.split_once('/'))
            .unwrap_or_else(|| panic!("{view} composes {file}, which is not <directory>/<name>.sqlc"));
        assert_eq!(view, &format!("{dir}.{stem}"), "{file} is registered as {view}, not as {dir}.{stem}");
        assert!(bodies.contains_key(file), "{view} composes {file}, which does not exist");
        assert!(!open_slot(file), "{view} composes {file}, which leaves a slot open");
        assert!(listed.insert(file.as_str()), "{file} is registered twice");
    }

    assert!(!owed.is_empty(), "no template is owed a view, so this test examines nothing");
    let missing: Vec<&&str> = owed.difference(&listed).collect();
    let stray: Vec<&&str> = listed.difference(&owed).collect();
    assert!(missing.is_empty(), "shared statements or folds with no view, copied into every reader: {missing:?}");
    assert!(stray.is_empty(), "views no rule asks for: {stray:?}");
}

/// Every template the statement reaches, transitively, through any directive.
fn closure(children: &BTreeMap<String, BTreeSet<String>>, from: &str) -> BTreeSet<String> {
    let mut seen = BTreeSet::new();
    let mut stack: Vec<String> = children.get(from).into_iter().flatten().cloned().collect();
    while let Some(next) = stack.pop() {
        if seen.insert(next.clone()) {
            stack.extend(children.get(&next).into_iter().flatten().cloned());
        }
    }
    seen
}

/// The templates a `query_file!` reads, as template paths. These are the statements whose column
/// types are part of the proof, because a Rust program declares what it expects of each one.
fn typed_statements() -> BTreeSet<String> {
    let mut out = BTreeSet::new();
    for dir in ["src", "examples", "tests"] {
        let mut stack = vec![Path::new(dir).to_path_buf()];
        while let Some(path) = stack.pop() {
            let Ok(entries) = fs::read_dir(&path) else { continue };
            for entry in entries.flatten() {
                let p = entry.path();
                if p.is_dir() {
                    stack.push(p);
                } else if p.extension().is_some_and(|e| e == "rs") {
                    let src = fs::read_to_string(&p).unwrap_or_default();
                    let mut rest = src.as_str();
                    while let Some(i) = rest.find("query_file") {
                        rest = &rest[i..];
                        let Some(open) = rest.find('"') else { break };
                        let Some(close) = rest[open + 1..].find('"') else { break };
                        let quoted = &rest[open + 1..open + 1 + close];
                        if let Some(stem) = quoted
                            .strip_prefix("assets/sql/")
                            .and_then(|q| q.strip_suffix(".sql"))
                        {
                            out.insert(format!("{stem}.sqlc"));
                        }
                        rest = &rest[open + 1 + close..];
                    }
                }
            }
        }
    }
    out
}

/// What a template defines in its own `WITH` clause, in the order it defines them: the local
/// name, the template the definition puts there, and whether it is materialised.
fn preamble(body: &str) -> Vec<(String, String, bool)> {
    let mut out = Vec::new();
    let mut open: Option<(String, bool)> = None;
    for line in body.lines() {
        let trimmed = line.trim();
        if let Some(n) = trimmed.strip_suffix(" AS NOT MATERIALIZED (") {
            open = Some((n.trim_start_matches("WITH ").trim().to_string(), false));
        } else if let Some(n) = trimmed.strip_suffix(" AS MATERIALIZED (") {
            open = Some((n.trim_start_matches("WITH ").trim().to_string(), true));
        } else if let Some(rest) = trimmed.strip_prefix(":define(") {
            if let (Some((n, fenced)), Some(path)) = (open.take(), rest.strip_suffix(')')) {
                out.push((n, path.to_string(), fenced));
            }
        }
    }
    out
}

#[test]
fn a_preamble_defines_every_view_its_statement_reaches() {
    // ⛔ THE HALF-DEFINED STATEMENT IS THE DANGEROUS ONE, WHICH IS WHY THIS RUNS ON THE
    //    STATEMENTS THAT DEFINE ANYTHING RATHER THAN ON THE STATEMENTS A PROGRAM READS. A
    //    statement that defines nothing takes every column through a view and is typed as
    //    nullable throughout, which the program either handles or fails to compile over. A
    //    statement that defines SOME of what it reaches is typed both ways at once, and which
    //    column got which depends on a path through the tree nobody is looking at.
    let (bodies, children) = graph();
    let views: BTreeSet<String> = registered().into_iter().map(|(_, f)| f).collect();
    let typed = typed_statements();
    assert!(!typed.is_empty(), "no statement is read by a program, so this test examines nothing");

    let mut examined = 0;
    for (statement, body) in &bodies {
        let defined: BTreeSet<String> = preamble(body).into_iter().map(|(_, p, _)| p).collect();
        if defined.is_empty() {
            continue;
        }
        examined += 1;
        let reached: BTreeSet<String> = closure(&children, statement)
            .into_iter()
            .filter(|t| views.contains(t))
            .collect();
        let missing: Vec<&String> = reached.difference(&defined).collect();
        let spare: Vec<&String> = defined.difference(&reached).collect();
        assert!(
            missing.is_empty(),
            "{statement} defines part of what it reads and not these, so its columns are typed \
             two ways at once: {missing:?}"
        );
        assert!(spare.is_empty(), "{statement} defines what it never reads: {spare:?}");
        assert!(
            typed.contains(statement),
            "{statement} defines its vocabulary but no program reads it. A definition is for \
             keeping a column's origin where a program declares a type, or for fencing a plan; \
             say which in the header, or compose it like everything else."
        );
    }
    assert!(examined > 0, "no statement defines anything, so this test examines nothing");
}

#[test]
fn a_definition_comes_after_the_definitions_it_reads() {
    let (bodies, children) = graph();
    for (name, body) in &bodies {
        let defined = preamble(body);
        for (i, (_, path, _)) in defined.iter().enumerate() {
            let needs = closure(&children, path);
            for (j, (_, earlier, _)) in defined.iter().enumerate() {
                if j > i && needs.contains(earlier) {
                    panic!(
                        "{name} defines {path} before {earlier}, which it reads. A `WITH` clause \
                         resolves in order, so the reference would name a relation that does not \
                         exist yet."
                    );
                }
            }
        }
    }
}

#[test]
fn a_local_name_is_free_for_the_statement_to_take() {
    // A definition's name is unqualified, so it stands in front of anything else that answers to
    // that name. Two hazards, and both fail as a query rather than as a wrong answer, which is
    // why they are worth a test: a word Postgres reserves cannot be a CTE name at all, and a name
    // that is also a table's is a body meaning the table and getting the definition.
    const RESERVED: &[&str] = &[
        "all", "analyse", "analyze", "and", "any", "array", "as", "asc", "between", "both",
        "case", "cast", "check", "collate", "column", "constraint", "create", "cross", "current",
        "default", "desc", "distinct", "do", "else", "end", "except", "false", "for", "foreign",
        "from", "full", "grant", "group", "having", "in", "initially", "inner", "intersect",
        "into", "is", "join", "lateral", "leading", "left", "like", "limit", "natural", "not",
        "null", "offset", "on", "only", "or", "order", "outer", "overlaps", "placing", "primary",
        "references", "returning", "right", "select", "similar", "some", "symmetric", "table",
        "then", "to", "trailing", "true", "union", "unique", "user", "using", "values", "verbose",
        "when", "where", "window", "with",
    ];
    let ddl = fs::read_to_string("assets/ddl/schema.ddl").expect("the schema is readable");
    let tables: BTreeSet<&str> = ddl
        .lines()
        .filter_map(|l| l.trim().strip_prefix("CREATE TABLE "))
        .map(|rest| rest.trim_end_matches(" ("). trim().rsplit('.').next().unwrap_or(rest))
        .collect();
    assert!(!tables.is_empty(), "no table was read from the schema, so this test examines nothing");

    let (bodies, _) = graph();
    for (file, body) in &bodies {
        let defined = preamble(body);
        let mut seen = BTreeSet::new();
        for (name, path, _) in &defined {
            assert!(
                !RESERVED.contains(&name.to_ascii_lowercase().as_str()),
                "{file} defines {path} as `{name}`, which Postgres reserves"
            );
            assert!(
                !tables.contains(name.as_str()),
                "{file} defines {path} as `{name}`, and `{name}` is a table: an unqualified \
                 reference meaning the table would find this definition instead"
            );
            assert!(seen.insert(name.clone()), "{file} defines `{name}` twice");
        }
    }
}

#[test]
fn a_plan_fence_belongs_to_a_statement_nothing_composes() {
    // ⛔ A DEFINITION WRITTEN `MATERIALIZED` IS COMPUTED ONCE INSTEAD OF ONCE PER REFERENCE, AND
    //    THAT IS A DECISION ABOUT ONE QUERY'S PLAN. It travels with the template, so a relation
    //    others compose hands its fence to every reader, and a fenced view hands it to everyone
    //    who reads the view. `folds/law_subjects.sqlc` was fenced for a while and the three
    //    statements reading it went up about five gigabytes each and stopped finishing.
    //    ⭐ A `NOT MATERIALIZED` definition is inlined by the planner, changes no plan, and is
    //    therefore allowed anywhere: it is there to keep a column's origin, not to fence.
    let (bodies, children) = graph();
    let mut parents: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for (parent, kids) in &children {
        for kid in kids {
            parents.entry(kid.as_str()).or_default().insert(parent.as_str());
        }
    }
    let mut fenced = 0;
    for (file, body) in &bodies {
        if !preamble(body).iter().any(|(_, _, materialised)| *materialised) {
            continue;
        }
        fenced += 1;
        let composed_by: Vec<&&str> = parents.get(file.as_str()).into_iter().flatten().collect();
        assert!(
            composed_by.is_empty(),
            "{file} fences its plan and is composed by {composed_by:?}, which inherit the fence              along with the relation"
        );
    }
    assert!(fenced > 0, "nothing fences its plan, so this test examines nothing");
}

#[test]
fn every_view_is_created_after_the_views_it_reads() {
    let (_, children) = graph();
    let lines = registered();
    let position: BTreeMap<&str, usize> =
        lines.iter().enumerate().map(|(i, (_, file))| (file.as_str(), i)).collect();
    let edges: BTreeMap<&str, Vec<String>> =
        children.iter().map(|(k, v)| (k.as_str(), v.iter().cloned().collect())).collect();
    for (i, (view, file)) in lines.iter().enumerate() {
        for (other, j) in &position {
            if *j != i && tree::reaches(&edges, file, other, &mut BTreeSet::new()) {
                assert!(*j < i, "{view} reads {other}, which is created after it");
            }
        }
    }
}
