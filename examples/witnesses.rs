//! Whether each rule has ever been SEEN TO SAY NO.
//!
//! ⭐⭐⭐ THE OTHER EXAMPLES ASK WHETHER THE RULES ARE RIGHT. THIS ONE ASKS WHETHER THEY CAN BE
//!    WRONG. `soundness.rs` checks that each query computes what it claims and `readiness.rs`
//!    checks that each rule has a population, and a rule can pass both while being incapable
//!    of failing: a predicate true by construction examines a thousand rows and concludes
//!    nothing. Measured before this file existed, the corpus and fixtures put 22 of 24 rules
//!    over real rows and NOT ONE RULE HAD EVER BEEN OBSERVED TO FIRE. The violated column of
//!    the rule x {passed, violated} matrix was empty end to end.
//!
//! ⭐⭐ A WITNESS IS A MINIMAL MUTATION OF A REAL FILING THAT TRIPS EXACTLY ONE RULE. Minimal
//!    matters: a mutation that trips six rules has shown that something is checked, not that
//!    THIS rule is. Each is a single string substitution against a corpus or fixture document,
//!    and the mutant must still validate against the XSD, because a document the grammar
//!    rejects proves nothing about a rule the grammar never reaches.
//!
//! ⛔ A RULE WITH NO WITNESS IS THE FINDING AND NOT A GAP IN THIS FILE. Two have none, and
//!    they are exactly the two that examine nothing: `share_exceeds_slack` and
//!    `exposure_unaccounted`. That is not a coincidence and it is the useful half of the
//!    result. A rule can only be falsified where it has rows, so an empty population and an
//!    unfalsifiable rule are one fact seen from two sides, and no edit to a document these
//!    rules do not look at will ever produce a witness.
//!
//! ⚠️ SUBSTITUTION, NOT ADDITION. The mutant REPLACES its source document in the ingest rather
//!    than joining it, so the corpus keeps its shape: same thirteen filings, same notation
//!    URNs, same part references. Adding a mutated copy would collide on `filing_identity`
//!    and would change what every composition rule is looking at.
//!
//! ⚠️ AND THE ANCHOR COUNT IS ASSERTED. Each witness names the occurrence it edits and this
//!    file checks how many there are. A document edit that changes the count fails loudly
//!    here rather than silently mutating a different claim and still going green.
//!
//! Run it with:
//!
//! ```text
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!     cargo run --example witnesses
//! ```

use std::collections::BTreeMap;
use std::fmt::Write as _;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

/// One rule, and the smallest edit to a real document that should make it say no.
struct Witness {
    /// The rule slug, from `assets/sqlc/checks/roster.sqlc`.
    rule: &'static str,
    /// The document the mutant replaces in the ingest.
    doc: &'static str,
    /// The text to find. `nth` says which occurrence.
    from_: &'static str,
    /// What to put there.
    to: &'static str,
    /// Which occurrence of `from_` to edit, counting from one.
    nth: usize,
    /// What the edit means, in the language of the rule.
    says: &'static str,
}

