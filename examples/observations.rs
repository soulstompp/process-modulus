//! What the corpus actually says, and whether anything is looking.
//!
//! [`examples/matrices.rs`] proves the arithmetic agrees with itself. [`examples/readiness.rs`]
//! asks whether it may be performed. This one asks the corpus questions and prints the answers
//!, because a relation whose product is knowledge rather than a verdict had nowhere to land,
//! and so either never got written or got written and read by nobody.
//!
//! ⭐⭐⭐ EVERY NUMBER A COMMENT IN THIS REPOSITORY QUOTES SHOULD BE PRINTED BY A PROGRAM. Four
//! were not, and all four had drifted: the capacity-slack coverage in two places, the template
//! count, and the refusal count in `epistemics/standing.sqlc`'s own header. None of the authors
//! was wrong when they wrote it. The corpus moved and the sentences did not.
//!
//! ⛔⛔ THE TEETH ARE ON THE UNASKED QUESTION, NEVER ON THE ANSWER. Two assertions:
//! that no relation and no document is reached by nothing, and that every remainder has had
//! the closure question put to it. Neither judges a filing. `unbounded` is the honest state
//! for a document written to argue about three layers, and a spillover is a REFERRAL, a
//! filing is not the system, and a second document's observation is a projection onto this one
//! rather than an accusation against it.
//!
//! Run it with a loaded database:
//!
//! ```text
//! psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!   cargo run --example observations
//! ```

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

/// Documents that are parsed only by Rust tests and never reach the database, each with the
/// reason. ⛔ Adding a name here is the whole decision: it removes a document from every SQL
/// query, every check and every report at once, and the only thing that says so is this list.
const RUST_ONLY: &[(&str, &str)] = &[
    ("coverage-us-gaap", "a coverage assertion; tests/coverage_parse.rs"),
    ("coverage-pt-ncrf-pe", "a coverage assertion; tests/coverage_parse.rs"),
    ("run-2026-08-30", "a run record; tests/coverage_parse.rs"),
    ("dependence-group-consolidation", "a dependence assertion; tests/dependence_parse.rs"),
    ("every-claimed", "a draft-state fixture; tests/fixtures.rs"),
    ("every-draft", "a draft-state fixture; tests/fixtures.rs"),
];

