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
#![doc = include_str!("../../pt-PT/examples/readiness/README.md")]

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example reports which computations are available, and \
         it cannot do that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = database::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. The roster, and what guards each site.
    // ------------------------------------------------------------------
    let sites = sqlx::query_file!("assets/sql/queries/readiness/1-sites.sql")
        .fetch_all(&pool)
        .await?;

    println!("1. arithmetic sites: {} on the roster\n", sites.len());
    println!(
        "   {:<30} {:>6} {:>10} {:>7}  {}",
        "site", "ready", "suspended", "cross", "commensurability"
    );
    for s in &sites {
        // An unguarded site reads `not checked`, never `ok` and never blank, so a reader
        // scanning the column sees the gap without counting.
        let guard = match s.guarded_by.as_str() {
            "" => "not checked".to_string(),
            "(forbidden)" => "must not be checked".to_string(),
            rule => format!("✅ {rule}"),
        };
        println!(
            "   {:<30} {:>6} {:>10} {:>7}  {}",
            s.site, s.computable, s.suspended, s.not_comparable, guard
        );
    }

    let unguarded: Vec<&str> = sites
        .iter()
        .filter(|s| s.guarded_by.is_empty())
        .map(|s| s.site.as_str())
        .collect();
    let bound_rows: i64 = sites
        .iter()
        .filter(|s| s.guarded_by.is_empty())
        .map(|s| s.computable)
        .sum();
    println!(
        "\n   {} of {} sites compare no units. A guard on them would bind {} rows, not none.",
        unguarded.len(),
        sites.len(),
        bound_rows
    );

    // This assertion is about the arithmetic, not the corpus. A `not comparable` row means the
    // model put two numbers of different things together and produced a figure that looks well
    // formed. Nothing of that is tolerated, so the count is held at zero.
    let incomparable: i64 = sites.iter().map(|s| s.not_comparable).sum();
    assert_eq!(
        incomparable, 0,
        "a site combined two magnitudes in different units"
    );

    // ------------------------------------------------------------------
    // 2. What the corpus declines to compute, and what stopped it.
    // ------------------------------------------------------------------
    let suspended = sqlx::query_file!("assets/sql/queries/readiness/2-suspensions.sql")
        .fetch_all(&pool)
        .await?;

    println!("\n2. suspended: {} instances\n", suspended.len());
    let mut last = "";
    for s in &suspended {
        if s.site != last {
            println!("   {}", s.site);
            last = &s.site;
        }
        println!("      {:<28} {:<22} {}", s.filing, s.layer, s.detail);
    }

    // A suspension is a claim the filer made, so the count is printed and never asserted. When
    // somebody measures one of these, it falls, and that is the model working.
    println!(
        "\n   Not one of these is a defect. Each is a filer saying they did not measure \n\
           \x20  something, and the model taking them at their word."
    );

    // ------------------------------------------------------------------
    // 3. The roster and the relations agree.
    // ------------------------------------------------------------------
    let drift = sqlx::query_file!("assets/sql/queries/soundness/2-integrity.sql")
        .fetch_all(&pool)
        .await?;

    println!("\n3. roster integrity, every declared contract: {} disagreement(s)", drift.len());
    for d in &drift {
        println!("   [{}] {}: {}", d.contract, d.problem, d.subject);
    }

    // The assertion this example exists for. Without a list of the places this model combines
    // two magnitudes, a missing site is not a failure but a silence. A new site added without a
    // roster row, or a roster row added without a relation, fails here.
    //
    // It covers the rule roster and the algebra roster too, because reports/integrity.sqlc checks
    // every contract in one pass. A readiness report that passed while the rule roster was broken
    // would be reporting on a checker it has no reason to trust.
    //
    // It reads the soundness example's query file on purpose. Both examples want the same
    // projection of reports/integrity.sqlc, so the relation is written once and each example
    // makes its own case with it.
    assert!(
        drift.is_empty(),
        "a roster and the population it declares disagree"
    );

    println!("\nAll checks passed.");
    Ok(())
}
