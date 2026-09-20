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
        // ⛔ An unguarded site reads `not checked`. Never `ok`, never blank, a reader
        //    scanning this column has to be able to see the hole without counting.
        let guard = match s.guarded_by.as_str() {
            "" => "⛔ not checked".to_string(),
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
        "\n   ⛔ {} of {} sites compare no units. A guard on them would bind {} rows, not none.",
        unguarded.len(),
        sites.len(),
        bound_rows
    );

    // ⛔⛔ THIS ASSERTION IS ABOUT THE ARITHMETIC AND NOT ABOUT THE CORPUS. A `not comparable`
    //     row means the model put two numbers of different things together and produced a
    //     figure that looks perfectly well formed. There is no tolerance for that, and the
    //     count is pinned at zero the way matrices.rs pins its disagreements at zero.
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

    // ⭐ A suspension is a claim the filer made, so the count is reported and never pinned.
    //   The day somebody measures one of these it falls, and that is the model working.
    println!(
        "\n   ⭐ Not one of these is a defect. Each is a filer saying they did not measure \n\
           \x20     something, and the model taking them at their word."
    );

    // ------------------------------------------------------------------
    // 3. The roster and the relations agree.
    // ------------------------------------------------------------------
    let drift = sqlx::query_file!("assets/sql/queries/soundness/2-integrity.sql")
        .fetch_all(&pool)
        .await?;

    println!("\n3. roster integrity, every declared contract: {} disagreement(s)", drift.len());
    for d in &drift {
        println!("   ⛔ [{}] {}: {}", d.contract, d.problem, d.subject);
    }

    // ⛔⛔⛔ THE ASSERTION THIS EXAMPLE EXISTS FOR. With nothing holding a list of the places
    //     this model combines two magnitudes, a missing site is not a failure, it is a
    //     silence. A tenth site added without a roster row, or a roster row added without a
    //     relation, fails here.
    //
    // ⭐ It covers the conformance and algebra rosters too, because reports/integrity.sqlc
    //   checks every contract in one pass. A readiness report that passed while the rule
    //   roster was broken would be reporting on a checker it has no reason to trust.
    //
    // ⭐ AND IT READS THE SOUNDNESS EXAMPLE'S QUERY FILE ON PURPOSE. Both examples want the same
    //   projection of reports/integrity.sqlc, and two files holding one identical alias list is
    //   the duplication this tree exists to avoid. The argument differs per example; the
    //   relation does not, so the relation is written once.
    assert!(
        drift.is_empty(),
        "a roster and the population it declares disagree"
    );

    println!("\nAll checks passed.");
    Ok(())
}
