//! The compositions this repository has, and the three preconditions that make them an algebra.
//!
//! ⭐⭐⭐ THERE ARE TWO LAYERS AND THEY ARE NOT TWO READINGS OF ONE THING. The DOMAIN OBJECTS are
//! the relational objects, `pm.*` in `assets/ddl/schema.ddl`. The COMPOSITIONS are the queries,
//! `assets/sqlc/**.sqlc`, and they are ad-hoc views this repository never builds: `CREATE VIEW`
//! appears in the schema zero times. Everything else here refers to a composition by NAME, the
//! way a `.sqlc` refers to another `.sqlc` and never repeats its SQL.
//!
//! ⭐⭐ AND THE COMPOSE DAG IS A CALL GRAPH. `sql-composer`, BPMN 2.0 and this model are the
//! reachability algebra of a well-founded binary relation on names, which is a claim with three
//! preconditions: every name resolves, no name expands to itself, the expansion has a start and
//! an end. This example ASSERTS all three on the real tree rather than restating them.
//!
//! ⛔⛔ THE ONE THAT IS WORTH THE MOST IS THE CONTRAST AT THE END. A layer reached twice inside
//! one fusion is `checks/jagged_layer`, a violation, because the carrier is CONSERVED and one
//! total closes over both occurrences. A composition reached twice inside one root is the NORMAL
//! CASE and costs nothing, because a query is idempotent and the planner reads the relation once.
//! Same substitution algebra, same graph shape, opposite verdicts. The difference is the carrier,
//! and it is the whole of what this model adds to its two neighbours.
//!
//! ⭐ It needs no database. The compose DAG is a fact about the source tree.
//!
//! ```text
//! cargo run --example compositions
//! ```

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::Path;

/// The one composition that is reached by nothing and reaches nothing, with the reason. ⛔ It is
/// named here rather than tolerated by a count, so that a SECOND orphan fails the build.
const ISOLATED: &[(&str, &str)] =
    &[("ingest.sqlc", "the XMLTABLE loader; psql runs it before anything composes")];

