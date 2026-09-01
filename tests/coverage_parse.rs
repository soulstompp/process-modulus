//! Reads the coverage and run documents, and asserts the property they exist to prove.
//!
//! ⭐ The interesting test here is `two_regimes_are_comparable_where_they_share_an_authority`.
//! It is not a parser check: it asserts that the SAME questions answered under two
//! regimes stay comparable exactly where the two witnesses cite the same taxonomy, and
//! stop being comparable exactly where they do not. That is the whole reason a refusal
//! code and a chart position are borrowed terms rather than strings.

use std::collections::HashSet;
use std::fs;

use process_modulus::asrt::{AnswerType, ClaimedType, CoverageType, RunType, VerdictType};
use process_modulus::pm::StatedBorrowedTermType;
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

fn read(name: &str) -> String {
    let path = format!("{}/assets/corpus/{name}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

fn coverage(name: &str) -> CoverageType {
    let xml = read(name);
    let mut reader = SliceReader::new(&xml);
    CoverageType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{name}: {e}"))
}

fn run(name: &str) -> RunType {
    let xml = read(name);
    let mut reader = SliceReader::new(&xml);
    RunType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{name}: {e}"))
}

const US: &str = "coverage-us-gaap.xml";
const PT: &str = "coverage-pt-ncrf-pe.xml";

#[test]
fn both_coverage_files_and_the_run_parse() {
    for name in [US, PT] {
        let c = coverage(name);
        assert!(
            !c.witness.is_empty(),
            "{name}: a coverage names its witness"
        );
        assert!(
            !c.entry.is_empty(),
            "{name}: a coverage with no entries claims nothing"
        );
    }
    let r = run("run-2026-08-30.xml");
    assert!(!r.result.is_empty());
}

/// ⭐⭐ THE PROPERTY. Two regimes answering one corpus are comparable row by row where
/// they cite the same authority, and legibly incomparable where they do not.
#[test]
fn two_regimes_are_comparable_where_they_share_an_authority() {
    let (us, pt) = (coverage(US), coverage(PT));

    let keys =
        |c: &CoverageType| -> HashSet<String> { c.entry.iter().map(|e| e.key.clone()).collect() };
    let shared: HashSet<String> = keys(&us).intersection(&keys(&pt)).cloned().collect();
    assert!(
        shared.len() >= 3,
        "the two witnesses must answer the SAME questions or there is nothing to compare"
    );

    // Where both refuse, they draw from one pack, so the codes mean the same thing.
    let refusal_authorities = |c: &CoverageType| -> HashSet<String> {
        c.entry
            .iter()
            .filter_map(|e| match e.answer.as_ref()? {
                AnswerType::Refuses(t) => Some(t.taxonomy.clone()),
                _ => None,
            })
            .collect()
    };
    assert_eq!(
        refusal_authorities(&us),
        refusal_authorities(&pt),
        "both witnesses cite the same coding pack, which is what makes two refusals \
         comparable rather than two unrelated exercises"
    );

    // Where both name a position, the charts are national and share nothing.
    let position_authorities = |c: &CoverageType| -> HashSet<String> {
        c.entry
            .iter()
            .filter_map(|e| match e.answer.as_ref()? {
                AnswerType::Holds(t) => Some(t.taxonomy.clone()),
                _ => None,
            })
            .collect()
    };
    let (a, b) = (position_authorities(&us), position_authorities(&pt));
    assert!(!a.is_empty() && !b.is_empty());
    assert!(
        a.is_disjoint(&b),
        "chart positions are coded nationally (or per entity, in the US, which has no \
         national chart). If these overlapped, a comparison across the pair would be \
         comparing unrelated strings, which is what a bare code silently does"
    );
}

/// ⛔ An undeclared divergence is a bug; a declared one is a position. The reason is
/// what separates them, so an exception without one is not conformant.
#[test]
fn every_declared_exception_carries_a_reason() {
    for name in [US, PT] {
        let c = coverage(name);
        let declared: Vec<_> = c.entry.iter().filter(|e| e.exception.is_some()).collect();
        assert!(
            !declared.is_empty(),
            "{name}: both examples exist partly to show a declared divergence"
        );
        for e in declared {
            let reason = e.exception.as_deref().unwrap_or("");
            assert!(
                reason.trim().len() > 30,
                "{name}: `{}` declares an exception with no real reason, which reads \
                 exactly like a defect somebody stopped chasing",
                e.key
            );
            assert!(
                e.answer.is_some(),
                "{name}: `{}` declares an exception with no answer beside it, so there \
                 is nothing for the reason to explain",
                e.key
            );
        }
    }
}

/// ⭐ `notable` is the valuable verdict and the easiest to leave unexplained. A run
/// promoted to evidence must say what was observed, or it cannot be checked later.
#[test]
fn the_notable_result_carries_its_evidence() {
    let r = run("run-2026-08-30.xml");

    let interesting: Vec<_> = r
        .result
        .iter()
        .filter(|x| matches!(x.verdict, VerdictType::Notable | VerdictType::Diverged))
        .collect();
    assert!(
        !interesting.is_empty(),
        "a promoted run with nothing notable or diverged is not evidence of much"
    );

    for x in interesting {
        assert!(
            x.evidence
                .as_deref()
                .map(str::trim)
                .is_some_and(|e| e.len() > 30),
            "`{}` is {:?} with no evidence, which is an assertion about the past nobody can check",
            x.key,
            x.verdict
        );
    }
}

/// ⭐⭐ THE FIFTH RULE, AND `Regime/chart` IS WHAT MADE IT STATABLE AT ALL.
///
/// `Regime`'s annotation asserts a universal -- "any answer naming a position must carry
/// the chart that codes it" -- and until `chart` existed there was nowhere for the
/// EXPECTED value to live, so the rule was satisfiable by carrying ANY chart. A regime
/// declared as a Portuguese microentity whose one answer held a US position validated,
/// and nothing could say otherwise.
///
/// ⛔ `holds` ONLY, NEVER `refuses`. A refusal code comes from a coding pack that is
/// deliberately SHARED across regimes -- that is the property the test above pins -- so
/// checking refusals against the chart would break the thing the pack is for.
///
/// ⚠️ This is `conformance/README.md`'s owed-rule list, implemented for the documents in
/// this repository rather than in general. A profile still owes it for documents it has
/// never seen; the crate can only answer for what it can read.
#[test]
fn every_position_is_held_in_a_chart_its_own_document_declares() {
    for name in [US, PT] {
        let c = coverage(name);

        let declared: HashSet<String> = c
            .regime
            .iter()
            .filter_map(|r| match &r.chart {
                StatedBorrowedTermType::Term(t) => Some(t.taxonomy.clone()),
                StatedBorrowedTermType::Absent(_) => None,
            })
            .collect();
        assert!(
            !declared.is_empty(),
            "{name}: a coverage that files chart positions must declare the chart"
        );

        let held: Vec<String> = c
            .entry
            .iter()
            .filter_map(|e| match e.answer.as_ref()? {
                AnswerType::Holds(t) => Some(t.taxonomy.clone()),
                _ => None,
            })
            .collect();
        assert!(!held.is_empty(), "{name}: expected at least one position");

        for taxonomy in held {
            assert!(
                declared.contains(&taxonomy),
                "{name}: an answer holds a position in `{taxonomy}`, which no regime in \
                 this document declares as its chart. Either the answer is in the wrong \
                 chart or the regime never said which chart it posts to -- and before \
                 `Regime/chart` existed, neither could be told from the other"
            );
        }
    }
}

/// ⭐⭐⭐ HOW MUCH OF THE QUESTION DOES THIS WITNESS SAY IT ANSWERS? `CoverageEntry/complete`
/// was an `xs:boolean` — the only one in either schema — and it was the last survivor of the
/// pattern this project has caught five times: A TWO-VALUED ENCODING SURVIVES REVIEW BECAUSE
/// BOTH OF ITS VALUES ARE CORRECT. `true` was right, `false` was right, and nothing in a
/// boolean field points at what it cannot say.
///
/// ⛔ `false` WAS CARRYING TWO OPPOSITE READINGS. `none` says the question is outside this
/// witness's subject; `partial` says it is inside and half covered. A report that merges them
/// cannot tell a witness that declines from a witness that falls short — and a corpus about
/// quantities nobody records is asking precisely about the half that is not covered.
///
/// ⭐⭐ AND IT IS WHAT MAKES `notable` REACHABLE. `Verdict/notable` is "answered beyond what
/// was claimed", so a graded claim gives it two more ways to fire, not one.
#[test]
fn a_witness_says_how_much_of_each_question_it_answers() {
    let mut seen = Vec::new();

    for name in [US, PT] {
        for e in &coverage(name).entry {
            // ⛔ A WITNESS THAT TAKES ON NO PART OF A QUESTION HAS ONE HONEST ANSWER, and it
            // is not a refusal: a refusal is a coded position under a framework, which is a
            // full answer. `cannotAsk` is the witness saying the question is not its subject.
            if e.claimed == ClaimedType::None {
                assert!(
                    matches!(e.answer, Some(AnswerType::CannotAsk(_)) | None),
                    "{name} `{}`: claims none of the question and then answers it. That is \
                     `notable` for a runner to report, not something to file as a claim",
                    e.key
                );
            }
            // A witness that claims the whole question owes the whole answer.
            if e.claimed == ClaimedType::Full {
                assert!(
                    e.answer.is_some() || e.citation.is_empty(),
                    "{name} `{}`: claims the question fully and states nothing",
                    e.key
                );
            }
            seen.push(e.claimed.clone());
        }
    }

    assert!(
        seen.contains(&ClaimedType::Full) && seen.contains(&ClaimedType::None),
        "both witnesses answer some questions and decline others; a corpus where every entry \
         claims the same amount tests nothing about the distinction"
    );

    // ⚠️⚠️ AND THE THIRD VALUE IS UNEXERCISED, WHICH IS RECORDED RATHER THAN PAPERED OVER.
    // No entry in this corpus is a genuine `partial`: both witnesses either code a position,
    // return a typed refusal — which IS a complete answer under a framework — or say the
    // question is not theirs. A witness that codes the transacted half of an absorbed cost
    // and has no position for the rest would be the case, and nobody has filed one. Inventing
    // an entry to light this branch would make the corpus agree with the schema by
    // construction, which is the failure `Verdict/diverged` names.
    assert!(
        !seen.contains(&ClaimedType::Partial),
        "a witness now files `partial`. That is the interesting state and it should be checked \
         here rather than merely permitted: does its answer cover only part of the question, \
         and does the runner report `notable` when it covers more?"
    );
}
