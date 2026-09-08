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
//! Run it with a loaded database:
//!
//! ```text
//! psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!   cargo run --example soundness
//! ```

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

/// Templates that contain set-difference syntax but are not themselves a governed relation,
/// the `algebra/` laws, which are written *out of* differences in order to check them.
/// ⛔ Adding a name here removes a relation from the `unclaimed` guard, so it is the whole
/// decision: say why in the same breath.
const NOT_GOVERNED: &[(&str, &str)] = &[
    ("algebra/", "the laws themselves; each one counts a difference rather than taking one"),
    ("reports/integrity.sqlc", "governed as `integrity`, whose subjects are the contracts not the file"),
    ("invariance.sqlc", "a perturbation script, not a relation; its anti-joins scope a rewrite that is rolled back"),
];

/// Every `.sqlc` under a directory, with its body, named the way `:compose()` names it.
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

/// SQL only, `#` is a stripped template comment and `--` is a provenance line. Both discuss
/// these operators at length, and counting them is how a careless grep reports a dozen `EXISTS`
/// in a tree that contains none.
fn sql_only(body: &str) -> String {
    body.lines()
        .filter(|l| !l.trim_start().starts_with('#') && !l.trim_start().starts_with("--"))
        .collect::<Vec<_>>()
        .join("\n")
}

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

    println!("\nAll checks passed.");
    Ok(())
}