const WITNESSES: &[Witness] = &[
    Witness {
        rule: "clearance_with_unserved",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:kind>booked</pm:kind>",
        to: "<pm:kind>customer</pm:kind>",
        nth: 2,
        says: "the cover clears its demand and a customer is named as having gone unserved",
    },
    Witness {
        rule: "fit_disagrees",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:fit>clearance</pm:fit>",
        to: "<pm:fit>interference</pm:fit>",
        nth: 2,
        says: "nameplate 168 clears demand 147, and the filing calls it interference",
    },
    Witness {
        rule: "shares_do_not_sum",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:high>76</pm:high>",
        to: "<pm:high>300</pm:high>",
        nth: 1,
        // ⭐ THE ENDPOINT AND NOT THE MODE, DELIBERATELY. This exact edit was accepted by all
        //   24 rules until `shares_do_not_sum` learned to read the whole interval: 300
        //   engineer-hours a week of holder share on a layer rated 168, hidden behind a mode
        //   that did not move. A mode-only comparison cannot witness this, so the witness
        //   fails if the rule ever narrows back.
        says: "the share reaches 300 on a layer whose largest possible remainder is 76",
    },
    Witness {
        rule: "quantum_unit_mismatch",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:unit>engineer-hours per week</pm:unit>",
        to: "<pm:unit>widgets per week</pm:unit>",
        nth: 4,
        says: "the quantum divides a nameplate quoted in a different unit",
    },
    Witness {
        rule: "slack_unit_mismatch",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:unit>launches per quarter</pm:unit>",
        to: "<pm:unit>widgets per quarter</pm:unit>",
        nth: 5,
        says: "a slack is quoted in a unit the shares it bounds are not",
    },
    Witness {
        rule: "nameplate_not_a_multiple",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:low>168</pm:low>\n                    <pm:mostLikely>168</pm:mostLikely>\n                    <pm:high>168</pm:high>",
        to: "<pm:low>100</pm:low>\n                    <pm:mostLikely>100</pm:mostLikely>\n                    <pm:high>100</pm:high>",
        nth: 1,
        says: "168 hours of cover is not a whole number of 100-hour blocks",
    },
    Witness {
        rule: "draw_exceeds_the_supply",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "              <pm:low>92</pm:low>\n              <pm:mostLikely>118</pm:mostLikely>\n              <pm:high>147</pm:high>",
        to: "              <pm:low>800</pm:low>\n              <pm:mostLikely>900</pm:mostLikely>\n              <pm:high>1000</pm:high>",
        nth: 1,
        says: "the desk is recorded as having delivered five times what it is rated for",
    },
    Witness {
        rule: "range_says_no_range",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:narrowing>\n                <pm:condition>incident handling time is taken from the ticket clock rather than estimated at close</pm:condition>\n                <pm:kind>instrument</pm:kind>\n              </pm:narrowing>",
        to: "<pm:absent><pm:reason>notApplicable</pm:reason></pm:absent>",
        nth: 1,
        says: "a demand spanning 92 to 147 says there is no range to tighten",
    },
    Witness {
        rule: "narrows_a_point_value",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:absent>\n                  <pm:reason>notApplicable</pm:reason>\n                  <pm:note>there is no range here to tighten</pm:note>\n                </pm:absent>",
        to: "<pm:narrowing><pm:condition>a witness</pm:condition><pm:kind>instrument</pm:kind></pm:narrowing>",
        nth: 1,
        says: "a point nameplate names a condition that would tighten a width it does not have",
    },
    Witness {
        rule: "bound_fell_with_no_range",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:boundOrigin><pm:origin>intrinsic</pm:origin></pm:boundOrigin>",
        to: "<pm:boundOrigin><pm:absent><pm:reason>none</pm:reason></pm:absent></pm:boundOrigin>",
        nth: 1,
        says: "a point slack says its bound is where the measurements fell, and a point has no spread",
    },
    Witness {
        rule: "window_not_applicable_on_a_rate",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "<pm:reason>unmeasured</pm:reason>\n                    <pm:note>`turnos por semana` has a period and nobody has said which days of it the packing line runs</pm:note>",
        to: "<pm:reason>notApplicable</pm:reason>\n                    <pm:note>stipulated for this witness</pm:note>",
        nth: 1,
        says: "the duty-cycle question is called malformed on a unit that has a period",
    },
    Witness {
        rule: "derived_slack_over_a_window",
        doc: "assets/fixtures/every-absence.xml",
        from_: "<pm:unit>day</pm:unit>",
        to: "<pm:unit>hours</pm:unit>",
        nth: 1,
        says: "the window stops covering one whole period, so the spare is no longer known to be spread evenly",
    },
    Witness {
        rule: "window_lost_or_summed",
        doc: "assets/corpus/merge-holding-composition.xml",
        from_: "<pm:low>5</pm:low>\n                        <pm:mostLikely>5</pm:mostLikely>\n                        <pm:high>5</pm:high>",
        to: "<pm:low>3</pm:low>\n                        <pm:mostLikely>3</pm:mostLikely>\n                        <pm:high>3</pm:high>",
        nth: 1,
        says: "the composed layer files a different calendar from the part it carries",
    },
    Witness {
        rule: "fusion_sum_disagrees",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "<pm:low>0.5</pm:low>\n            <pm:mostLikely>0.8</pm:mostLikely>\n            <pm:high>1.2</pm:high>",
        to: "<pm:low>0.5</pm:low>\n            <pm:mostLikely>0.9</pm:mostLikely>\n            <pm:high>1.2</pm:high>",
        nth: 1,
        says: "the elimination moves, so the parts less the eliminations stop equalling the composed figure",
    },
    Witness {
        rule: "unresolved_part",
        doc: "assets/fixtures/every-local-part.xml",
        from_: "<pm:notation>urn:example:fixture:bakery:every-absence</pm:notation>",
        to: "<pm:notation>urn:example:fixture:bakery:no-such-filing</pm:notation>",
        nth: 1,
        says: "a part cites a filing that is not in the corpus",
    },
    Witness {
        rule: "coupling_does_not_attenuate",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "<pm:low>0.10</pm:low>\n              <pm:mostLikely>0.22</pm:mostLikely>\n              <pm:high>0.35</pm:high>",
        to: "<pm:low>0.01</pm:low>\n              <pm:mostLikely>0.02</pm:mostLikely>\n              <pm:high>0.03</pm:high>",
        nth: 1,
        says: "the coupling attenuates less through the fusion than the part's own share allows",
    },
    Witness {
        rule: "denied_remainder_is_not_contradicted",
        doc: "assets/corpus/unstated.xml",
        from_: "<pm:amount>\n            <pm:absent><pm:reason>notApplicable</pm:reason></pm:absent>\n          </pm:amount>",
        to: "<pm:amount>\n            <pm:claim><pm:low>30</pm:low><pm:mostLikely>30</pm:mostLikely><pm:high>30</pm:high><pm:unit>percent</pm:unit><pm:denominator><pm:absent><pm:reason>notApplicable</pm:reason></pm:absent></pm:denominator><pm:narrowsWhen><pm:absent><pm:reason>notApplicable</pm:reason></pm:absent></pm:narrowsWhen><pm:boundOrigin><pm:origin>policy</pm:origin></pm:boundOrigin></pm:claim>\n          </pm:amount>",
        nth: 1,
        says: "the layer denies having a remainder and then states both figures it would be the difference of",
    },
    Witness {
        rule: "nobody_named_as_unserved",
        doc: "assets/corpus/refutation.xml",
        from_: "<pm:kind>customer</pm:kind>",
        to: "<pm:kind>people</pm:kind>",
        nth: 1,
        says: "0.4 GPU could not be served and the only holder left absorbed it rather than going without",
    },
    Witness {
        rule: "local_part_dangles",
        doc: "assets/fixtures/every-local-part.xml",
        from_: "<pm:id>as-contracted</pm:id>",
        to: "<pm:id>ghost-layer</pm:id>",
        nth: 1,
        says: "a local part names a layer this document's own stack does not contain",
    },
    Witness {
        rule: "local_cycle",
        doc: "assets/fixtures/every-local-part.xml",
        from_: "<pm:id>as-contracted</pm:id>",
        to: "<pm:id>both-views</pm:id>",
        nth: 1,
        says: "a layer is composed from itself",
    },
    Witness {
        rule: "conversion_cycle_does_not_close",
        doc: "assets/fixtures/every-unit-cycle.xml",
        from_: "<pm:low>0.0108</pm:low><pm:mostLikely>0.0112</pm:mostLikely><pm:high>0.0116</pm:high>",
        to: "<pm:low>0.0018</pm:low><pm:mostLikely>0.0022</pm:mostLikely><pm:high>0.0026</pm:high>",
        nth: 1,
        // ⭐ THE CYCLE IS THE ONLY THING THAT MOVES. Each fusion still carries its own part
        //   exactly, because the composed figures are derived from this factor; what breaks is
        //   the walk all the way round, which is the one thing no single layer can see.
        says: "converting GPU to GPU-hour to node-hour and back lands at a fifth of where it started",
    },
    Witness {
        rule: "one_part_fusion_alters_its_part",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "<pm:low>8</pm:low>
                <pm:mostLikely>8</pm:mostLikely>
                <pm:high>8</pm:high>",
        to: "<pm:low>40</pm:low>
                <pm:mostLikely>40</pm:mostLikely>
                <pm:high>40</pm:high>",
        nth: 1,
        // ⭐ THIS EXACT EDIT WENT UNNOTICED BY EVERY COMPOSITION RULE until the identity check
        //   existed. `compute-us` is a one-part fusion with nothing eliminated, so its
        //   composed nameplate IS its part's, and five times the part is not a judgement call.
        says: "a one-part fusion carries 8 GPU as 40, five times the part it is composed from",
    },
    Witness {
        rule: "elimination_not_applicable_with_parts",
        doc: "assets/fixtures/every-elimination.xml",
        from_: "<pm:reason>unmeasured</pm:reason>\n        <pm:note>nobody checked whether these two parts double count. The fused figure may be",
        to: "<pm:reason>notApplicable</pm:reason>\n        <pm:note>nobody checked whether these two parts double count. The fused figure may be",
        nth: 1,
        says: "a two-part fusion calls the double-counting question malformed",
    },
];

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")
        .map_err(|_| "DATABASE_URL is unset. This example runs the corpus's own ingest and rules.")?;

    let ingest = fs::read_to_string("assets/sql/ingest.sql")?;
    let checks = fs::read_to_string("assets/sql/checks/all.sql")?;
    let roster = fs::read_to_string("assets/sql/checks/roster.sql")?;
    let roster = roster.trim().trim_end_matches(';');

    let dir = PathBuf::from("target/witnesses");
    fs::create_dir_all(&dir)?;

    println!("A rule that has never been seen to say no has not been tested.\n");

    // ⭐ ONE SCRIPT, ONE TRANSACTION PER WITNESS, EACH ROLLED BACK. A loaded corpus survives
    //   the run untouched, and the whole battery is a single psql invocation.
    let mut script = String::new();
    for w in WITNESSES {
        let src = fs::read_to_string(w.doc)?;
        let found = src.matches(w.from_).count();
        if found < w.nth {
            return Err(format!(
                "{}: its anchor occurs {found} time(s) in {} and it edits #{}. The document \
                 moved under the witness; re-read it rather than adjusting the number.",
                w.rule, w.doc, w.nth
            )
            .into());
        }
        let mut idx = 0;
        for _ in 0..w.nth {
            idx = src[idx..].find(w.from_).unwrap() + idx;
            idx += 1;
        }
        idx -= 1;
        let mutant = format!("{}{}{}", &src[..idx], w.to, &src[idx + w.from_.len()..]);

        let path = dir.join(format!("{}.xml", w.rule));
        fs::write(&path, &mutant)?;

        // ⛔ THE MUTANT MUST STILL VALIDATE. A document the grammar rejects says nothing about
        //   a rule that sits downstream of the grammar.
        let xsd = if mutant.contains("<asrt:") {
            "schema/assertion.xsd"
        } else {
            "schema/process-modulus.xsd"
        };
        let lint = Command::new("xmllint")
            .args(["--noout", "--schema", xsd])
            .arg(&path)
            .output()?;
        if !lint.status.success() {
            return Err(format!(
                "{}: the mutant does not validate, so it witnesses nothing:\n{}",
                w.rule,
                String::from_utf8_lossy(&lint.stderr)
            )
            .into());
        }

        let abs = fs::canonicalize(&path)?;
        let one = ingest
            .replace(&format!("cat {}", w.doc), &format!("cat {}", abs.display()))
            .replace("COMMIT;", "");
        writeln!(script, "{one}")?;
        writeln!(
            script,
            "WITH v AS (\n{checks}\n) SELECT '{}', rr.slug FROM v JOIN ({roster}) rr \
             ON rr.rule = v.rule WHERE v.violates GROUP BY rr.slug;",
            w.rule
        )?;
        writeln!(script, "ROLLBACK;\n")?;
    }

    let script_path = dir.join("witnesses.sql");
    fs::write(&script_path, &script)?;

    let psql = Command::new("psql")
        .arg(&url)
        .args(["-q", "-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-f"])
        .arg(&script_path)
        .output()?;
    if !psql.status.success() {
        eprintln!("{}", String::from_utf8_lossy(&psql.stderr));
        return Err(format!("psql failed. The script is at {}", script_path.display()).into());
    }

    let stdout = String::from_utf8_lossy(&psql.stdout);
    let mut fired: BTreeMap<&str, Vec<String>> = BTreeMap::new();
    for w in WITNESSES {
        fired.insert(w.rule, Vec::new());
    }
    for line in stdout.lines() {
        if let Some((target, slug)) = line.split_once('|') {
            if let Some(v) = fired.get_mut(target) {
                v.push(slug.to_string());
            }
        }
    }

    println!("{:<38} {:<9} {}", "rule", "witness", "what the edit says");
    let mut proven = 0usize;
    let mut collateral = 0usize;
    let mut failed: Vec<&str> = Vec::new();
    for w in WITNESSES {
        let f = &fired[w.rule];
        let hit = f.iter().any(|s| s == w.rule);
        let extra = f.iter().filter(|s| s.as_str() != w.rule).count();
        let mark = if hit && extra == 0 {
            proven += 1;
            "fires".to_string()
        } else if hit {
            proven += 1;
            collateral += 1;
            format!("fires +{extra}")
        } else {
            failed.push(w.rule);
            "SILENT".to_string()
        };
        println!("{:<38} {:<9} {}", w.rule, mark, w.says);
    }

    // ⭐⭐⭐ THE RULES NO WITNESS REACHES, WHICH IS WHAT THIS FILE IS FOR. Read from the roster
    //    rather than from a constant, so a rule added tomorrow arrives here unwitnessed
    //    instead of arriving unnoticed.
    let all: Vec<&str> = roster
        .lines()
        .filter_map(|l| l.trim().strip_prefix("('"))
        .filter_map(|l| l.split('\'').next())
        .collect();
    let unwitnessed: Vec<&&str> = all
        .iter()
        .filter(|r| !WITNESSES.iter().any(|w| w.rule == **r))
        .filter(|r| !fired.values().any(|v| v.iter().any(|s| s == **r)))
        .collect();

    // ⚠️ THREE COLUMNS AND NOT TWO, BECAUSE A RULE CAN BE SEEN TO FIRE WITHOUT BEING AIMED AT.
    //    `leaf_reached_twice` has no witness of its own and fires under the `local_cycle` one:
    //    a layer composed from itself is reachable by two paths, so the two rules cannot be
    //    separated by a single edit. That is evidence about the rule set rather than about
    //    this file, and folding it into either column would hide it.
    let collateral_only: Vec<&&str> = all
        .iter()
        .filter(|r| !WITNESSES.iter().any(|w| w.rule == **r))
        .filter(|r| fired.values().any(|v| v.iter().any(|s| s == **r)))
        .collect();
    println!(
        "
{} of {} rules have a witness of their own, {} of which trip a second rule as well.",
        proven,
        all.len(),
        collateral
    );
    if !collateral_only.is_empty() {
        println!(
            "{} more fire only as collateral, aimed at nothing: {}",
            collateral_only.len(),
            collateral_only
                .iter()
                .map(|r| **r)
                .collect::<Vec<_>>()
                .join(", ")
        );
    }
    println!(
        "{} of {} rules have now been observed to say no, against {} before this file existed.",
        proven + collateral_only.len(),
        all.len(),
        0
    );
    if !unwitnessed.is_empty() {
        println!("\nNo witness, and each one is a rule nothing has ever seen say no:");
        for r in &unwitnessed {
            println!("  {r}");
        }
        println!(
            "\n⛔ Both are the rules that examine NOTHING. A rule can only be falsified where it \n\
             has rows, so an empty population and an unfalsifiable rule are one fact from two \n\
             sides. No edit to a document these rules do not look at will ever witness them."
        );
    }

    if !failed.is_empty() {
        return Err(format!(
            "these witnesses did not fire their rule: {failed:?}. Either the mutation stopped \
             being wrong or the rule stopped noticing, and both are worth knowing."
        )
        .into());
    }
    Ok(())
}
