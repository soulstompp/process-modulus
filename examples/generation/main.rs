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

use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

// The bench is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which is
// exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/simulation/mod.rs"]
mod simulation;

use simulation::filing::emit;
use simulation::pipeline::build_script;
use simulation::instrument::{DeclaredAskSize, Instrument};
use simulation::window::{
    Run, overtime_settings, queued_settings, run, short_settings, slack_settings,
    starved_settings,
};

const DECLARED: DeclaredAskSize = DeclaredAskSize {
    low: 1.0,
    high: 6.0,
};

const AS_OF: &str = "2026-09-06";

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example puts generated filings through the same ingest and \
         the same rules as the corpus, and it cannot do that without a database."
    })?;

    let out = PathBuf::from("target/simulation");
    fs::create_dir_all(&out)?;

    // ------------------------------------------------------------------------------------
    // 1. Generate, and write each filing out.
    // ------------------------------------------------------------------------------------
    let window = Duration::from_secs(6 * 60 * 60);
    let mut written: Vec<(String, PathBuf)> = Vec::new();

    println!("1. generated filings\n");
    for (name, settings) in [
        ("slack", slack_settings()),
        ("turned-away", short_settings()),
        ("kept-waiting", queued_settings()),
        ("overtime", overtime_settings()),
        ("starved", starved_settings()),
    ] {
        let outcome: Run = run(settings, 1, window)?;
        for instrument in [Instrument::Whole, Instrument::StockAndFlow] {
            let declared = match instrument {
                Instrument::Whole => None,
                Instrument::StockAndFlow => Some(DECLARED),
            };
            let reading = instrument.read(&outcome, declared);
            let e = emit(&outcome, &reading, instrument, name, AS_OF);

            let short = match instrument {
                Instrument::Whole => "whole",
                Instrument::StockAndFlow => "stock-and-flow",
            };
            let stem = format!("{name}-{short}");
            let path = out.join(format!("{stem}.xml"));
            fs::write(&path, &e.xml)?;
            println!("   {stem:<28} {} bytes", e.xml.len());
            written.push((stem, path));
        }
    }

    // ------------------------------------------------------------------------------------
    // 2. The first gate: the XSD, through the validator the README tells adopters to use.
    // ------------------------------------------------------------------------------------
    println!("\n2. xmllint against schema/process-modulus.xsd\n");
    let mut invalid = 0usize;
    for (stem, path) in &written {
        let out = Command::new("xmllint")
            .args(["--noout", "--schema", "schema/process-modulus.xsd"])
            .arg(path)
            .output()?;
        if out.status.success() {
            println!("   {stem:<28} valid");
        } else {
            invalid += 1;
            println!("   {stem:<28} ⛔ INVALID");
            for line in String::from_utf8_lossy(&out.stderr).lines().take(6) {
                println!("      {line}");
            }
        }
    }

    if invalid > 0 {
        println!("\n{invalid} generated filings do not validate. The rules are not run on a \
                  document the schema rejects.");
        std::process::exit(1);
    }

    // ------------------------------------------------------------------------------------
    // 3. The second gate: the conformance rules, through the ingest the corpus uses.
    // ------------------------------------------------------------------------------------
    println!("\n3. assets/sql/checks/, over the same ingest as the corpus\n");
    let script = build_script(&written)?;
    let script_path = PathBuf::from("target/simulation/ingest-and-check.sql");
    fs::write(&script_path, &script)?;

    let psql = Command::new("psql")
        // examples/shared/database/mod.rs says why: a plan this deep costs more to compile
        // than to run.
        .env("PGOPTIONS", "-c jit=off")
        .arg(&url)
        .args(["-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-f"])
        .arg(&script_path)
        .output()?;

    if !psql.status.success() {
        eprintln!("{}", String::from_utf8_lossy(&psql.stderr));
        return Err("psql failed. The script is at target/simulation/ingest-and-check.sql".into());
    }

    let stdout = String::from_utf8_lossy(&psql.stdout);
    let mut violations: Vec<String> = Vec::new();
    let mut unreached: Vec<String> = Vec::new();
    let mut census: Vec<(String, i64, i64, i64)> = Vec::new();
    for line in stdout.lines() {
        let f: Vec<&str> = line.split('|').collect();
        match f.first() {
            Some(&"COUNT") if f.len() >= 5 => census.push((
                f[1].to_string(),
                f[2].parse().unwrap_or(0),
                f[3].parse().unwrap_or(0),
                f[4].parse().unwrap_or(0),
            )),
            Some(&"VIOLATION") if f.len() >= 5 => {
                violations.push(format!("{}  {}  {}  {}", f[1], f[2], f[3], f[4]))
            }
            Some(&"UNREACHED") if f.len() >= 2 => unreached.push(f[1].to_string()),
            _ => {}
        }
    }

    println!(
        "   {:<28} {:>6} {:>6} {:>10}",
        "filing", "rules", "rows", "violated"
    );
    let generated: Vec<&(String, i64, i64, i64)> = census.iter().collect();
    for (name, rules, violated, rows) in &generated {
        println!("   {name:<28} {rules:>6} {rows:>6} {violated:>10}");
    }

    if !violations.is_empty() {
        println!("\n   the violations:");
        for v in &violations {
            println!("     ⛔ {v}");
        }
    }

    // ------------------------------------------------------------------------------------
    // 4. What has to hold.
    // ------------------------------------------------------------------------------------
    println!();
    let mut failed = 0usize;

    let total_violations: i64 = generated.iter().map(|(_, _, v, _)| v).sum();
    let ok = total_violations == 0;
    println!(
        "   every generated filing passes every rule        {}",
        yes_no(ok)
    );
    if !ok {
        failed += 1;
    }

    // ⛔ THE NEGATIVE CONTROL, AND WITHOUT IT THE LINE ABOVE PROVES NOTHING. A filing so empty
    //   that no rule had a population to look at would report zero violations and zero work.
    let all_examined = generated.iter().all(|(_, rules, ..)| *rules > 0);
    println!(
        "   and every one of them gave the rules work to do  {}",
        yes_no(all_examined)
    );
    if !all_examined {
        failed += 1;
    }

    // ⭐⭐⭐ THE LINE THIS EXAMPLE EXISTS FOR. The blind filing reports strictly less and must be
    //    accused of nothing for it. A rule that fires here is firing because a filer lacked an
    //    instrument, which is not a contradiction in their document.
    let blind: i64 = generated
        .iter()
        .filter(|(name, ..)| name.ends_with("stock-and-flow"))
        .map(|(_, _, v, _)| v)
        .sum();
    println!(
        "   an honest report of less is accused of nothing   {}",
        yes_no(blind == 0)
    );
    if blind != 0 {
        failed += 1;
    }

    // ⭐⭐ WHAT THE BENCH DOES NOT REACH, WHICH IS THE HONEST OTHER HALF OF A CLEAN RUN.
    if !unreached.is_empty() {
        println!("\n   {} rules some real document exercises and no generated one does:", unreached.len());
        for rule in &unreached {
            println!("     · {rule}");
        }
    }

    println!();
    if failed == 0 {
        println!("A NeXosim run files, validates, and contradicts nothing. Twice over.");
        Ok(())
    } else {
        std::process::exit(1);
    }
}

fn yes_no(b: bool) -> &'static str {
    if b { "yes" } else { "⛔ no" }
}
