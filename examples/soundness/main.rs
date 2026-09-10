// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT.
// GitHub renders a directory's README and renders no `//!` block at all, so an argument
// kept only in the source is unreadable from the one place this repository is published.
// `include_str!` makes that same file rustdoc's page, so the two renderings cannot disagree
// and a missing header is a compile error rather than a blank row on the front page.
//
// ⭐⭐ BOTH LANGUAGES ARE INCLUDED, WHICH IS WHAT THE SCHEMAS ALREADY DO. An `xs:annotation`
// holds an `xml:lang="en"` block and an `xml:lang="pt"` block and the generator concatenates
// them into one Rust doc comment; these two files are the same arrangement one directory over.
// A Portuguese page rendered nowhere would be a translation nobody reads, which is the
// second-class citizenship `tests/translation.rs` exists to refuse.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;
use tree::{emitted, reaches, references, sql_only, templates};

/// Templates that contain set-difference syntax but are not themselves a governed relation,
/// the `algebra/` laws, which are written *out of* differences in order to check them.
/// ⛔ Adding a name here removes a relation from the `unclaimed` guard, so it is the whole
/// decision: say why in the same breath.
const NOT_GOVERNED: &[(&str, &str)] = &[
    ("algebra/", "the laws themselves; each one counts a difference rather than taking one"),
    ("reports/integrity.sqlc", "governed as `integrity`, whose subjects are the contracts not the file"),
    ("invariance.sqlc", "a perturbation script, not a relation; its anti-joins scope a rewrite that is rolled back"),
];

/// Contracts in `reports/integrity.sqlc` whose POPULATION composes the roster it is differenced
/// against, so the subject's NAME is on both sides of the difference by construction.
/// ⛔ Adding a name here takes a second witness away from a guard, so it is the whole decision:
/// say why in the same breath.
const BORROWS_ITS_SUBJECT: &[(&str, &str)] = &[
    ("algebra", "the roster join is what makes a law with no subjects report VACUOUS rather than vanish"),
    ("arithmetic", "the same, so a site with nothing to compute reports rather than vanishes"),
    ("rules", "the same, and the one whose price rank/guard_cover.sqlc can currently see"),
];

