//! Does the machinery do what it claims?
//!
//! The other examples ask about the arithmetic, the data, the corpus, and what a generated run
//! can be made to say. This one asks about the **queries themselves**, whether each relation
//! computes the operation it says it does. It is the only one that can accuse nobody's filing.
//!
//! ⭐⭐⭐ IT EXISTS BECAUSE A SET DIFFERENCE FAILS TO A PLAUSIBLE TABLE, NEVER TO AN ERROR.
//! `EXCEPT` and `LEFT JOIN … IS NULL` return the right shape, the right column names and a
//! believable count when they are wrong. Written once with the parentheses misplaced,
//! `reports/integrity.sqlc` returned 227 rows where 0 was correct, and 227 well-formed rows is
//! not a thing anybody reads twice.
//!
//! ⭐⭐ AND THE LAW IS CHECKABLE WITHOUT TOUCHING A FILE. |A ∖ B| = |A| − |A ⋉ B|, so a difference
//! and its semijoin must partition the left operand. As a manual probe that is edit the
//! template, recompose, observe, revert: a procedure nothing repeats, and one where a `sed`
//! silently matching nothing reports a false finding. Each law is a query instead.
//!
//! ⛔ THE SECOND ASSERTION IS THE ONE THAT MATTERS MOST. Every set difference in `assets/sqlc/`
//! must appear on `algebra/roster.sqlc`. A difference nobody declared a law for is
//! `asrt:Verdict`'s `unclaimed`, a guard believed to be there and never once checked.
//!
//! ⛔⛔ AND ONE OF THE LAWS IS NOT A QUERY, BECAUSE IT COULD NOT BE. §6 asks whether a rule still
//! reports that it examined NOTHING, and that is visible only where the population is nothing, so
//! it empties the corpus: a `TRUNCATE` inside a transaction that is rolled back, the idiom
//! `examples/generation/main.rs` and `assets/sqlc/invariance.sqlc` already use. The database this reads
//! is the database it leaves.
//!
//! ⛔ IT IS THE ONLY WRITE THIS EXAMPLE MAKES, AND IT TAKES AN `ACCESS EXCLUSIVE` LOCK WHILE IT
//! RUNS. So this is no longer an example to point at a database somebody else is reading, which
//! is a change in what it costs to run and not only in what it checks.
//!
//! Run it with a loaded database:
//!
//! ```text
//! psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!   cargo run --example soundness
//! ```

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
    //    *which layer of which filing it is*. That is FALSE for seven of the rules: their subject
    //    is a PART or a SLACK, so `(filing, layer)` is not a key and the item's identity survives
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
    let integrity = files
        .iter()
        .find(|(n, _)| n == "reports/integrity.sqlc")
        .map(|(_, b)| sql_only(b))
        .expect("reports/integrity.sqlc is in the tree");
    let edges: BTreeMap<&str, Vec<String>> = files
        .iter()
        .map(|(n, b)| (n.as_str(), references(&emitted(b))))
        .collect();

    // Each arm of the difference names its contract and composes one of that contract's two
    // relations on the same line, so the pair falls out of the file that declares it.
    let mut pairs: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for line in integrity.lines() {
        let label = line.split_once("SELECT '").and_then(|(_, r)| r.split_once('\'')).map(|(l, _)| l);
        let rel = line
            .split_once(":compose(")
            .and_then(|(_, r)| r.split_once(|c| c == ')' || c == ','))
            .map(|(t, _)| t.trim());
        if let (Some(label), Some(rel)) = (label, rel) {
            pairs.entry(label).or_default().insert(rel);
        }
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

    println!("\nAll checks passed.");
    Ok(())
}
