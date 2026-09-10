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

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;

// ⛔ AND THE SCAN OF THIS DIRECTORY IS SHARED FOR THE SAME REASON. `examples/observations/main.rs`
// asks the identical question of `examples/`, and two copies of one walk is how the two answers
// start to differ.
#[path = "../shared/sources/mod.rs"]
mod sources;
use tree::{emitted, references, sql_only, templates};

/// The one composition that is reached by nothing and reaches nothing, with the reason. ⛔ It is
/// named here rather than tolerated by a count, so that a SECOND orphan fails the build.
const ISOLATED: &[(&str, &str)] =
    &[("ingest.sqlc", "the XMLTABLE loader; psql runs it before anything composes")];

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
    // ⭐⭐⭐ AND THE DAG IS EMITTED, BECAUSE WHAT WAS MISSING WAS NEVER THE SCAN. `examples/shared/tree`
    //    has been the one scanner all along. What no caller could do was JOIN the DAG to
    //    anything: bounding a rule's reach by the reach of the relations it composes needs both
    //    sides in SQL, and one of them was a `BTreeMap` in a Rust program. So the fact becomes a
    //    relation, and the one real duplicate, an inline scan in `examples/graphs/main.rs`, retires.
    //
    // ⭐⭐ THIS PROGRAM IS WHERE IT COMES FROM AND IT STILL NEEDS NO DATABASE. The DAG is a fact
    //    about the SOURCE TREE, so the program that reads the source tree emits it and `ingest`
    //    loads it, which is the shape `assets/bpmn/` already has: one stage generates, the next
    //    consumes, and the artifact is tracked so a fresh clone has it.
    //
    // ⛔ `splices` AND NOT A BARE EDGE. A parent composing a child twice is ORDINARY here and a
    //    VIOLATION in `pm.part`, and that one column is where the two graphs differ. Deduping to
    //    an edge would throw away the only thing the comparison rests on.
    // ------------------------------------------------------------------
    {
        // ⭐⭐⭐ AND THE JOIN KEYWORD IS CLASSIFIED HERE, BECAUSE IT IS IN THE TEXT AND THIS IS THE
        //    PROGRAM THAT READS THE TEXT. The DAG carried who composes whom and not HOW, so a
        //    law over it could see that `composition/parts.sqlc` composed the layer dimension
        //    and not that it INNER-JOINED it, which is the whole difference between asking what
        //    is missing from the whole and asking whether one pair exists.
        // ⚠️ TWO CONVENTIONS COEXIST IN THIS TREE AND A NAIVE SCAN MISSES A THIRD OF THE SITES.
        //    Most write `JOIN (\n :compose(x)\n) alias`, so the keyword is on the previous line;
        //    four write `FROM ( :compose(x) ) x` inline. ⛔ So the keyword is taken as the LAST
        //    one before the directive in the whole preceding text, and a site with none is a
        //    hard failure rather than a guess: a scan that silently misreads is worse than a
        //    declared list that visibly rots.
        // ⭐⭐⭐ ONE SHAPE IS DETECTED AND EVERYTHING ELSE DEFAULTS TO *NOT AN INNER JOIN*, and
        //    the stronger design is not available. ⛔ THERE IS NO CLOSED SET OF CALL-SITE SHAPES:
        //    a `:compose` legitimately sits after `JOIN (`, after `FROM (`, after `LEFT JOIN (`,
        //    in a CTE body, after a bare grouping paren inside an `EXCEPT`, after
        //    `CREATE TEMP TABLE x AS`, and as a whole statement in a psql script after an
        //    `\echo`. Classifying every site and failing on the rest means enumerating SQL and
        //    psql, and the guard names more of it on every pass rather than converging.
        //
        // ⭐⭐ SO THE HONESTY MOVES FROM EXHAUSTIVENESS TO A POSITIVE CONTROL. The detector looks
        //    for `JOIN (` immediately before the directive, not qualified by LEFT/RIGHT/FULL/
        //    CROSS, and the guard is that it still finds some: a detector that silently stopped
        //    matching would zero this column and take `algebra/dimension_use.sqlc` with it, and
        //    a law reading all zeros passes loudest.
        let is_inner_join = |body: &str, upto: usize| -> bool {
            let flat = body[..upto]
                .split_whitespace()
                .rev()
                .take(4)
                .collect::<Vec<_>>()
                .into_iter()
                .rev()
                .collect::<Vec<_>>()
                .join(" ");
            flat.ends_with("JOIN (")
                && !["LEFT JOIN (", "RIGHT JOIN (", "FULL JOIN (", "CROSS JOIN ("]
                    .iter()
                    .any(|q| flat.ends_with(q))
        };
        let mut rows: Vec<String> = Vec::new();
        for (parent, kids) in &edges {
            let body = files
                .iter()
                .find(|(n, _)| n == parent)
                .map(|(_, b)| sql_only(b))
                .unwrap_or_default();
            let mut counted: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
            for k in kids {
                let e = counted.entry(k.as_str()).or_default();
                e.0 += 1;
            }
            // one pass over the directives in text order, so a parent splicing one child at two
            // call sites has each site classified on its own
            let mut at = 0usize;
            while let Some(i) = body[at..].find(":compose(") {
                let start = at + i;
                let Some(close) = body[start..].find(')') else { break };
                let named = body[start + 9..start + close].trim().to_string();
                let child = named.split(',').next().unwrap_or("").trim().to_string();
                if is_inner_join(&body, start) {
                    if let Some(e) = counted.get_mut(child.as_str()) { e.1 += 1 }
                }
                at = start + close;
            }
            for (child, (n, inner)) in counted {
                rows.push(format!("  ('{}', '{}', {n}, {inner})",
                                  parent.replace('\'', "''"), child.replace('\'', "''")));
            }
        }
        let inner_total: usize = rows
            .iter()
            .filter_map(|r| r.rsplit(", ").next()?.trim_end_matches(')').parse::<usize>().ok())
            .sum();
        assert!(
            inner_total > 0,
            "no `:compose` in the tree reads as an inner join, so `inner_joins` is all zeros and \
             `algebra/dimension_use.sqlc` is reading a column that cannot fire. Either the tree \
             genuinely has none, or this detector stopped matching `JOIN (`"
        );
        fs::create_dir_all("assets/dag").expect("assets/dag is writable");
        let mut out = String::from(
            "-- GENERATED by examples/compositions/main.rs from assets/sqlc/. DO NOT EDIT.\n             -- One row per (parent, child) with how many times the parent splices the child.\n             -- Loaded by assets/sql/ingest.sql into public.compose_edge.\n             TRUNCATE public.compose_edge;\n");
        if rows.is_empty() {
            panic!("no :compose directive anywhere, so the emitted DAG would be empty");
        }
        out.push_str("INSERT INTO public.compose_edge (parent, child, splices, inner_joins) VALUES\n");
        out.push_str(&rows.join(",\n"));
        out.push_str(";\n");
        fs::write("assets/dag/edges.sql", out).expect("assets/dag/edges.sql is writable");
        println!("THE COMPOSE DAG, EMITTED FOR THE DATABASE");
        println!("   {} pairs from {directives} directives, into assets/dag/edges.sql", rows.len());
        println!("   ⭐ A fact about the source tree, so the program that reads the source tree");
        println!("      emits it. `splices` is carried because a parent composing a child twice is");
        println!("      ordinary here and `checks/jagged_layer` in `pm.part`: two graphs of one");
        println!("      shape, and that column is the whole of the difference.\n");
    }

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
    //    at least as new. That fails exactly when the pipeline runs out of order or stops
    //    early, and it says so with the command that fixes it. Measured: with nothing checking
    //    the invariant, running the battery in REVERSE alphabetical order leaves **18 BPMN and
    //    0 SVG, with every example reporting success**, and the SVG is the stage the *verifies
    //    with no BPMN tool present* claim rests on.
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
    let example_src = sources::all();
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
    // ⭐ AND `public.` IS THE THIRD CASE THE COMMENT ABOVE ANTICIPATED. `rank/compose_edges.sqlc`
    //   reads `public.compose_edge`, this repository's own compose DAG, which is deliberately
    //   outside `pm` because everything in `pm` descends from a filed document and the DAG
    //   descends from `assets/sqlc/`. Without this it filed as a VALUES literal, which is the
    //   opposite of what it is: a base table read, just not of the subject.
    let touches_a_table = |b: &str| {
        let e = emitted(b);
        ["FROM pm.", "JOIN pm.", "FROM      pm.", "FROM public.", "JOIN public.",
         "information_schema.", "pg_constraint"]
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
