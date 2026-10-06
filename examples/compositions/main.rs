// This program's header is `README.md` beside it, and there is one copy of it. GitHub renders a
// directory's README and no `//!` block, so a header kept only in the source cannot be read where
// the repository is published. `include_str!` makes the same file rustdoc's page, so the two
// renderings cannot disagree, and a missing header is a compile error rather than a blank row.
//
// Both languages are included, as in the schemas: an `xs:annotation` holds an `xml:lang="en"`
// block and an `xml:lang="pt"` block, and the generated Rust carries both in one doc comment.
// These two files are the same arrangement for a program, so the Portuguese page is rendered
// wherever the English one is, as `tests/translation.rs` requires.
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/compositions/README.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::Path;

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;

// The scan of the examples is shared for the same reason. `examples/observations/main.rs` asks
// the same question of `examples/`, and two copies of one walk are how two answers start to
// differ.
#[path = "../shared/sources/mod.rs"]
mod sources;
use tree::{emitted, references, sql_only, templates};

/// The one template that is reached by nothing, reaches nothing and is run by no example, with the
/// reason. It is named here rather than tolerated by a count, so a second one fails this program.
const ISOLATED: &[(&str, &str)] = &[
    ("ingest.sqlc", "the XMLTABLE loader; psql runs it before anything composes"),
];

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
    // Which template composes which is written out for the database. `examples/shared/tree` reads
    // it from the source; written out as a relation, it can be joined to anything in SQL, and
    // bounding a rule's reach by the reach of the relations it composes needs both sides there.
    //
    // This program writes it and needs no database. The graph is a fact about the source tree,
    // so the program that reads the source tree writes it and `ingest` loads it, as with
    // `assets/bpmn/`: one stage generates, the next consumes, and the output is tracked so a
    // fresh clone has it.
    //
    // `splices`, and not a bare edge. A parent composing a child twice is ordinary here and a
    // violation in `pm.part`, and that one column is where the two graphs differ. Collapsing it to
    // one edge would throw away the only thing the comparison rests on.
    // ------------------------------------------------------------------
    {
        // The join keyword is classified here, because it is in the text and this program reads
        // the text. The graph says who composes whom; this column says how. With it, a law can
        // tell a parent that inner-joins the layer dimension from one that only composes it,
        // which is the difference between asking whether one pair exists and asking what is
        // missing from the whole.
        //
        // Two conventions coexist in this tree. Most templates write
        // `JOIN (\n :compose(x)\n) alias`, with the keyword on the line before; some write
        // `FROM ( :compose(x) ) x` inline. So the keyword is read from the last few words before
        // the directive, across line breaks.
        //
        // One shape is detected, and everything else counts as not an inner join. There is no
        // closed set of call-site shapes: a `:compose` sits after `JOIN (`, after `FROM (`, after
        // `LEFT JOIN (`, in a CTE body, after a bare parenthesis inside an `EXCEPT`, after
        // `CREATE TEMP TABLE x AS`, and as a whole statement in a psql script after an `\echo`.
        // Classifying every site and failing on the rest would mean listing all of SQL and psql.
        //
        // So the guard is a positive control. The detector looks for `JOIN (` immediately before
        // the directive, not qualified by LEFT, RIGHT, FULL or CROSS, and the guard is that it
        // still finds some: a detector that silently stopped matching would zero this column and
        // take `algebra/dimension_use.sqlc` with it, and a law reading all zeros passes.
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
            "-- Generated by examples/compositions from assets/sqlc/. Do not edit by hand.\n\
             -- One row per (parent, child) with how many times the parent splices the child.\n\
             -- Loaded by assets/sql/ingest.sql into public.compose_edge.\n\
             TRUNCATE public.compose_edge;\n",
        );
        if rows.is_empty() {
            panic!("no :compose directive anywhere, so the written graph would be empty");
        }
        out.push_str("INSERT INTO public.compose_edge (parent, child, splices, inner_joins) VALUES\n");
        out.push_str(&rows.join(",\n"));
        out.push_str(";\n");
        fs::write("assets/dag/edges.sql", out).expect("assets/dag/edges.sql is writable");
        println!("The compose graph, written for the database");
        println!("   {} pairs from {directives} directives, into assets/dag/edges.sql", rows.len());
        println!("   A fact about the source tree, so the program that reads the source tree");
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

    println!("The two layers");
    println!("   domain objects, the relational objects `pm.*`   {domain:>4}   render as BPMN elements");
    println!("   compositions,   the queries `assets/sqlc/*`     {:>4}   render as BPMN processes", files.len());
    println!("   `CREATE VIEW` in the schema                     {views:>4}   ad-hoc views, never built");

    // ------------------------------------------------------------------
    // The three preconditions. Each is an assertion, not a report.
    // ------------------------------------------------------------------
    // ------------------------------------------------------------------
    // The pipeline's own order. Three programs share the drawings: `diagramming` and `graphs`
    // write BPMN into subdirectories of `assets/bpmn/` they own, and `rendering` reads both and
    // writes an SVG for each under `assets/svg/`. `rendering` must run last, and no program can
    // assert that it did, because the check would have to run after the last thing.
    //
    // So this checks what the right order leaves behind: every `.bpmn` owes a `.svg` at the same
    // path under `assets/svg/`, at least as new. That fails exactly when the pipeline runs out of
    // order or stops early, and the message gives the order that fixes it. The SVG is what lets a
    // reader check a drawing with no BPMN tool at hand.
    //
    // Guarded on existence: without `assets/bpmn/` there is nothing to render. Once it exists, it
    // must be complete.
    // ------------------------------------------------------------------
    let mut unrendered: Vec<String> = Vec::new();
    let mut stale: Vec<String> = Vec::new();
    let mut pairs = 0usize;
    // The two trees are separate, `assets/bpmn/` and `assets/svg/`, as `assets/sql/` and `.sqlx/`
    // are, so a program that wipes its BPMN directory leaves the drawings alone, and a stale
    // drawing is caught by its age.
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
        println!("\nThe pipeline, and whether it was run to the end");
        println!("   {pairs} BPMN documents, {} without an SVG, {} whose SVG is older",
                 unrendered.len(), stale.len());
        assert!(
            unrendered.is_empty() && stale.is_empty(),
            "the BPMN stage ran after the SVG stage, or instead of it, so the artifact a reader \
             verifies without a BPMN tool is missing or stale. Run: diagramming, graphs, then \
             rendering. unrendered {unrendered:?}, stale {stale:?}"
        );
        println!("   Every document is rendered and no SVG is older than its BPMN. The order");
        println!("      cannot be asserted from inside, so this checks what it leaves behind.");
    }

    println!("\nThe three preconditions, on the compose graph");

    let dangling: Vec<String> = edges
        .iter()
        .flat_map(|(f, ts)| ts.iter().filter(|t| !names.contains(t.as_str())).map(move |t| format!("{f} -> {t}")))
        .collect();
    println!("   1. every name resolves          {} directives, {} dangling", directives, dangling.len());
    assert!(dangling.is_empty(), "a :compose names a template that is not here: {dangling:?}");

    // Depth first, marking each template as on the current path or finished. Meeting one still on
    // the path means a template expands to itself; meeting a finished one only means two paths
    // reach it, which is fine. `composition/descent.sqlc` makes the same distinction with
    // SQL:2016's `CYCLE` clause, for the same reason.
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
    println!("   2. no name expands to itself    {} loops", cycles.len());
    assert!(cycles.is_empty(), "a template expands to itself: {cycles:?}");

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
    // A relation earns its place two ways: something composes it, or it is run, as a psql entry
    // point or by an example naming its composed output. A literal contract read straight by an
    // example composes nothing and is composed by nothing, and it still earns its place.
    // `observations` makes the same test, and both read `examples/` through `sources`, so the
    // two stay in step.
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
    // "Reads a base table" is not "reads `pm.`". `diagrams/catalogue.sqlc` reads
    // `information_schema`, on purpose: a contract needs a population it did not write, and the
    // catalogue is the one true source for which tables exist. A predicate that looked for `pm.`
    // alone would file it as a literal, the opposite of what it is.
    //
    // `public.` is a third case. `rank/compose_edges.sqlc` reads `public.compose_edge`, this
    // repository's own graph of compositions, which sits outside `pm` on purpose: everything in
    // `pm` descends from a filed document, and the graph descends from `assets/sqlc/`. Without
    // it, that template would be filed as a VALUES literal, when it reads a base table, just not
    // one of the subject.
    let touches_a_table = |b: &str| {
        let e = emitted(b);
        ["FROM pm.", "JOIN pm.", "FROM      pm.", "FROM public.", "JOIN public.",
         "information_schema.", "pg_constraint"]
            .iter()
            .any(|m| e.contains(m))
    };
    // A contract declares itself by being a literal, not by being called `roster`. Keying on the
    // filename would make the check a naming convention rather than a structural one.
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
    println!("\nThe leaf boundary, where a process stops calling and starts containing");
    println!("   {only_compose:>4}  compose only          a process of call activities");
    println!("   {only_table:>4}  read `pm.*` only       a process holding domain-object elements");
    println!("   {:>4}  do both               reaching past its own abstraction, and visible in a diagram", both.len());
    for n in &both {
        println!("         {n}");
    }
    // The fourth category is not a gap; it is the contracts. A roster names what the tree must
    // contain, so it cannot be derived from the tree: derived, what it declares and what the tree
    // produces could never disagree, and `reports/integrity.sqlc` would be anti-joining a set
    // against itself. That is why every one of them is a bare VALUES literal.
    println!("   {:>4}  neither               a VALUES literal: a contract, which must not be derived", literal.len());
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
         what a contract is, or the loader: {not_a_contract:?}"
    );

    // ------------------------------------------------------------------
    // The contrast, the section this example exists for.
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

    println!("\nDuplication: the same shape, and the opposite verdict");
    println!(
        "   {roots_with_a_diamond} of {} roots reach some composition by more than one path",
        roots.len()
    );
    println!("   worst: {} reaches {} compositions more than once", worst.0, worst.1);
    println!("   {} of {} compositions have more than one parent", indeg.values().filter(|v| **v > 1).count(), files.len());
    for (n, c) in most.iter().take(3) {
        println!("         {n} is composed {c} times");
    }
    println!("   Every one of these is correct: a query composed twice gives the same rows at");
    println!("      every copy, so nothing is counted twice.");
    println!("   The same shape in the part graph is `checks/jagged_layer`, a violation,");
    println!("      because supply is conserved and one total closes over both occurrences.");
    println!("      A supply counted twice is twice the supply. That difference is");
    println!("      the whole of what this model adds to `sql-composer` and to BPMN 2.0.");

    assert!(
        roots_with_a_diamond > 0,
        "no root reaches anything twice, so the contrast this example draws has no subject \
         and the claim that duplication is normal here is untested."
    );

    println!("\nAll checks passed.");
}