/// Every `.sqlc` under `assets/sqlc`, named the way a `:compose()` directive names it.
fn templates(dir: &Path, root: &Path, out: &mut Vec<(String, String)>) {
    for e in fs::read_dir(dir).expect("assets/sqlc is readable").flatten() {
        let p = e.path();
        if p.is_dir() {
            templates(&p, root, out);
        } else if p.extension().is_some_and(|x| x == "sqlc") {
            let name = p
                .strip_prefix(root)
                .expect("under assets/sqlc")
                .to_string_lossy()
                .into_owned();
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example reports what the corpus says, and it cannot do \
         that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. Nothing unobserved: every relation, and every document.
    // ------------------------------------------------------------------
    let sqlc = Path::new("assets/sqlc");
    let mut files = Vec::new();
    templates(sqlc, sqlc, &mut files);

    let composed: BTreeSet<String> = files.iter().flat_map(|(_, b)| references(b)).collect();

    // A root is reached by no other template. It earns its place by being run: as a psql entry
    // point, or by an example naming its composed output.
    let examples: String = fs::read_dir("examples")
        .expect("examples/ is readable")
        .flatten()
        .map(|e| fs::read_to_string(e.path()).unwrap_or_default())
        .collect();
    let entry_points = ["ingest.sqlc", "rules.sqlc", "matrices.sqlc", "invariance.sqlc"];

    let mut unobserved: Vec<&str> = Vec::new();
    for (name, _) in &files {
        if composed.contains(name) || entry_points.contains(&name.as_str()) {
            continue;
        }
        let emitted = format!("assets/sql/{}", name.replace(".sqlc", ".sql"));
        if !examples.contains(&emitted) {
            unobserved.push(name);
        }
    }
    unobserved.sort_unstable();

    // ⛔ A template carrying an open `@slot` emits no .sql and is a shape rather than a query,
    //   so it is reached through its fillers and never directly. That is handled above by the
    //   `composed` set: a shape is always composed by whoever fills it.
    println!(
        "1. relations: {} templates, {} reached by something",
        files.len(),
        files.len() - unobserved.len()
    );
    for u in &unobserved {
        println!("   ⛔ {u} is read by nothing");
    }

    let on_disk: Vec<PathBuf> = ["assets/corpus", "assets/fixtures"]
        .iter()
        .flat_map(|d| fs::read_dir(d).expect("readable").flatten().map(|e| e.path()))
        .filter(|p| p.extension().is_some_and(|x| x == "xml"))
        .collect();
    let ingest = fs::read_to_string("assets/sqlc/ingest.sqlc").expect("readable");

    let mut unreached: Vec<String> = Vec::new();
    let mut rust_only = 0usize;
    for p in &on_disk {
        let stem = p.file_stem().expect("named").to_string_lossy().into_owned();
        if ingest.contains(&format!("'{stem}'")) {
            continue;
        }
        match RUST_ONLY.iter().find(|(n, _)| *n == stem) {
            Some(_) => rust_only += 1,
            None => unreached.push(stem),
        }
    }
    unreached.sort();

    println!(
        "\n   documents: {} on disk, {} ingested, {} parsed only by Rust",
        on_disk.len(),
        on_disk.len() - rust_only - unreached.len(),
        rust_only
    );
    for (name, why) in RUST_ONLY {
        println!("      · {name:<32} {why}");
    }
    for u in &unreached {
        println!("   ⛔ {u}.xml is reached by nothing at all");
    }

    // ⛔⛔⛔ THE ASSERTION THIS EXAMPLE EXISTS FOR. A relation nobody reads and a document
    //     nobody parses are both invisible, and invisible reads from the outside exactly like
    //     absent. `layers/drawn.sqlc` was absent for months and nothing said so.
    assert!(
        unobserved.is_empty() && unreached.is_empty(),
        "something in the tree is reached by nothing"
    );

    // ------------------------------------------------------------------
    // 2. The census: what the corpus says when somebody asks.
    // ------------------------------------------------------------------
    let docs = sqlx::query_file!("assets/sql/queries/observations/1-documents.sql")
        .fetch_all(&pool)
        .await?;
    let no_witness = docs.iter().filter(|d| d.witness.is_empty()).count();
    println!(
        "\n2. documents in the database: {}, of which {} name no witness",
        docs.len(),
        no_witness
    );
    println!("   ⛔ every one of those {no_witness} is a pm:processModulus. It is the only root");
    println!("      that carries no document-level provenance, so a stipulation and an");
    println!("      observation are the same shape to anything reading the tree.");
    // ⭐ The standard a composition works under, a different question from the regime: the
    //   regime is what the MEMBERS reported under, the citation is what governs combining them.
    let cited: Vec<_> = docs.iter().filter(|d| !d.under.is_empty()).collect();
    println!("   ⭐ {} document(s) name the instrument they compose under:", cited.len());
    for d in &cited {
        println!("      {:<32} {}", d.filing, d.under);
    }

    let standing = sqlx::query_file!("assets/sql/queries/observations/2-what-nobody-claims.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n3. where claims say they came from");
    for s in &standing {
        println!("   {:<22} {:>4}", s.says, s.claims);
    }

    let denoms = sqlx::query_file!("assets/sql/queries/observations/3-denominators.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n4. denominators the corpus leans on: {}", denoms.len());
    for d in &denoms {
        println!("   {:<8} {:<14} {:>4}  {}", d.kind, d.denominator, d.claims, d.filed_on);
    }
    println!("   ⭐ `week` and `semana` are two rows because two filers wrote two tokens.");

    let patience = sqlx::query_file!("assets/sql/queries/observations/4-patience.sql")
        .fetch_all(&pool)
        .await?;
    let filed = patience.iter().filter(|p| p.state == "filed").count();
    println!(
        "\n5. patience: {} of {} layers state how long demand survives unanswered",
        filed,
        patience.len()
    );
    for p in patience.iter().filter(|p| p.state == "filed") {
        println!(
            "   {} / {}: {} {}   (the demand is in {})",
            p.filing,
            p.layer,
            p.mode.unwrap_or_default(),
            p.unit,
            p.demand_unit
        );
    }

    let slacks = sqlx::query_file!("assets/sql/queries/observations/5-slack-coverage.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n6. buffer coverage");
    println!("   {:<10} {:<12} {:>6} {:>8} {:>8}", "buffer", "evidence", "sized", "at zero", "absent");
    for s in &slacks {
        println!(
            "   {:<10} {:<12} {:>6} {:>8} {:>8}",
            s.buffer,
            s.evidence.clone().unwrap_or_default(),
            s.sized,
            s.sized_at_zero,
            s.absent
        );
    }
    // ⭐ Printed, never pinned. The day somebody sizes a capacity slack above zero this line
    //   changes and nothing fails, which is the difference between an observation and a rule.
    println!("   ⭐ A sized zero is the TIGHTEST bound, not a missing one.");

    let fixtures = sqlx::query_file!("assets/sql/queries/observations/6-absences-in-the-fixtures.sql")
        .fetch_all(&pool)
        .await?;
    let total: i64 = fixtures.iter().map(|f| f.times).sum();
    println!(
        "\n7. the fixtures decline {} questions across {} kinds, on purpose, which is what a",
        total,
        fixtures.len()
    );
    println!("   stipulation is for. ⛔ Not counted as evidence anywhere; rules.sql composes the");
    println!("   corpus census and correctly not this one.");

    // ------------------------------------------------------------------
    // 3. Every remainder has had the closure question put to it.
    // ------------------------------------------------------------------
    let standings = sqlx::query_file!("assets/sql/queries/observations/7-remainder-standing.sql")
        .fetch_all(&pool)
        .await?;
    let asked: i64 = standings.iter().map(|s| s.remainders).sum();
    let computable: i64 =
        sqlx::query_file!("assets/sql/queries/observations/7b-remainders-computable.sql")
            .fetch_one(&pool)
            .await?
            .computable;

    println!(
        "\n8. remainders: {asked} of {computable} computable asked about the set they sit in"
    );
    for s in &standings {
        println!("   {:<32} {:>3}   {}", s.standing, s.remainders, s.filings);
    }

    // ⛔⛔ THE SECOND ASSERTION, AND IT IS ABOUT COVERAGE RATHER THAN ABOUT ANSWERS. Every
    //    remainder the arithmetic can reach must appear in layers/remainder_scope.sqlc with
    //    some standing. `nobody bounded the set` is a perfectly honest standing and fails
    //    nothing; a remainder that never had the question put to it is the failure.
    assert_eq!(
        asked, computable,
        "a remainder reaches the arithmetic without appearing in layers/remainder_scope.sqlc"
    );

    let spills = sqlx::query_file!("assets/sql/queries/observations/8-spillovers.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n9. referrals, a person settles these, not a checker: {}", spills.len());
    for s in &spills {
        println!(
            "   {} holds {} ~ {}, which {} observed  (its own search: {})",
            s.borne_by, s.from_layer, s.to_layer, s.observed_in, s.their_search
        );
    }
    println!("   ⛔ Not violations. A filing is not the system, and one document's observation");
    println!("      is a projection onto another rather than an accusation against it.");

    // ⭐ The union of the two search relations, which neither half can answer: how often does
    //   anybody look at all? That is a fact about the practice rather than about either
    //   mechanism, and it is the only thing that reads epistemics/searches.sqlc whole.
    let diligence = sqlx::query_file!("assets/sql/queries/observations/9-diligence.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n10. did anybody look?");
    let mut seen = "";
    for d in &diligence {
        if d.looked_for != seen {
            println!("   {}", d.looked_for);
            seen = &d.looked_for;
        }
        println!("      {:<20} {:>3}", d.answer, d.times);
    }

    // ⭐⭐⭐ THE EVIDENCE FOR AN ELIMINATION, WHICH THIS DATABASE COULD NOT STORE UNTIL
    //    2026-09-06. `asrt:Elimination/between` is repeating and no rule read it, so it had no
    //    column, no table and no ingest, and eight of them were parsed out of the corpus and
    //    thrown away on every load. Nothing on the query side could find that: a rule reads what
    //    it needs, so a field nothing reads is under no pressure to exist. The question that
    //    finds it is "could I write this document back out from what I stored".
    let evidence =
        sqlx::query_file!("assets/sql/queries/observations/10-elimination-evidence.sql")
            .fetch_all(&pool)
            .await?;
    let named = evidence.iter().filter(|e| e.named > 0).count();
    println!(
        "\n11. eliminations, and what each says it is between: {} of {} name their evidence",
        named,
        evidence.len()
    );
    for e in &evidence {
        println!(
            "   {:<26} {:<15} {:<10} {:>12}   {}",
            e.composition, e.composed_layer, e.quantity, e.size, e.between
        );
    }
    println!("   ⛔ `(none named)` is not a defect. `between` is minOccurs=0, and a composer");
    println!("      eliminating against a member that files nothing has nothing to name.");

    // ⭐ The greatest element of the intersection of the parts' divisor sets, where the parts
    //   share a unit. Where they do not, divisibility is a relation on one ordered set and there
    //   is nothing to intersect, so the row reports `notApplicable` rather than a number the fold
    //   would happily have produced.
    let quanta = sqlx::query_file!("assets/sql/queries/observations/11-composed-quantum.sql")
        .fetch_all(&pool)
        .await?;
    let unanswerable = quanta.iter().filter(|q| q.unit == "(incommensurable)").count();
    println!(
        "\n12. does a fused supply still arrive in whole units? {} of {} have no common quantum",
        unanswerable,
        quanta.len()
    );
    for q in &quanta {
        println!(
            "   {:<26} {:<22} {} part(s)  {:<20} {}",
            q.composition, q.composed_layer, q.parts, q.unit, q.quantum
        );
    }
    println!("   ⛔ `(notApplicable)` is the question being malformed, not unanswered: two quanta");
    println!("      in different units have no common divisor to find.");

    println!("\nAll checks passed.");
    Ok(())
}
