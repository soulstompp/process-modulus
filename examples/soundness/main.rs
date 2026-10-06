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
#![doc = include_str!("../../pt-PT/examples/soundness/README.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;
use tree::{emitted, reaches, references, sql_only, templates};

/// Templates that contain set-difference syntax but are not themselves a governed relation: the
/// `algebra/` laws, which are written out of differences in order to check them. Adding a name
/// here removes a relation from the `unclaimed` guard, so it is the whole decision: say why in the
/// same breath.
const NOT_GOVERNED: &[(&str, &str)] = &[
    ("algebra/", "the laws themselves; each one counts a difference rather than taking one"),
    ("invariance.sqlc", "a perturbation script, not a relation; its anti-joins scope a rewrite that is rolled back"),
];

/// Contracts whose population composes the roster its fold joins it to, so the subject's name is
/// on both sides of the outer join by construction. Adding a name here takes a second witness away
/// from a guard, so it is the whole decision: say why in the same breath.
const BORROWS_ITS_SUBJECT: &[(&str, &str)] = &[
    ("algebra", "the roster join makes a law with no subjects say it examined nothing, not vanish"),
    ("arithmetic", "the same, so a site with nothing to compute reports rather than vanishes"),
    ("rules", "the same, and the one whose price rank/guard_reach.sqlc can currently see"),
];

/// Does this template take a set difference? `EXCEPT`, `NOT EXISTS`, or a `LEFT JOIN` whose
/// result is filtered on `IS NULL`, as opposed to the roster cross (`ON true`), an outer join
/// proper, or the form where the NULL *is* the verdict (`x IS NULL AS violates`).
///
/// Three spellings, not two, and a missing one is silent. `NOT EXISTS` keeps the rows with no
/// match, so it is a difference; `composition/carried.sqlc` takes two. A spelling this function
/// does not know is a difference the `unclaimed` guard never examines, so the guard prints
/// `All checks passed` and shows nothing about it. `EXISTS` alone keeps the rows with a match and
/// is not a difference. Add a spelling here before adding one to the tree.
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
        // `IS NULL AS <col>` is the verdict form, not a filter: the NULL is the answer.
        filters && !seg.contains("IS NULL AS")
    })
}

/// What each template that multiplies by a conversion factor does with the operand's sign.
///
/// The conversion is one operator, and a count of sites cannot find a second one. A relation that
/// reads the corner its operand's sign picks, and a law that checks it by multiplying bound by
/// bound, compute two different things. They agree on every operand that is not negative, no
/// filed operand is negative, and so every law stays green while the law and the relation it
/// checks disagree about the arithmetic. A law that computes something else is not independent of
/// the relation; it is wrong about it.
///
/// The tree is held against this list in both directions: a template that starts multiplying by a
/// factor fails this program until it appears here, and an entry whose template stops multiplying
/// fails too. Adding a row is the whole decision, so say why in the same breath.
const CONVERSIONS: &[(&str, Corner, &str)] = &[
    ("algebra/derived_quantities.sqlc", Corner::Takes,
     "one level of the recursion, by its own route"),
    ("algebra/fusion_sum.sqlc", Corner::Takes,
     "the fusion sum, recomputed by its own route"),
    // `p_low` here is an accumulated factor and not a quantity, the one row on this roster whose
    // exemption cannot be read off the column names.
    ("checks/conversion_cycle_does_not_close.sqlc", Corner::PathProduct,
     "the walk's accumulated factor times the next edge's, so both operands are factors"),
    ("composition/attenuated.sqlc", Corner::OneCorner,
     "the share is read where it is largest, the reading that refuses to accuse"),
    ("composition/carriable.sqlc", Corner::Takes,
     "the one-part fusion's converted figure, the population the identity test compares"),
    ("composition/carried_eliminations.sqlc", Corner::Takes,
     "an elimination carried into the root's unit, at the corner its own sum used"),
    ("composition/composed_quantum.sqlc", Corner::Takes,
     "each part's quantum put into the composed unit at each of its three points"),
    ("composition/converted.sqlc", Corner::Takes,
     "a part's quantity put into the composed unit"),
    ("composition/conversion_slopes.sqlc", Corner::TheComparison,
     "the bound-by-bound figure is this relation's subject, reported beside the corner one"),
    ("composition/derived_frontier.sqlc", Corner::PathProduct,
     "factor times factor down the walk"),
    ("composition/derived_quantities.sqlc", Corner::Takes,
     "the elimination and the nameplate, each by the product of the factors above it"),
    ("composition/descent.sqlc", Corner::PathProduct,
     "factor times factor down the walk"),
    ("composition/remainder_frontier.sqlc", Corner::PathProduct,
     "factor times factor down the walk"),
    ("composition/settled_remainders.sqlc", Corner::Takes,
     "a part's remainder, which is the one operand here that actually goes negative"),
];

