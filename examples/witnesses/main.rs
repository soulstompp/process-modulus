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
        rule: "identity_does_not_compute_the_claim",
        doc: "assets/corpus/enterprise-contract.xml",
        from_: "<pm:boundOrigin>\n              <pm:origin>contractual</pm:origin>\n            </pm:boundOrigin>",
        to: "<pm:boundOrigin><pm:derivation><pm:identity>fusionSum</pm:identity></pm:derivation></pm:boundOrigin>",
        nth: 1,
        says: "a demand's patience says its edge is a fusion's sum, and no identity computes a patience",
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
        rule: "window_size_not_applicable",
        doc: "assets/corpus/merge-us-member.xml",
        from_: "<pm:size>\n                    <pm:claim>\n                      <pm:low>5</pm:low>\n                      <pm:mostLikely>5</pm:mostLikely>\n                      <pm:high>5</pm:high>\n                      <pm:unit>days</pm:unit>\n                      <pm:denominator>\n                        <pm:absent>\n                          <pm:reason>notApplicable</pm:reason>\n                        </pm:absent>\n                      </pm:denominator>\n                      <pm:narrowsWhen>\n                        <pm:absent>\n                          <pm:reason>notApplicable</pm:reason>\n                          <pm:note>there is no range here to tighten</pm:note>\n                        </pm:absent>\n                      </pm:narrowsWhen>\n                      <pm:boundOrigin>\n                        <pm:derivation>\n                          <pm:identity>quantumOrigin</pm:identity>\n                          <pm:note>`LumpyQuantum/origin` says who sets this window, in this same element</pm:note>\n                        </pm:derivation>\n                      </pm:boundOrigin>\n                    </pm:claim>\n                  </pm:size>",
        to: "<pm:size><pm:absent><pm:reason>notApplicable</pm:reason></pm:absent></pm:size>",
        nth: 1,
        says: "a window filed as five days of each week calls the size of those days malformed",
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
        rule: "fusion_sum_disagrees",
        doc: "assets/fixtures/every-partial-elimination.xml",
        from_: "<pm:low>17</pm:low><pm:mostLikely>17</pm:mostLikely><pm:high>17</pm:high>",
        to: "<pm:low>18</pm:low><pm:mostLikely>18</pm:mostLikely><pm:high>18</pm:high>",
        nth: 1,
        says: "a composed nameplate of 18 where two parts of 10 less a shared block of 3 give 17",
    },
    Witness {
        rule: "fusion_sum_disagrees",
        doc: "assets/fixtures/every-inverting-elimination.xml",
        from_: "<pm:low>2</pm:low><pm:mostLikely>3</pm:mostLikely><pm:high>5</pm:high>",
        to: "<pm:low>2</pm:low><pm:mostLikely>3</pm:mostLikely><pm:high>4</pm:high>",
        nth: 1,
        says: "the shared block tops out at 4, so the crossed pairing starts at 16 and the filed 15 is wrong",
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
        rule: "nobody_named_as_unserved",
        doc: "assets/fixtures/every-unserved-excess.xml",
        from_: "<pm:kind>unrealised</pm:kind>",
        to: "<pm:kind>booked</pm:kind>",
        nth: 1,
        says: "every buffer is empty and a booked holder says part of the excess was absorbed",
    },
    Witness {
        rule: "exposure_unaccounted",
        doc: "assets/fixtures/every-unserved-excess.xml",
        from_: "<pm:low>1</pm:low><pm:mostLikely>3</pm:mostLikely><pm:high>4</pm:high>",
        to: "<pm:low>1</pm:low><pm:mostLikely>3</pm:mostLikely><pm:high>3</pm:high>",
        nth: 1,
        says: "6 could not be served and the unserved shares admit at most 5",
    },
    Witness {
        rule: "stated_quantity_is_not_the_magnitude",
        doc: "assets/corpus/refutation.xml",
        from_: "<pm:mostLikely>2.8</pm:mostLikely>",
        to: "<pm:mostLikely>2.9</pm:mostLikely>",
        // The first occurrence is the booked holder's share, which would trip `shares_do_not_sum`
        // instead; the second is the remainder's own `quantity`.
        nth: 2,
        says: "the remainder is stated as 2.9 GPU at the mode, where 16 less a demand of 13.2 is 2.8",
    },
    Witness {
        rule: "local_part_dangles",
        doc: "assets/fixtures/every-local-part.xml",
        from_: "<pm:id>as-contracted</pm:id>",
        to: "<pm:id>ghost-layer</pm:id>",
        nth: 1,
        says: "a local part names a layer this document's own stack does not contain",
    },
    // ⭐⭐ ONE MUTATION, AND ONLY ONE RULE MAY CLAIM IT. This document falsifies
    //   `layers_move_together`, which states the repair the schema asks for: merge the layers,
    //   or withdraw a part. ⛔ A witness cannot be aimed at a rule while a second rule fires on
    //   the same edit, because a mutation tripping two shows that SOMETHING is checked and not
    //   that THIS is.
    // ⭐⭐⭐ THE ONE THE GRAMMAR CANNOT REACH, AND THE MUTANT STILL VALIDATES BECAUSE OF IT.
    //   `partRegime` keyrefs the handle against `compositionRegimeId`, so flipping a part from
    //   the composer's `us` regime to its `pt` one resolves perfectly and XSD 1.0 is content.
    //   What it now claims is that `merge-us-member` reports under NCRF-PE, which that filing
    //   does not declare, and no identity constraint can look: an XSD key is scoped to one
    //   document. This is the boundary handed from the grammar to a rule, with a witness.
    Witness {
        rule: "part_regime_disagrees",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "<asrt:regime>us</asrt:regime>",
        to: "<asrt:regime>pt</asrt:regime>",
        nth: 1,
        says: "the composer puts a us-gaap member's layer under the Portuguese regime, and that member declares no such framework",
    },
    // ⭐⭐ THE ONLY WITNESS HERE THAT REMOVES RATHER THAN ALTERS, and it is legitimate because
    //   `asrt:citation` is `minOccurs="0"`: a composition with no instrument is a document the
    //   grammar accepts, which is exactly why a RULE has to refuse it. The group consolidates
    //   `us-gaap` and `NCRF-PE` into IFRS-2026 and this is it withdrawing the standard it did
    //   that under.
    Witness {
        rule: "regime_crossing_without_a_citation",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "  <asrt:citation>\n    <asrt:instrument>\n      <pm:taxonomy>urn:example:ifrs:standards</pm:taxonomy>\n      <pm:value>IFRS-10</pm:value>\n    </asrt:instrument>\n    <asrt:clause>B86</asrt:clause>\n    <asrt:version>2026</asrt:version>\n  </asrt:citation>",
        to: "",
        nth: 1,
        says: "a consolidation crosses two frameworks into a third and cites no instrument for it",
    },
    Witness {
        rule: "layers_move_together",
        doc: "assets/fixtures/every-local-part.xml",
        from_: "<pm:id>as-contracted</pm:id>",
        to: "<pm:id>both-views</pm:id>",
        nth: 1,
        says: "a layer is composed from itself, so its figure depends on its own value",
    },
    Witness {
        rule: "unit_crossing_without_a_factor",
        doc: "assets/corpus/merge-group-composition.xml",
        from_: "      <asrt:factor>
        <pm:claim>
          <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
          <pm:unit>people per pessoa</pm:unit>
          <pm:denominator><pm:each>pessoas</pm:each></pm:denominator>
          <pm:narrowsWhen>
            <pm:absent><pm:reason>notApplicable</pm:reason><pm:note>there is no range here to tighten</pm:note></pm:absent>
          </pm:narrowsWhen>
          <pm:boundOrigin><pm:origin>policy</pm:origin></pm:boundOrigin>
          <pm:provenance><pm:party>group-parent</pm:party>
            <pm:standing><pm:absent><pm:reason>unmeasured</pm:reason></pm:absent></pm:standing>
            <pm:note>the two members count heads on the same basis, checked against both establishment registers; a member counting full-time equivalents would not convert at one</pm:note>
          </pm:provenance>
        </pm:claim>
      </asrt:factor>",
        to: "",
        nth: 1,
        // ⭐ THE WITNESS IS A DELETION, which is the only mutation that reaches this rule: it
        //   fires on an element that is NOT there. Removing it puts the corpus back in the
        //   state where `pessoas` becomes `people` on the authority of a `coalesce` in a
        //   query rather than a filed factor.
        says: "a part quoted in `pessoas` is composed into a layer quoted in `people` and says nothing about the conversion",
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
    // ⭐⭐ THE BASELINE POPULATION OF EVERY RULE, ON THE UNTOUCHED CORPUS. It is what separates
    //   "no witness because nothing could ever falsify it" from "no witness because nobody wrote
    //   one", and the closing paragraph of this file asserted the first about both for as long
    //   as it took somebody to add a rule with rows.
    writeln!(
        script,
        "WITH v AS (\n{checks}\n) SELECT '__examined', rr.slug, count(*) FILTER (WHERE          v.violates IS NOT NULL)::text FROM v JOIN ({roster}) rr ON rr.rule = v.rule          GROUP BY rr.slug;"
    )?;
    for (i, w) in WITNESSES.iter().enumerate() {
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

        let path = dir.join(format!("{}-{i}.xml", w.rule));
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
            "WITH v AS (\n{checks}\n) SELECT 'w{i}', rr.slug FROM v JOIN ({roster}) rr \
             ON rr.rule = v.rule WHERE v.violates GROUP BY rr.slug;"
        )?;
        writeln!(script, "ROLLBACK;\n")?;
    }

    let script_path = dir.join("witnesses.sql");
    fs::write(&script_path, &script)?;

    let psql = Command::new("psql")
        // examples/shared/database/mod.rs says why: a plan this deep costs more to compile
        // than to run.
        .env("PGOPTIONS", "-c jit=off")
        .arg(&url)
        .args(["-q", "-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-f"])
        .arg(&script_path)
        .output()?;
    if !psql.status.success() {
        eprintln!("{}", String::from_utf8_lossy(&psql.stderr));
        return Err(format!("psql failed. The script is at {}", script_path.display()).into());
    }

    let stdout = String::from_utf8_lossy(&psql.stdout);
    // Keyed by witness, not by rule: a rule may have more than one witness, one per state of
    // the rule worth seeing fire.
    let mut fired: BTreeMap<usize, Vec<String>> = BTreeMap::new();
    let mut examined: BTreeMap<String, i64> = BTreeMap::new();
    for i in 0..WITNESSES.len() {
        fired.insert(i, Vec::new());
    }
    for line in stdout.lines() {
        let mut f = line.split('|');
        match (f.next(), f.next(), f.next()) {
            (Some("__examined"), Some(slug), Some(n)) => {
                examined.insert(slug.to_string(), n.parse().unwrap_or(0));
            }
            (Some(target), Some(slug), _) => {
                let at = target.strip_prefix('w').and_then(|n| n.parse::<usize>().ok());
                if let Some(v) = at.and_then(|at| fired.get_mut(&at)) {
                    v.push(slug.to_string());
                }
            }
            _ => {}
        }
    }

    println!("{:<38} {:<9} {}", "rule", "witness", "what the edit says");
    // Counted per rule, however many witnesses it has.
    let mut proven_rules: BTreeSet<&str> = BTreeSet::new();
    let mut collateral_rules: BTreeSet<&str> = BTreeSet::new();
    let mut failed: Vec<&str> = Vec::new();
    for (i, w) in WITNESSES.iter().enumerate() {
        let f = &fired[&i];
        let hit = f.iter().any(|s| s == w.rule);
        let extra = f.iter().filter(|s| s.as_str() != w.rule).count();
        let mark = if hit && extra == 0 {
            proven_rules.insert(w.rule);
            "fires".to_string()
        } else if hit {
            proven_rules.insert(w.rule);
            collateral_rules.insert(w.rule);
            format!("fires +{extra}")
        } else {
            failed.push(w.rule);
            "SILENT".to_string()
        };
        println!("{:<38} {:<9} {}", w.rule, mark, w.says);
    }
    let (proven, collateral) = (proven_rules.len(), collateral_rules.len());

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
    //    `jagged_layer` has no witness of its own and fires under the `layers_move_together` one:
    //    a layer composed from itself is also reachable by two paths, so the two rules cannot be
    //    separated by a single edit. That is evidence about the rule set rather than about
    //    this file, and folding it into either column would hide it. ⚠️ The entanglement is
    //    between the QUESTIONS and not between the files, so it survives any renaming of either
    //    rule.
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
        // ⛔⛔⛔ THIS PARAGRAPH IS DERIVED AND NEVER WRITTEN OUT. A sentence like "both of these
        //    examine NOTHING" is printed on every run whatever the list beside it holds, so it
        //    goes on asserting two while the list grows to four, and a claim in prose beside
        //    data that contradicts it is worse than no claim at all. ⭐ And the split is the
        //    point: a rule with no witness because nothing can falsify it and a rule with no
        //    witness because nobody wrote one are DIFFERENT FACTS, and collapsing them is the
        //    flattening this repository exists to refuse.
        let empty: Vec<&&&str> =
            unwitnessed.iter().filter(|r| examined.get(***r).copied().unwrap_or(0) == 0).collect();
        let unwritten: Vec<&&&str> =
            unwitnessed.iter().filter(|r| examined.get(***r).copied().unwrap_or(0) > 0).collect();
        println!(
            "\n⛔ {} of them examine NOTHING, and for those the two facts are one: a rule can only \n\
             be falsified where it has rows, so no edit to a document they do not look at will \n\
             ever witness them.",
            empty.len()
        );
        if !unwritten.is_empty() {
            println!(
                "⛔⛔ {} examine rows and simply have no witness, which is a debt in \n\
                 this file rather than a fact about the rule: {}",
                unwritten.len(),
                unwritten.iter().map(|r| ***r).collect::<Vec<_>>().join(", ")
            );
        }
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