/// Does this template take a set difference? `EXCEPT`, `NOT EXISTS`, or a `LEFT JOIN` whose
/// result is filtered on `IS NULL`, as opposed to the roster cross (`ON true`), an outer join
/// proper, or the form where the NULL *is* the verdict (`x IS NULL AS violates`).
///
/// ⛔ THREE SPELLINGS, NOT TWO, AND A MISSING ONE IS SILENT. `NOT EXISTS` is an anti-semijoin
/// and therefore a difference; `composition/carried.sqlc` takes two. A spelling this function
/// does not know is a difference the `unclaimed` guard never examines, so the guard prints
/// `All checks passed` and proves nothing about it. `EXISTS` alone is a semijoin and is NOT a
/// difference. Add a spelling here before adding one to the tree.
fn takes_a_difference(sql: &str) -> bool {
    if sql.contains("EXCEPT") || sql.contains("NOT EXISTS") {
        return true;
    }
    sql.split("LEFT JOIN").skip(1).any(|seg| {
        let seg = seg.split("\nUNION").next().unwrap_or(seg);
        let filters = seg
            .lines()
            .any(|l| {
                let t = l.trim_start();
                (t.starts_with("WHERE") || t.starts_with("AND")) && t.contains("IS NULL")
            });
        // ⛔ `IS NULL AS <col>` is the verdict form, not a filter, the NULL is the answer.
        filters && !seg.contains("IS NULL AS")
    })
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example checks that the queries compute what they claim, \
         and it cannot do that without running them. Load the rows with assets/ddl/schema.ddl."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. Every declared law, and whether it holds.
    // ------------------------------------------------------------------
    let laws = sqlx::query_file!("assets/sql/queries/soundness/1-laws.sql")
        .fetch_all(&pool)
        .await?;

    println!("1. set-algebraic laws: {} subject(s) checked\n", laws.len());
    let mut last = "";
    for l in &laws {
        if l.law != last {
            println!("   {}", l.law);
            last = &l.law;
        }
        let mark = match l.holds {
            Some(true) => "  ",
            Some(false) => "⛔",
            None => "⛔", // VACUOUS: the law had no subjects
        };
        println!("   {mark} {:<46} {}", l.subject, l.detail);
    }

    // ⛔⛔ A law that examined nothing is not a law that held. `holds` is NULL only on the roster
    //     row that found no subjects, and that is the ⛔ VACUOUS verdict, the same trap
    //     reports/coverage.sqlc names for rules.
    let vacuous: Vec<&str> = laws
        .iter()
        .filter(|l| l.holds.is_none())
        .map(|l| l.law.as_str())
        .collect();
    let broken: Vec<&str> = laws
        .iter()
        .filter(|l| l.holds == Some(false))
        .map(|l| l.subject.as_str())
        .collect();

    println!(
        "\n   {} hold, {} broken, {} vacuous",
        laws.iter().filter(|l| l.holds == Some(true)).count(),
        broken.len(),
        vacuous.len()
    );
    assert!(broken.is_empty(), "a relation does not compute what it claims: {broken:?}");
    assert!(vacuous.is_empty(), "a law examined nothing: {vacuous:?}");

    // ------------------------------------------------------------------
    // 2. Every set difference in the tree is governed by a law.
    // ------------------------------------------------------------------
    let sqlc = Path::new("assets/sqlc");
    let mut files = Vec::new();
    templates(sqlc, sqlc, &mut files);

    let roster = sqlx::query_file!("assets/sql/queries/soundness/3-governed.sql")
        .fetch_all(&pool)
        .await?;
    let governed: BTreeSet<&str> = roster.iter().map(|r| r.governs.as_str()).collect();

    let mut unclaimed: Vec<&str> = Vec::new();
    for (name, body) in &files {
        if !takes_a_difference(&sql_only(body)) {
            continue;
        }
        if NOT_GOVERNED.iter().any(|(pat, _)| name.starts_with(pat) || name == *pat) {
            continue;
        }
        let stem = name.trim_end_matches(".sqlc");
        if !governed.contains(stem) {
            unclaimed.push(name);
        }
    }
    unclaimed.sort_unstable();

    println!("\n2. set differences in the tree: {} governed", governed.len());
    for r in &roster {
        println!("   {:<40} {:<11} {}", r.governs, r.form, r.multiplicity);
    }
    for (pat, why) in NOT_GOVERNED {
        println!("   · {pat:<28} exempt {why}");
    }
    for u in &unclaimed {
        println!("   ⛔ {u} takes a difference and no law governs it");
    }

    // ⛔⛔⛔ `unclaimed` IS asrt:Verdict's OWN WORD FOR THIS, and it is the verdict the run record
    //     calls the most valuable line: a guard believed to be there and never once checked.
    //     A difference added without a law is exactly that, and it is silent in every other test.
    assert!(
        unclaimed.is_empty(),
        "a set difference is governed by no law in algebra/roster.sqlc"
    );

    // ------------------------------------------------------------------
    // 3. The rosters and their populations agree, every contract this repository declares.
    // ------------------------------------------------------------------
    let drift = sqlx::query_file!("assets/sql/queries/soundness/2-integrity.sql")
        .fetch_all(&pool)
        .await?;

    println!("\n3. contract integrity: {} disagreement(s)", drift.len());
    for d in &drift {
        println!("   ⛔ [{}] {}: {}", d.contract, d.problem, d.subject);
    }
    assert!(drift.is_empty(), "a roster and its population disagree");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ WHAT ONE EXAMINED ROW OF EACH RULE IS, DECLARED, AGAINST WHAT ITS ROWS ACTUALLY ARE.
    //    `checks/all.sqlc` returns `(rule, filing, layer, violates, detail)` and its header reads
    //    *which layer of which filing it is*. That is FALSE wherever the examined item is finer
    //    than a layer, a PART, a SLACK or a CLAIM, so `(filing, layer)` is not a key and survives
    //    only inside the prose `detail`.
    //
    // ⭐⭐ AND IT SPLITS A BAG THAT WAS BEING CALLED ONE THING. `invariance.sqlc` says the
    //    relation is a bag because *several items per layer produce the same sentence*; that is
    //    true of TWO rules, and for the other five every row says something DIFFERENT. The bag is
    //    mostly a GRAIN artifact. ⭐ That file's count-don't-subtract repair is correct for both,
    //    which means it was more general than the reason given for it.
    //
    // ⛔ ONE DIRECTION ONLY. A rule declaring `layer` owes exactly one row per `(filing, layer)`;
    //   a second means it silently changed what it examines and the count moves with nothing
    //   saying what the count is OF. The converse is not assertable: a part-grained rule may see
    //   one part per layer in a corpus that files one, and accusing it reads luck as a claim.
    // ------------------------------------------------------------------
    let grain = sqlx::query_file!("assets/sql/checks/grain.sql").fetch_all(&pool).await?;
    let misdeclared: Vec<&str> = grain
        .iter()
        .filter(|g| g.finer_than_declared == Some(true))
        .map(|g| g.slug.as_deref().unwrap_or("?"))
        .collect();
    let mut by_subject: std::collections::BTreeMap<&str, (usize, i64, i64)> = Default::default();
    for g in &grain {
        let e = by_subject.entry(g.declares.as_deref().unwrap_or("?")).or_default();
        e.0 += 1;
        e.1 += g.rows.unwrap_or(0);
        e.2 += g.layers.unwrap_or(0);
    }
    println!("\n4. what one examined row IS, per rule");
    for (subject, (rules, rows, layers)) in &by_subject {
        println!("   {subject:<7} {rules:>2} rules   {rows:>4} rows over {layers:>4} layers{}",
                 if rows == layers { "   one row per layer" } else { "   FINER than a layer" });
    }
    // ⛔⛔⛔ AND THE SECOND ARM, WHICH THE FIRST COULD NOT BE. `finer_than_declared` asks whether
    //    the key is unique per row. This asks whether the key RESOLVES. Three rules put a claim
    //    ADDRESS in the `layer` column, `pm:nameplate/pm:amount claim 7`, 523 rows over 324
    //    distinct values, and the multiplicity arm read false on all three: a value unique per
    //    row satisfies *one row per key* by construction, so what makes the column wrong is
    //    exactly what makes the multiplicity arm pass. ⭐ And anything joining a verdict to a
    //    layer keeps only the pairs that resolve and drops the rest, with the join looking
    //    perfect either way.
    let unresolvable: Vec<(&str, i64)> = grain
        .iter()
        .filter(|g| g.unresolvable.unwrap_or(0) > 0)
        .map(|g| (g.slug.as_deref().unwrap_or("?"), g.unresolvable.unwrap_or(0)))
        .collect();
    let checked: i64 = grain.iter().map(|g| g.rows.unwrap_or(0)).sum();
    assert!(
        unresolvable.is_empty(),
        "a rule returns a `(filing, layer)` that names no filed layer, so its verdict cannot be \
         attributed to anything and every join through that key drops it in silence: \
         {unresolvable:?}"
    );
    println!("   {checked} verdict rows, every non-null (filing, layer) a layer somebody filed");
    assert!(!grain.is_empty(), "no rule was examined, so the grain law examined nothing");
    assert!(
        by_subject.len() > 1,
        "every rule declares the same subject, so this law cannot discriminate and the column \
         is decoration"
    );
    assert!(
        misdeclared.is_empty(),
        "a rule declares its subject is a layer and emits more than one row per layer, so it \
         examines something finer than it says and the coverage number counts the wrong unit: \
         {misdeclared:?}"
    );
    println!("   ⭐ The coverage number has a UNIT now. `examined 20` is twenty PARTS for one rule");
    println!("      and twenty LAYERS for another, and the `< 3 is thin` threshold ran across both.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ WHICH GUARDS HAVE A SECOND WITNESS, AND WHICH ARE THE ROSTER READ TWICE.
    //    `diagrams/domain_objects.sqlc` states the rule for one side and the tree is asserted to
    //    keep it: a contract must not be derived from what it governs, so every roster here is a
    //    bare VALUES literal. NOTHING STATES THE CONVERSE, and some of the populations
    //    `reports/integrity.sqlc` differences take their subject's NAME from the very roster they
    //    are compared against. The table below is which.
    //
    // ⭐⭐ IT IS A TRADE AND NOT A DEFECT, WHICH IS EXACTLY WHY IT HAS TO BE DECLARED. The roster
    //    join is what buys ⛔ VACUOUS: a rule with nothing to examine still emits a row, so the
    //    verdict that matters most is a row a reader can see rather than a silence. The price is
    //    that the subject is then on both sides of the difference by construction, and
    //    `rank/guard_cover.sqlc` counts what the corpus makes of that. This says which contracts
    //    pay it, which is a fact about the TEMPLATES and out of a query's reach.
    //
    // ⛔ THE DIRECTION THAT BITES IS A CONTRACT LEAVING THE INDEPENDENT COLUMN. `diagrams` reads
    //   its population out of `information_schema` and `diagram laws` names each law in its own
    //   arm; a refactor that routed either through its roster "so the names line up" would take
    //   a real second witness away and every other check here would still pass.
    // ------------------------------------------------------------------
    let edges: BTreeMap<&str, Vec<String>> = files
        .iter()
        .map(|(n, b)| (n.as_str(), references(&emitted(b))))
        .collect();

    // ⭐⭐⭐ THE PAIR COMES FROM THE TWO OPERANDS AND NOT FROM THE DIFFERENCE, SO THE SIDES ARE
    //    NAMED. `algebra/declared_subjects.sqlc` is the rosters and
    //    `algebra/produced_subjects.sqlc` is the populations. ⛔ Read off the difference instead,
    //    this law gets two relations per contract with no way to say WHICH is the roster, and has
    //    to test reachability both ways and take whichever answers.
    // ⚠️ AND IT DETECTS A PROPERTY BY PARSING, WHICH IS THE COST TO KNOW ABOUT. `checks/all.sqlc`
    //    composing `checks/roster.sqlc` is what makes the property true; this law only sees it
    //    where it happens to be written. A detector keyed on WHERE a fact is written fails on a
    //    refactor that keeps the fact true.
    let arms = |name: &str| -> BTreeMap<String, String> {
        let body = files
            .iter()
            .find(|(n, _)| n == name)
            .map(|(_, b)| sql_only(b))
            .unwrap_or_else(|| panic!("{name} is in the tree"));
        let mut out = BTreeMap::new();
        let mut label: Option<String> = None;
        for line in body.lines() {
            if let Some(l) = line.split_once("SELECT '").and_then(|(_, r)| r.split_once('\'')) {
                label = Some(l.0.to_string());
            }
            if let (Some(lab), Some(rel)) = (
                label.clone(),
                line.split_once(":compose(")
                    .and_then(|(_, r)| r.split_once(|c| c == ')' || c == ','))
                    .map(|(t, _)| t.trim().to_string()),
            ) {
                out.insert(lab, rel);
                label = None;
            }
        }
        out
    };
    let rosters = arms("algebra/declared_subjects.sqlc");
    let populations = arms("algebra/produced_subjects.sqlc");
    let mut pairs: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for (label, roster) in &rosters {
        let Some(pop) = populations.get(label) else { continue };
        let e = pairs.entry(label.as_str()).or_default();
        e.insert(roster.as_str());
        e.insert(pop.as_str());
    }

    println!("\n5. what stands behind each contract's own difference");
    let mut borrowed: BTreeSet<&str> = BTreeSet::new();
    let mut independent: BTreeSet<&str> = BTreeSet::new();
    let mut unreadable: Vec<&str> = Vec::new();
    for (label, ts) in &pairs {
        let t: Vec<&str> = ts.iter().copied().collect();
        let [a, b] = t[..] else {
            unreadable.push(label);
            continue;
        };
        let (borrows, shown) = if reaches(&edges, a, b, &mut BTreeSet::new()) {
            (true, format!("{a} reaches {b}"))
        } else if reaches(&edges, b, a, &mut BTreeSet::new()) {
            (true, format!("{b} reaches {a}"))
        } else {
            (false, format!("{a} and {b} share no edge"))
        };
        if borrows {
            borrowed.insert(label);
        } else {
            independent.insert(label);
        }
        println!(
            "   {:<13} {:<66} {}",
            label,
            shown,
            if borrows { "⛔ the roster twice" } else { "a second witness" }
        );
    }
    for (contract, why) in BORROWS_ITS_SUBJECT {
        println!("   · {contract:<11} {why}");
    }

    assert!(
        unreadable.is_empty(),
        "a contract in reports/integrity.sqlc does not name exactly two relations on its own \
         lines, so this law cannot tell which side is the roster and has lost its subject: \
         {unreadable:?}"
    );
    let declared: BTreeSet<&str> = BORROWS_ITS_SUBJECT.iter().map(|(c, _)| *c).collect();
    let undeclared: Vec<&&str> = borrowed.difference(&declared).collect();
    let stale: Vec<&&str> = declared.difference(&borrowed).collect();
    assert!(
        undeclared.is_empty(),
        "a contract's population composes the roster it is differenced against and nothing says \
         so, which takes the second witness out of a guard while every other check here passes: \
         {undeclared:?}"
    );
    assert!(
        stale.is_empty(),
        "a contract is declared to take its subject from its own roster and no longer does, so \
         the reason written beside it describes something that is not there: {stale:?}"
    );
    // ⛔ A law every subject passes the same way is decoration, and this one would be if the
    //   tree ever held only the one shape. Both columns have to stay populated for it to mean
    //   anything at all.
    assert!(
        !borrowed.is_empty() && !independent.is_empty(),
        "every contract is built the same way, so this law cannot discriminate and the column \
         it prints says nothing"
    );

    // ------------------------------------------------------------------
    // ⛔⛔⛔ AND WHETHER A RULE STILL REPORTS THAT IT EXAMINED NOTHING, MEASURED ON A CORPUS
    //    MADE EMPTY FOR THE PURPOSE. `⛔ VACUOUS` is the verdict this repository calls the most
    //    important one it can return, and the roster join is the only thing producing it. With
    //    rows on hand every arm emits `1 + examined` whether the join carries the roster or not,
    //    so the corpus that can see a broken one is the corpus with nothing in it.
    //
    // ⭐⭐ THE PERTURBATION IS THE ANSWER TO A GUARD WHOSE REACH WAS A PROPERTY OF THE CORPUS.
    //    `reports/integrity.sqlc` branch one reports a broken roster join only for the rules
    //    nothing yet populates, and it loses even those the day a filing sizes a buffer. Here it
    //    is every subject on both rosters, and it gets STRONGER as they grow.
    //
    // ⛔⛔ NOTHING IS COMMITTED. The truncate runs inside a transaction that is rolled back, the
    //    idiom `examples/generation/main.rs` and `assets/sqlc/invariance.sqlc` already use, so the
    //    database this reads is the database it leaves. ⛔ It is the only write this example
    //    makes, and it is the reason the example now needs a corpus it is allowed to touch.
    //
    // ⛔ THE TABLE LIST IS READ FROM THE CATALOGUE rather than written here, for the reason
    //   diagrams/catalogue.sqlc gives: a list of tables restated in a second place is a list
    //   that stops matching the schema and cannot say so.
    // ------------------------------------------------------------------
    let mut tx = pool.begin().await?;
    let tables: String = sqlx::query_scalar(
        "SELECT string_agg(format('pm.%I', tablename), ', ') FROM pg_tables WHERE schemaname = 'pm'",
    )
    .fetch_one(&mut *tx)
    .await?;
    // ⛔ `AssertSqlSafe` IS THE AUDIT sqlx ASKS FOR, AND HERE IT IS DISCHARGED BY `format('pm.%I')`:
    //   Postgres quotes the identifier itself, the names come from `pg_tables` rather than from
    //   anything a document said, and the statement runs in a transaction that is rolled back.
    sqlx::query(sqlx::AssertSqlSafe(format!("TRUNCATE {tables} CASCADE")))
        .execute(&mut *tx)
        .await?;

    let vacuity = sqlx::query_file!("assets/sql/queries/soundness/4-vacuity.sql")
        .fetch_all(&mut *tx)
        .await?;
    tx.rollback().await?;

    let mut by_contract: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for v in &vacuity {
        let e = by_contract.entry(v.contract.as_str()).or_default();
        e.0 += 1;
        if v.rows == 1 {
            e.1 += 1;
        }
    }
    println!("\n6. with the corpus emptied, does every rule still report that it ran");
    for (contract, (declared, silent)) in &by_contract {
        println!("   {contract:<11} {silent:>3} of {declared:>3} emit exactly the one row that says ⛔ VACUOUS");
    }
    let mute: Vec<&str> = vacuity
        .iter()
        .filter(|v| v.rows != 1)
        .map(|v| v.subject.as_str())
        .collect();
    // ⛔ AND THE ROW HAS TO CARRY NO VERDICT. One row saying `false` over a corpus with nothing in
    //   it is a check answering about rows it does not have, which the row count alone reads as
    //   healthy. Two different defects, so two assertions.
    let answered: Vec<&str> = vacuity
        .iter()
        .filter(|v| v.verdicts != 0)
        .map(|v| v.subject.as_str())
        .collect();
    assert!(
        !vacuity.is_empty(),
        "no subject came back from an emptied corpus, so this law examined nothing and is the \
         trap it exists to catch"
    );
    assert!(
        mute.is_empty(),
        "with nothing to examine a check emits no row at all, so the rule reports its silence by \
         being silent and ⛔ VACUOUS becomes indistinguishable from a rule that does not exist: \
         {mute:?}"
    );
    assert!(
        answered.is_empty(),
        "with nothing to examine a check returned a verdict anyway, so it is answering about rows \
         it does not have and the coverage table will count them as examined: {answered:?}"
    );
    println!("   ⭐ The roster row exists before the population does, which is what makes");
    println!("      \"a bound with nothing to bound passes loudest\" a verdict here instead of a worry.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ THE EMITTED DAG CAN GO STALE, WHICH IS WHAT THE GENERATE-THEN-LOAD SHAPE COSTS.
    //    `examples/compositions/main.rs` writes `assets/dag/edges.sql` from the source tree and
    //    `ingest` loads it, so a `:compose` added without rerunning the emitter leaves the
    //    database describing an older tree. Nothing else here would notice: every relation over
    //    the DAG would be internally consistent and about the wrong repository.
    //
    // ⚠️ THIS IS A STALENESS CHECK AND NOT TWO INDEPENDENT ROUTES, and the difference matters.
    //    It re-derives through the SAME `examples/shared/tree` module the emitter used, so it catches
    //    the ARTIFACT drifting from the tree and could never catch the scanner being wrong about
    //    both. Two routes would need a second scanner, which is the duplication this replaced.
    // ------------------------------------------------------------------
    let dag_now: BTreeMap<(String, String), usize> = {
        let sqlc = Path::new("assets/sqlc");
        let mut fs_files = Vec::new();
        templates(sqlc, sqlc, &mut fs_files);
        let mut m: BTreeMap<(String, String), usize> = BTreeMap::new();
        for (name, body) in &fs_files {
            for child in references(&emitted(body)) {
                *m.entry((name.clone(), child)).or_default() += 1;
            }
        }
        // ⚠️ SPLICES ONLY. `inner_joins` is classified by `examples/compositions/main.rs` from the SQL
        //   text, and re-deriving it here would be a second detector rather than a second route:
        //   this law's job is that the LOADED artifact matches the tree's edges, and the syntax
        //   column has its own positive control in the emitter.

        m
    };
    let dag_loaded = sqlx::query_file!("assets/sql/rank/compose_edges.sql")
        .fetch_all(&pool)
        .await?;
    let loaded: BTreeMap<(String, String), usize> = dag_loaded
        .iter()
        .map(|e| ((e.parent.clone(), e.child.clone()), e.splices as usize))
        .collect();
    assert!(!dag_now.is_empty(), "the source tree has no :compose directive, so this law is vacuous");
    assert_eq!(
        dag_now, loaded,
        "public.compose_edge does not match assets/sqlc/ as it stands on disk. Rerun \
         `cargo run --example compositions` to regenerate assets/dag/edges.sql and reload the \
         ingest: every relation over the DAG is otherwise describing an older tree, consistently"
    );
    println!("\n7. the compose DAG, loaded against the source tree");
    println!("   {} pairs, {} directives, {} pairs spliced more than once",
             loaded.len(), loaded.values().sum::<usize>(),
             loaded.values().filter(|n| **n > 1).count());
    println!("   ⭐ A parent splicing a child twice is ORDINARY here and `checks/jagged_layer` in");
    println!("      `pm.part`. Two graphs of one shape, opposite verdicts on one column, and the");
    println!("      comparison is a query now rather than a sentence in a program's output.");

    println!("\nAll checks passed.");
    Ok(())
}