/// How a site reads the sign of what it converts. Every arm but `Takes` is a reason the corner
/// does not arise, never a licence to read the sign a second way.
#[derive(Clone, Copy, PartialEq)]
enum Corner {
    /// `least(x * f_low, x * f_high)` and its `greatest` twin: the operand's sign picks the corner.
    Takes,
    /// Factor times factor. `pm.part` CHECKs the low strictly positive and the three ordered, which
    /// between them put all three above zero, so the product is the conversion the whole path
    /// performs and there is no sign to read. Only `a_factor_is_strictly_positive` names the low;
    /// `a_factor_claim_is_whole_and_ordered` is what carries it to the other two.
    PathProduct,
    /// One corner on purpose, argued in that template's own header.
    OneCorner,
    /// The naive figure, kept because comparing against it is what the template is for.
    TheComparison,
}

impl Corner {
    fn word(self) -> &'static str {
        match self {
            Corner::Takes => "corner",
            Corner::PathProduct => "path product",
            Corner::OneCorner => "one corner",
            Corner::TheComparison => "the comparison",
        }
    }
}

/// Does this template multiply something by a conversion factor? Several relations only select
/// the factor columns, so the test is a multiplication next to the token and not the token alone.
///
/// A spelling this function does not know is a conversion the roster never examines, and the
/// guard then prints a pass and shows nothing about it. It knows the factor on either side of a
/// `*`, with or without a `coalesce(..., 1)` round it. Add a spelling here before adding one to
/// the tree. A false positive is safe: it forces a roster row, which fails loudly and is answered
/// by writing down what that site does.
fn multiplies_by_a_factor(sql: &str) -> bool {
    // `SELECT *`, `t.*` and `count(*)` are not multiplications, and they are the only other `*`.
    let flat = sql
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
        .replace("SELECT *", "SELECT_ALL")
        .replace(".*", "_ALL")
        .replace("count(*)", "count_ALL");
    ["factor_low", "factor_mode", "factor_high"].iter().any(|f| {
        let parts: Vec<&str> = flat.split(f).collect();
        parts.windows(2).any(|w| {
            let before: String = w[0].chars().rev().take(48).collect();
            let after: String = w[1].chars().take(48).collect();
            before.contains('*') || after.contains('*')
        })
    })
}

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example checks that the queries compute what they claim, \
         and it cannot do that without running them. Load the rows with assets/ddl/schema.ddl."
    })?;
    let pool = database::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. Every declared law, and whether it holds.
    // ------------------------------------------------------------------
    let laws = sqlx::query_file!("assets/sql/queries/soundness/1-laws.sql")
        .fetch_all(&pool)
        .await?;

    println!("1. laws: {} subject(s) checked\n", laws.len());
    let mut last = "";
    for l in &laws {
        if l.law != last {
            println!("   {:<22} {}", l.law, l.formula);
            last = &l.law;
        }
        let mark = match l.holds {
            Some(true) => "  ",
            Some(false) => "no",
            None => "no", // vacuous: the law had no subjects
        };
        println!("   {mark} {:<46} {}", l.subject, l.detail);
    }

    // A law that examined nothing is not a law that held. `holds` is NULL only on the roster row
    // that found no subjects, the vacuous verdict, the same trap reports/coverage.sqlc names for
    // rules.
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

    // The laws' own fold is checked from here, because no law can check it.
    // `folds/law_subjects.sqlc` counts `algebra/all.sqlc`'s rows per law into the verdict's boxes,
    // and a law composing it would compose itself. The rows above are the same population read
    // without the fold, so they are counted into the same boxes here and must agree law by law,
    // and the fold's own boxes must add up to its rows.
    let fold = sqlx::query_file!("assets/sql/folds/law_subjects.sql").fetch_all(&pool).await?;
    let mut tally: BTreeMap<&str, [i64; 5]> = BTreeMap::new();
    for l in &laws {
        let c = tally.entry(l.law.as_str()).or_default();
        c[0] += 1;
        match l.holds {
            Some(true) => c[1] += 1,
            Some(false) => c[2] += 1,
            None if !l.subject.is_empty() => c[3] += 1,
            None => c[4] += 1,
        }
    }
    let mut miscounted: Vec<String> = Vec::new();
    for f in fold.iter().filter(|f| f.declared == Some(true)) {
        let subject = f.subject.as_deref().unwrap_or("");
        let n = |x: Option<i64>| x.unwrap_or(0);
        let counted = [n(f.rows), n(f.holding), n(f.failing), n(f.silent), n(f.vacuous)];
        let adds_up = counted[0] == n(f.answered) + counted[3] + counted[4]
            && n(f.answered) == counted[1] + counted[2];
        let from_rows = tally.get(subject).copied().unwrap_or_default();
        if !adds_up || counted != from_rows {
            miscounted.push(format!("{subject}: fold {counted:?}, rows {from_rows:?}"));
        }
    }
    println!(
        "   the laws' own fold: {} laws, each counted into the same boxes from the rows above",
        fold.iter().filter(|f| f.declared == Some(true)).count()
    );
    assert!(
        miscounted.is_empty(),
        "folds/law_subjects.sqlc does not count algebra/all.sqlc the way its rows do: {miscounted:?}"
    );

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
        println!("   {u} takes a difference and no law governs it");
    }

    // A set difference no law governs is a guard believed to be there and never once checked, and
    // it is silent in every other test.
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
        println!("   [{}] {}: {}", d.contract, d.problem, d.subject);
    }
    assert!(drift.is_empty(), "a roster and its population disagree");

    // ------------------------------------------------------------------
    // What one examined row of each rule is, declared, against what its rows are.
    // `checks/all.sqlc` returns `(rule, filing, layer, violates, detail)`, and its header reads
    // *which layer of which filing it is*. That is not so wherever the examined item is finer
    // than a layer, a part, a slack or a claim, so `(filing, layer)` is not a key and survives
    // only inside the prose `detail`.
    //
    // It also tells apart the two reasons `checks/all.sqlc` is a bag, as `invariance.sqlc` sets
    // them out: several items per layer saying the same sentence, and an examined item finer than
    // a layer, where every row says something different.
    //
    // One direction only. A rule declaring `layer` owes exactly one row per `(filing, layer)`; a
    // second means it silently changed what it examines, and the count moves with nothing saying
    // what it counts. The converse cannot be asserted: a rule that examines parts may see one
    // part per layer in a corpus that files one, and accusing it would read luck as a claim.
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
                 if rows == layers { "   one row per layer" } else { "   finer than a layer" });
    }
    // The second arm, which the first cannot replace. `finer_than_declared` asks whether the key
    // is unique per row; this asks whether the key resolves. A rule putting a claim address in
    // the `layer` column, such as `pm:nameplate/pm:amount claim 7`, gives a value unique per row,
    // which satisfies one row per key by construction, so what makes the column wrong is exactly
    // what makes the first arm pass. And anything joining a verdict to a layer keeps only the
    // pairs that resolve and drops the rest, with the join looking perfect either way.
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
    println!("   The coverage number has a unit. `examined 20` is twenty parts for one rule");
    println!("      and twenty layers for another, so one threshold cannot read across both.");

    // ------------------------------------------------------------------
    // Which guards have a second witness, and which are the roster read twice.
    // `diagrams/domain_objects.sqlc` states the rule for one side, and the tree is asserted to keep
    // it: a contract must not be derived from what it governs, so every roster here is a bare
    // VALUES literal. Nothing in the SQL states the converse, and some of the populations
    // `folds/contract_subjects.sqlc` counts take their subject's name from the very roster they
    // are compared against. The table below says which.
    //
    // It is a trade, not a defect, which is why it has to be declared. The roster join is what
    // gives the vacuous verdict: a rule with nothing to examine still emits a row, so the verdict
    // that matters most is a row a reader can see rather than a silence. The price is that the
    // subject is then on both sides of the difference by construction, and
    // `rank/guard_reach.sqlc` counts what the corpus makes of that. This says which contracts pay
    // it, a fact about the templates that no query can reach.
    //
    // The direction that bites is a contract leaving the independent column. `diagrams` reads its
    // population out of `information_schema`, and `diagram laws` names each law in its own arm; a
    // refactor that routed either through its roster "so the names line up" would take a real
    // second witness away, and every other check here would still pass.
    // ------------------------------------------------------------------
    let edges: BTreeMap<&str, Vec<String>> = files
        .iter()
        .map(|(n, b)| (n.as_str(), references(&emitted(b))))
        .collect();

    // The pair comes from each contract's own fold. `folds/contract_subjects.sqlc` names one fold
    // per contract, and each fold composes exactly two relations, its roster and its population,
    // as the two sides of one outer join. Read off the report instead, this law would get every
    // contract's relations at once, with no way to say which belong together.
    //
    // It detects a property by parsing, which is the cost to know about. `checks/all.sqlc`
    // composing `checks/roster.sqlc` is what makes the property true; this law sees it only where
    // it happens to be written. A detector keyed on where a fact is written fails on a refactor
    // that keeps the fact true.
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
    let folds = arms("folds/contract_subjects.sqlc");
    let mut pairs: BTreeMap<&str, BTreeSet<&str>> = BTreeMap::new();
    for (label, fold) in &folds {
        let e = pairs.entry(label.as_str()).or_default();
        for rel in edges.get(fold.as_str()).into_iter().flatten() {
            e.insert(rel.as_str());
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
            if borrows { "the roster twice" } else { "a second witness" }
        );
    }
    for (contract, why) in BORROWS_ITS_SUBJECT {
        println!("   · {contract:<11} {why}");
    }

    assert!(
        unreadable.is_empty(),
        "a contract's fold in folds/contract_subjects.sqlc does not compose exactly two \
         relations, so this law cannot tell its roster from its population and has lost its \
         subject: {unreadable:?}"
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
    // A law every subject passes the same way is decoration, and this one would be if the tree
    // ever held only one shape. Both columns have to stay populated for it to mean anything.
    assert!(
        !borrowed.is_empty() && !independent.is_empty(),
        "every contract is built the same way, so this law cannot discriminate and the column \
         it prints says nothing"
    );

    // ------------------------------------------------------------------
    // Whether a rule still reports that it examined nothing, measured on a corpus emptied for the
    // purpose. The vacuous verdict is the one this repository calls the most important it can
    // return, and the roster join is the only thing producing it. With rows on hand every arm
    // emits `1 + examined` whether the join carries the roster or not, so the corpus that can see
    // a broken join is the corpus with nothing in it.
    //
    // Emptying the corpus answers a guard whose reach depends on the corpus.
    // `reports/integrity.sqlc`'s first problem reports a broken roster join only for the rules
    // nothing populates, and loses even those when a filing sizes a buffer. Here it is every
    // subject on both rosters, and it gets stronger as they grow.
    //
    // Nothing is committed. The truncate runs inside a transaction that is rolled back, as
    // `examples/generation/main.rs` and `assets/sqlc/invariance.sqlc` do, so the database this
    // reads is the database it leaves. It is the only write this example makes, and the reason it
    // needs a database it is allowed to touch.
    //
    // The table list is read from the catalogue rather than written here, for the reason
    // diagrams/catalogue.sqlc gives: a list of tables restated in a second place stops matching
    // the schema and cannot say so.
    // ------------------------------------------------------------------
    let mut tx = pool.begin().await?;
    let tables: String = sqlx::query_scalar(
        "SELECT string_agg(format('pm.%I', tablename), ', ') FROM pg_tables WHERE schemaname = 'pm'",
    )
    .fetch_one(&mut *tx)
    .await?;
    // `AssertSqlSafe` is the audit sqlx asks for, and `format('pm.%I')` answers it here: Postgres
    // quotes the identifier itself, the names come from `pg_tables` rather than from anything a
    // document said, and the statement runs in a transaction that is rolled back.
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
        println!("   {contract:<11} {silent:>3} of {declared:>3} emit the one row saying they examined nothing");
    }
    let mute: Vec<&str> = vacuity
        .iter()
        .filter(|v| v.rows != 1)
        .map(|v| v.subject.as_str())
        .collect();
    // The row has to carry no verdict. One row saying `false` over a corpus with nothing in it is
    // a check answering about rows it does not have, which the row count alone reads as healthy.
    // Two different defects, so two assertions.
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
         being silent, and a rule that examined nothing looks like a rule that does not exist: \
         {mute:?}"
    );
    assert!(
        answered.is_empty(),
        "with nothing to examine a check returned a verdict anyway, so it is answering about rows \
         it does not have and the coverage table will count them as examined: {answered:?}"
    );
    println!("   The roster row exists before the population does, which is what makes");
    println!("      \"a bound with nothing to bound passes loudest\" a verdict here instead of a worry.");

    // ------------------------------------------------------------------
    // The written-out graph can go stale, which is what generating and then loading costs.
    // `examples/compositions/main.rs` writes `assets/dag/edges.sql` from the source tree and
    // `ingest` loads it, so a `:compose` added without rerunning that program leaves the database
    // describing an older tree. Nothing else here would notice: every relation over the graph
    // would be internally consistent and about the wrong repository.
    //
    // This is a staleness check and not two independent routes. It re-derives through the same
    // `examples/shared/tree` module the writer uses, so it catches the file drifting from the
    // tree and could never catch the scanner being wrong about both. Two routes would need a
    // second copy of the scanner.
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
        // Splices only. `inner_joins` is classified by `examples/compositions/main.rs` from the
        // SQL text, and re-deriving it here would be a second detector rather than a second
        // route: this law checks that the loaded file matches the tree's edges, and the join
        // column has its own positive control in the writer.

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
         ingest: every relation over the graph is otherwise describing an older tree, consistently"
    );
    println!("\n7. the compose graph, loaded against the source tree");
    println!("   {} pairs, {} directives, {} pairs spliced more than once",
             loaded.len(), loaded.values().sum::<usize>(),
             loaded.values().filter(|n| **n > 1).count());
    println!("   A parent splicing a child twice is ordinary here and `checks/jagged_layer` in");
    println!("      `pm.part`. Two graphs of one shape, opposite verdicts on one column, and the");
    println!("      comparison is a query rather than a sentence in a program's output.");

    // ------------------------------------------------------------------
    // 7b. The compose graph's measures, held against the same tree.
    //
    // Two routes that share no code. Above, the loaded edges are held against the scanned tree.
    // Here the counts the database derives from those edges, by a recursive CTE that ignores
    // direction and walks, are held against a union-find over the map this program has already
    // built. `rank/compose_measures.sqlc` is otherwise the only place in SQL where those numbers
    // exist, and a relation nobody recomputes is a number nobody checks.
    //
    // The counts ignore the direction of the edges, and they have to. The compose graph has no
    // loop when direction is kept, which is a different question and a different sense of the
    // word cycle; `composition/descent.sqlc`'s header sets out its senses.
    // ------------------------------------------------------------------
    let mut names: BTreeSet<&str> = BTreeSet::new();
    for (parent, child) in dag_now.keys() {
        names.insert(parent.as_str());
        names.insert(child.as_str());
    }
    let index: BTreeMap<&str, usize> = names.iter().enumerate().map(|(i, n)| (*n, i)).collect();
    let mut up: Vec<usize> = (0..names.len()).collect();
    fn root_of(up: &mut Vec<usize>, mut x: usize) -> usize {
        while up[x] != x {
            up[x] = up[up[x]];
            x = up[x];
        }
        x
    }
    for (parent, child) in dag_now.keys() {
        let a = root_of(&mut up, index[parent.as_str()]);
        let b = root_of(&mut up, index[child.as_str()]);
        if a != b {
            up[a] = b;
        }
    }
    let walked_c = (0..names.len()).map(|i| root_of(&mut up, i)).collect::<BTreeSet<_>>().len() as i64;
    let (walked_n, walked_m) = (names.len() as i64, dag_now.len() as i64);

    let measures = sqlx::query_file!("assets/sql/rank/compose_measures.sql").fetch_all(&pool).await?;
    let whole = measures
        .iter()
        .find(|m| m.scope.is_none())
        .ok_or("rank/compose_measures.sqlc has no whole-graph row to compare")?;
    assert_eq!(
        (whole.n_nodes, whole.m_edges, whole.c_components, whole.rank_of_incidence,
         whole.cycle_space_dim),
        (Some(walked_n), Some(walked_m), Some(walked_c), Some(walked_n - walked_c),
         Some(walked_m - walked_n + walked_c)),
        "rank/compose_measures.sqlc and a union-find over the source tree disagree about the \
         compose graph's counts. The recursive walk and the union-find share no code, so one \
         of them is wrong rather than both being stale"
    );

    // The directory cut puts each template in exactly one scope, and this is what says so. Every
    // template lives in one directory, so the scopes' node counts must sum to the whole graph's.
    // The filing cut in `rank/graph_measures.sqlc` can put a node in more than one scope, so its
    // sum is larger, and the two relations' sums must never be read as the same kind of number.
    let summed_nodes: i64 = measures.iter().filter(|m| m.scope.is_some())
        .map(|m| m.n_nodes.unwrap_or(0)).sum();
    assert_eq!(
        summed_nodes, walked_n,
        "the directory scopes hold {summed_nodes} nodes between them and the graph has \
         {walked_n}, so the cut is not a partition and its sums show nothing"
    );

    let cut = sqlx::query_file!("assets/sql/rank/compose_decomposition.sql").fetch_one(&pool).await?;
    let summed_cycles: i64 = measures.iter().filter(|m| m.scope.is_some())
        .map(|m| m.cycle_space_dim.unwrap_or(0)).sum();
    assert_eq!(
        cut.summed_per_directory, Some(summed_cycles),
        "rank/compose_decomposition.sqlc does not sum the rows of rank/compose_measures.sqlc"
    );

    // That there was something to examine, which is not a claim about the answer. Surviving the
    // cut is a legitimate outcome, so it is not asserted. What must hold is that there was
    // something to lose and more than one scope to lose it to.
    assert!(
        cut.corpus_wide.unwrap_or(0) > 0 && cut.directories.unwrap_or(0) > 1,
        "the compose graph has no loops, or only one directory, so the cut measures nothing"
    );

    println!("\n7b. the compose graph's counts, and what a directory cut costs them");
    println!("   union-find over the tree   n {walked_n}, m {walked_m}, c {walked_c}");
    println!("   rank/compose_measures      tree edges {}, loops {}",
             whole.rank_of_incidence.unwrap_or(-1), whole.cycle_space_dim.unwrap_or(-1));
    println!("   cut into {} directories    loops {} of {}, so {} loop(s) need two",
             cut.directories.unwrap_or(0), summed_cycles, cut.corpus_wide.unwrap_or(0),
             cut.loops_that_cross.unwrap_or(0));
    println!("   The layer graph survives its cut and the unit graph does not; this is the");
    println!("      third row of that table, and this cut puts each template in one directory.");

    // ------------------------------------------------------------------
    // 8. Every conversion in the tree reads the operand's sign the same way.
    // ------------------------------------------------------------------
    let declared: BTreeMap<&str, (Corner, &str)> =
        CONVERSIONS.iter().map(|(n, c, w)| (*n, (*c, *w))).collect();

    let mut converts: BTreeSet<&str> = BTreeSet::new();
    let mut undeclared: Vec<&str> = Vec::new();
    let mut not_cornered: Vec<&str> = Vec::new();
    for (name, body) in &files {
        let sql = sql_only(body);
        if !multiplies_by_a_factor(&sql) {
            continue;
        }
        converts.insert(name.as_str());
        match declared.get(name.as_str()) {
            None => undeclared.push(name),
            Some((Corner::Takes, _))
                if !(sql.contains("least(") && sql.contains("greatest(")) =>
            {
                not_cornered.push(name)
            }
            Some(_) => {}
        }
    }
    let stale: Vec<&str> = CONVERSIONS
        .iter()
        .map(|(n, _, _)| *n)
        .filter(|n| !converts.contains(n))
        .collect();

    println!("\n8. conversions in the tree: {} declared, {} found", CONVERSIONS.len(), converts.len());
    for (n, c, why) in CONVERSIONS {
        println!("   {:<44} {:<15} {why}", n, c.word());
    }
    for u in &undeclared {
        println!("   {u} multiplies by a factor and CONVERSIONS does not name it");
    }
    for u in &not_cornered {
        println!("   {u} is declared to take the corner and takes neither");
    }
    for u in &stale {
        println!("   {u} is declared here and no longer multiplies by a factor");
    }

    // What a count cannot see. Counting conversion sites cannot report that two of them read a
    // sign differently, because both spellings are one site each. This is an attribution check
    // for the same reason `diagrams/ungoverned.sqlc` is: what each site does is declared here, and
    // inferring it from the template's name would call the divergence a pass.
    assert!(
        !converts.is_empty(),
        "no template in the tree multiplies by a conversion factor, so this guard is vacuous and \
         `multiplies_by_a_factor` has stopped recognising the spelling rather than the tree having \
         stopped converting"
    );
    assert!(
        undeclared.is_empty() && not_cornered.is_empty() && stale.is_empty(),
        "the conversion operator is spelled more than one way in the tree, or the roster above no \
         longer describes it. One operator: `least(x * f_low, x * f_high)` at the low bound, its \
         `greatest` twin at the high, the mode a plain product"
    );

    println!("\nAll checks passed.");
    Ok(())
}