/// Every `.sqlc` under `assets/sqlc`, named the way a `:compose()` directive names it.
fn templates(dir: &Path, root: &Path, out: &mut Vec<(String, String)>) {
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

/// The `.sqlc` paths a template names, from either directive. Three forms occur:
/// `:compose(path)`, `:union(ALL a, b)`, and a slot fill, `:compose(shape, @scope = path)`.
/// ⛔ The third is the one worth being careful about: the filler is the only reference a
/// `scope/` relation ever gets, so a parser that stopped at the `@` would report every scope
/// as an orphan. A bare `@scope` inside a shape names no file and drops out on its own.
fn references(body: &str) -> Vec<String> {
    let mut out = Vec::new();
    for (open, close) in [(":compose(", ')'), (":union(", ')')] {
        let mut rest = body;
        while let Some(i) = rest.find(open) {
            rest = &rest[i + open.len()..];
            let Some(j) = rest.find(close) else { break };
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

/// A template's body with the `#` argument stripped, which is what compose emits. ⛔ The `#`
/// lines are prose and they NAME other templates constantly; counting a reference out of one
/// would make the call graph disagree with the composed SQL.
fn emitted(body: &str) -> String {
    body.lines().filter(|l| !l.trim_start().starts_with('#')).collect::<Vec<_>>().join("\n")
}

fn main() {
    let sqlc = Path::new("assets/sqlc");
    let mut files = Vec::new();
    templates(sqlc, sqlc, &mut files);
    files.sort();
    let names: BTreeSet<&str> = files.iter().map(|(n, _)| n.as_str()).collect();

    let edges: BTreeMap<&str, Vec<String>> =
        files.iter().map(|(n, b)| (n.as_str(), references(&emitted(b)))).collect();
    let directives: usize = edges.values().map(Vec::len).sum();

    // ------------------------------------------------------------------
    // The two layers.
    // ------------------------------------------------------------------
    let ddl = fs::read_to_string("assets/ddl/schema.ddl").expect("schema.ddl is readable");
    let domain = ddl.lines().filter(|l| l.starts_with("CREATE TABLE")).count();
    let views = ddl.matches("CREATE VIEW").count() + ddl.matches("CREATE MATERIALIZED").count();

    println!("THE TWO LAYERS");
    println!("   domain objects, the relational objects `pm.*`   {domain:>4}   render as BPMN elements");
    println!("   compositions,   the queries `assets/sqlc/*`     {:>4}   render as BPMN processes", files.len());
    println!("   `CREATE VIEW` in the schema                     {views:>4}   ad-hoc views, never built");

    // ------------------------------------------------------------------
    // The three preconditions. Each is an assertion, not a report.
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // ⛔⛔⛔ THE PIPELINE'S OWN ORDER, WHICH NOTHING STATED AND NOTHING NOTICED. Three programs
    //    share `assets/bpmn/`: two emit BPMN into subdirectories they own, and `rendering` reads
    //    both and writes the SVG beside each. **`rendering` must run LAST and no program can
    //    assert that it did**, because the check would have to run after the last thing.
    //
    // ⭐⭐ SO CHECK THE INVARIANT INSTEAD OF THE ORDER: every `.bpmn` owes a `.svg` at the same
    //    path under `assets/svg/`,
    //    at least as new. That fails exactly when the pipeline ran out of order or stopped early,
    //    and it says so with the command that fixes it. Measured before this existed: running the
    //    battery in REVERSE alphabetical order left **18 BPMN and 0 SVG, with every example
    //    reporting success**, and the SVG is the stage the *verifies with no BPMN tool present*
    //    claim rests on.
    //
    // ⚠️ GUARDED ON EXISTENCE, because `assets/bpmn/` is generated and untracked: a fresh clone
    //   has not run the pipeline at all and owes nothing. Once it exists it must be COMPLETE.
    // ------------------------------------------------------------------
    let mut unrendered: Vec<String> = Vec::new();
    let mut stale: Vec<String> = Vec::new();
    let mut pairs = 0usize;
    // ⭐ THE TWO TREES ARE SEPARATE, `assets/bpmn/` and `assets/svg/`, the way `assets/sql/` and
    //   `.sqlx/` are. While the drawing lived beside its document an emitter's wipe DELETED it,
    //   so this could only ever see it go missing; now a stale one is caught by AGE.
    if let Ok(top) = std::fs::read_dir("assets/bpmn") {
        for d in top.flatten().filter(|e| e.path().is_dir()) {
            for f in std::fs::read_dir(d.path()).into_iter().flatten().flatten() {
                let p = f.path();
                if p.extension().is_none_or(|x| x != "bpmn") { continue; }
                pairs += 1;
                let svg = std::path::Path::new("assets/svg")
                    .join(p.strip_prefix("assets/bpmn").unwrap_or(&p))
                    .with_extension("svg");
                let name = p.strip_prefix("assets/bpmn").unwrap_or(&p).display().to_string();
                match std::fs::metadata(&svg).and_then(|m| m.modified()) {
                    Err(_) => unrendered.push(name),
                    Ok(t) => {
                        if std::fs::metadata(&p).and_then(|m| m.modified()).is_ok_and(|b| b > t) {
                            stale.push(name);
                        }
                    }
                }
            }
        }
        println!("\nTHE PIPELINE, AND WHETHER IT WAS RUN TO THE END");
        println!("   {pairs} BPMN documents, {} without an SVG, {} whose SVG is older",
                 unrendered.len(), stale.len());
        assert!(
            unrendered.is_empty() && stale.is_empty(),
            "the BPMN stage ran after the SVG stage, or instead of it, so the artifact a reader \
             verifies without a BPMN tool is missing or stale. Run: diagramming, graphs, then \
             rendering. unrendered {unrendered:?}, stale {stale:?}"
        );
        println!("   ⭐ Every document is rendered and no SVG is older than its BPMN. The ORDER");
        println!("      is unassertable from inside, so this is the invariant it would produce.");
    }

    println!("\nTHE THREE PRECONDITIONS, on the compose DAG");

    let dangling: Vec<String> = edges
        .iter()
        .flat_map(|(f, ts)| ts.iter().filter(|t| !names.contains(t.as_str())).map(move |t| format!("{f} -> {t}")))
        .collect();
    println!("   1. every name resolves          {} directives, {} dangling", directives, dangling.len());
    assert!(dangling.is_empty(), "a :compose names a template that is not here: {dangling:?}");

    // ⭐ Depth-first with a colour per node: grey is on the current path, so meeting grey is a
    //   cycle and meeting black is a DIAMOND, which is not one. `composition/descent.sqlc`
    //   makes the same distinction with SQL:2016's CYCLE clause, for the same reason.
    let mut colour: BTreeMap<&str, u8> = BTreeMap::new();
    let mut cycles: Vec<String> = Vec::new();
    fn visit<'a>(
        n: &'a str, edges: &BTreeMap<&'a str, Vec<String>>, names: &BTreeSet<&'a str>,
        colour: &mut BTreeMap<&'a str, u8>, path: &mut Vec<&'a str>, cycles: &mut Vec<String>,
    ) {
        match colour.get(n) {
            Some(2) => return,
            Some(1) => {
                let at = path.iter().position(|x| x == &n).unwrap_or(0);
                cycles.push(format!("{} -> {n}", path[at..].join(" -> ")));
                return;
            }
            _ => {}
        }
        colour.insert(n, 1);
        path.push(n);
        for m in edges.get(n).into_iter().flatten() {
            if let Some(m) = names.get(m.as_str()) {
                visit(m, edges, names, colour, path, cycles);
            }
        }
        path.pop();
        colour.insert(n, 2);
    }
    for n in &names {
        visit(n, &edges, &names, &mut colour, &mut Vec::new(), &mut cycles);
    }
    println!("   2. no name expands to itself    {} cycles", cycles.len());
    assert!(cycles.is_empty(), "the compose DAG is not well founded: {cycles:?}");

    let called: BTreeSet<&str> =
        edges.values().flatten().filter_map(|t| names.get(t.as_str()).copied()).collect();
    let roots: Vec<&str> = names.iter().copied().filter(|n| !called.contains(n)).collect();
    let leaves: Vec<&str> =
        names.iter().copied().filter(|n| edges.get(n).is_none_or(Vec::is_empty)).collect();
    let isolated: Vec<&str> =
        roots.iter().copied().filter(|n| leaves.contains(n)).collect();
    println!(
        "   3. a start and an end           {} roots, {} leaves, {} isolated",
        roots.len(), leaves.len(), isolated.len()
    );
    // ⭐ A relation earns its place TWO ways and this check knew only one. `observations.rs`
    //   already states the other: a root is run, as a psql entry point or by an example naming
    //   its composed output. A literal contract read straight by an example composes nothing and
    //   is composed by nothing, and it is not an orphan. Reading `examples/` is the same test
    //   that file makes, and keeping the two in step matters more than either being clever.
    let example_src: String = fs::read_dir("examples")
        .expect("examples/ is readable")
        .flatten()
        .map(|e| fs::read_to_string(e.path()).unwrap_or_default())
        .collect();
    for n in &isolated {
        let run_by_an_example =
            example_src.contains(&format!("assets/sql/{}", n.replace(".sqlc", ".sql")));
        match (ISOLATED.iter().find(|(f, _)| *f == *n).map(|(_, w)| *w), run_by_an_example) {
            (Some(w), _) => println!("      {n}  exempt: {w}"),
            (None, true) => println!("      {n}  run by an example, which is how a root earns its place"),
            (None, false) => panic!(
                "{n} is composed by nothing, composes nothing, and no example runs it. Either \
                 it earns a line in ISOLATED with the reason, or it is a relation nobody reaches."
            ),
        }
    }

    // ------------------------------------------------------------------
    // Where a process stops calling and starts containing.
    // ------------------------------------------------------------------
    // ⛔ "Reads a base table" is not "reads `pm.`". `diagrams/catalogue.sqlc` reads
    //   `information_schema`, on purpose: a contract needs a population it did not write, and
    //   the catalogue is the only honest source for which tables actually exist. A predicate
    //   that looked for `pm.` alone would have filed it as a literal, which is the opposite of
    //   what it is.
    let touches_a_table = |b: &str| {
        let e = emitted(b);
        ["FROM pm.", "JOIN pm.", "FROM      pm.", "information_schema.", "pg_constraint"]
            .iter()
            .any(|m| e.contains(m))
    };
    // ⭐ A contract declares itself by BEING a literal, not by being called `roster`. Keying on
    //   the filename would have made the check a naming convention rather than a structural one.
    let is_a_literal = |b: &str| emitted(b).contains("FROM (VALUES");
    let mut only_compose = 0;
    let mut only_table = 0;
    let mut both: Vec<&str> = Vec::new();
    let mut literal: Vec<&str> = Vec::new();
    for (n, b) in &files {
        let composes = !edges[n.as_str()].is_empty();
        match (composes, touches_a_table(b)) {
            (true, true) => both.push(n),
            (true, false) => only_compose += 1,
            (false, true) => only_table += 1,
            (false, false) => literal.push(n),
        }
    }
    println!("\nTHE LEAF BOUNDARY, where a process stops calling and starts containing");
    println!("   {only_compose:>4}  compose only          a process of call activities");
    println!("   {only_table:>4}  read `pm.*` only       a process holding domain-object elements");
    println!("   {:>4}  do BOTH               reaching past its own abstraction, and VISIBLE in a diagram", both.len());
    for n in &both {
        println!("         {n}");
    }
    // ⭐⭐⭐ The fourth category is not a gap, it is the contracts. A roster names what the tree
    //   must contain, so it CANNOT be derived from the tree: derived, declared and produced could
    //   never disagree and `reports/integrity.sqlc` would be anti-joining a set against itself.
    //   That is why every one of them is a bare VALUES literal, and it is the reason a roster of
    //   200 file names would not be a contract at all.
    println!("   {:>4}  neither               a VALUES literal: a CONTRACT, which must not be derived", literal.len());
    for n in &literal {
        println!("         {n}");
    }
    let not_a_contract: Vec<&&str> = literal
        .iter()
        .filter(|n| {
            !ISOLATED.iter().any(|(f, _)| *f == **n)
                && !files.iter().any(|(f, b)| f == *n && is_a_literal(b))
        })
        .collect();
    assert!(
        not_a_contract.is_empty(),
        "a template that composes nothing and reads no table must be a VALUES literal, which is \
         what a contract IS, or the loader: {not_a_contract:?}"
    );

    // ------------------------------------------------------------------
    // ⭐⭐⭐ The contrast. This is the section the example exists for.
    // ------------------------------------------------------------------
    fn reached<'a>(
        n: &'a str, edges: &BTreeMap<&'a str, Vec<String>>, names: &BTreeSet<&'a str>,
        seen: &mut Vec<&'a str>, count: &mut BTreeMap<&'a str, usize>,
    ) {
        *count.entry(n).or_default() += 1;
        for m in edges.get(n).into_iter().flatten() {
            if let Some(m) = names.get(m.as_str()).copied() {
                if !seen.contains(&m) {
                    seen.push(m);
                    reached(m, edges, names, seen, count);
                    seen.pop();
                }
            }
        }
    }
    let mut worst = ("", 0usize);
    let mut roots_with_a_diamond = 0;
    for r in &roots {
        let mut count = BTreeMap::new();
        reached(r, &edges, &names, &mut vec![*r], &mut count);
        let twice = count.iter().filter(|(k, v)| **v > 1 && *k != r).count();
        if twice > 0 {
            roots_with_a_diamond += 1;
            if twice > worst.1 {
                worst = (r, twice);
            }
        }
    }
    let mut indeg: BTreeMap<&str, usize> = BTreeMap::new();
    for t in edges.values().flatten() {
        if let Some(t) = names.get(t.as_str()).copied() {
            *indeg.entry(t).or_default() += 1;
        }
    }
    let mut most: Vec<(&&str, &usize)> = indeg.iter().collect();
    most.sort_by(|a, b| b.1.cmp(a.1));

    println!("\nDUPLICATION: THE SAME SHAPE, AND THE OPPOSITE VERDICT");
    println!(
        "   {roots_with_a_diamond} of {} roots reach some composition by more than one path",
        roots.len()
    );
    println!("   worst: {} reaches {} compositions more than once", worst.0, worst.1);
    println!("   {} of {} compositions have more than one parent", indeg.values().filter(|v| **v > 1).count(), files.len());
    for (n, c) in most.iter().take(3) {
        println!("         {n} is composed {c} times");
    }
    println!("   ⭐ Every one of these is CORRECT, and `references/planner.md` measured the cost:");
    println!("      the repeated relations are read once, shared hit 9,883 and read 0.");
    println!("   ⛔ The identical shape in the PART graph is `checks/jagged_layer`, a violation,");
    println!("      because supply is a CONSERVED carrier and one total closes over both");
    println!("      occurrences. A query is idempotent and a supply is not. That difference is");
    println!("      the whole of what this model adds to `sql-composer` and to BPMN 2.0.");

    assert!(
        roots_with_a_diamond > 0,
        "no root reaches anything twice, so the contrast this example draws has no subject \
         and the claim that duplication is normal here is untested."
    );

    println!("\nAll checks passed.");
}
