//! Running a generated filing through the corpus's own ingest and rules.
//!
//! Every line of the extraction is the same, byte for byte, as `assets/sql/ingest.sql`, so a
//! generated filing goes through the very reader the corpus goes through. A filing that passed
//! only through a friendlier reader would corroborate nothing. The edits are two lines per
//! generated filing added to the list of documents, and the final `COMMIT` replaced by a
//! `ROLLBACK`, so a loaded corpus survives the run untouched.

use std::fmt::Write as _;
use std::fs;
use std::path::PathBuf;

/// The corpus's own ingest with the generated filings spliced into its source list, the rules run
/// inside the same transaction, and a `ROLLBACK` at the end.
///
pub fn build_script(written: &[(String, PathBuf)]) -> Result<String, Box<dyn std::error::Error>> {
    let ingest = fs::read_to_string("assets/sql/ingest.sql")?;
    let checks = fs::read_to_string("assets/sql/checks/all.sql")?;

    let mut s = String::new();
    let mut spliced = false;
    for line in ingest.lines() {
        // The transaction stays open, so the rules see the generated rows and the rollback takes
        // them away again.
        if line.trim() == "COMMIT;" {
            continue;
        }
        s.push_str(line);
        s.push('\n');
        if !spliced && line.contains("CASCADE;") {
            spliced = true;
            s.push('\n');
            for (stem, path) in written {
                let p = fs::canonicalize(path)?;
                writeln!(s, "\\set d `cat {}`", p.display())?;
                writeln!(
                    s,
                    "INSERT INTO source VALUES ('{stem}', XMLPARSE(DOCUMENT :'d'));"
                )?;
            }
            s.push('\n');
        }
    }
    if !spliced {
        return Err("assets/sql/ingest.sql no longer has the TRUNCATE this splices after".into());
    }

    let names: Vec<String> = written
        .iter()
        .map(|(stem, _)| format!("'{stem}'"))
        .collect();
    let generated = names.join(", ");

    writeln!(s, "\nWITH v AS (\n{checks}\n)")?;
    writeln!(
        s,
        "SELECT 'VIOLATION', filing, rule, layer, coalesce(detail, '') FROM v WHERE violates;"
    )?;

    // Distinct rules, not rows. A filing with forty layers appears in one rule forty times, which
    // says nothing about how much of the rule set it exercised.
    writeln!(s, "WITH v AS (\n{checks}\n)")?;
    writeln!(
        s,
        "SELECT 'COUNT', filing, count(DISTINCT rule)::text, \
         count(*) FILTER (WHERE violates)::text, count(*)::text \
         FROM v WHERE filing IN ({generated}) GROUP BY filing;"
    )?;

    // What the bench cannot do. A generated filing passing every rule is worth little without
    // knowing which rules it never reached. These are the rules some real document exercises and
    // no generated one does: what the bench would have to grow to be a corpus.
    //
    // An anti-join and not an `EXCEPT`: a set difference fails to a plausible table rather than
    // to an error, as `examples/soundness/main.rs` explains.
    writeln!(s, "WITH v AS (\n{checks}\n)")?;
    writeln!(
        s,
        "SELECT 'UNREACHED', r.rule, '', '', '' \
         FROM (SELECT DISTINCT rule FROM v WHERE filing IS NOT NULL) r \
         WHERE NOT EXISTS (SELECT 1 FROM v g \
                           WHERE g.rule = r.rule AND g.filing IN ({generated})) \
         ORDER BY r.rule;"
    )?;
    writeln!(s, "\nROLLBACK;")?;
    Ok(s)
}
