//! Reads the cross-document dependence and asserts the property it exists to prove.
//!
//! ⭐⭐ The interesting test here is `the_two_ends_are_parties_the_witness_is_not`. It is
//! not a parser check: it asserts the one thing that makes this a separate root element
//! rather than a widened `pm:Coupling`: that the observation is filed by somebody who is
//! the filer of neither end. It would fail the moment this document type was quietly used
//! as a `pm:Coupling` substitute, which is the only way it can be misused.
//!
//! ⚠️ `an_end_names_a_regime_the_statement_declared` deliberately re-implements the
//! schema's `xs:keyref` in Rust, for `corpus_parse.rs`'s stated reason: the two checks
//! answer to different authorities, and a document reaching this crate through some other
//! path (an API, a database, a hand-built value) was never validated at all.

use std::collections::HashSet;
use std::fs;

use process_modulus::asrt::DependenceType;
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

const DEP: &str = "dependence-group-consolidation.xml";

fn dependence(name: &str) -> DependenceType {
    let path = format!("{}/assets/corpus/{name}", env!("CARGO_MANIFEST_DIR"));
    let xml = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let mut reader = SliceReader::new(&xml);
    DependenceType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{path}: {e}"))
}

#[test]
fn the_statement_parses_and_is_dated_and_attributed() {
    let d = dependence(DEP);
    assert!(
        !d.witness.is_empty(),
        "anonymous testimony about somebody else's books is not a filing"
    );
    assert!(
        !d.observed_at.is_empty(),
        "an observation that does not say when it was made cannot be checked against \
         the filings as they were, nor compared with the next one"
    );
    assert!(
        !d.entry.is_empty(),
        "a statement with no entries observed nothing"
    );
}

/// ⛔ THE DISCIPLINE `pm:Coupling` SETS, AND IT IS LESS NEGOTIABLE HERE. There, a reader
/// who doubts the observation can read the rest of the filing it sits in. Here BOTH ENDS
/// ARE ELSEWHERE, so `observed` is the entire evidence a receiver holds.
#[test]
fn every_observation_says_what_was_observed() {
    for (i, e) in dependence(DEP).entry.iter().enumerate() {
        assert!(
            e.observed.trim().len() > 30,
            "entry {i}: a dependence filed without saying what was observed is an opinion"
        );
    }
}

/// ⚠️ The keyref, re-implemented. A regime handle is the ONE reference in this document a
/// validator can resolve, precisely because it is document-local. See the type.
#[test]
fn an_end_names_a_regime_the_statement_declared() {
    let d = dependence(DEP);
    let declared: HashSet<&str> = d.regime.iter().map(|r| r.id.as_str()).collect();

    let mut named = 0;
    for e in &d.entry {
        for (side, end) in [("from", &e.from), ("to", &e.to)] {
            if let Some(id) = end.regime.as_deref() {
                named += 1;
                assert!(
                    declared.contains(id),
                    "{side}: names regime `{id}`, which this statement never declared"
                );
            }
        }
    }
    assert!(
        named > 0,
        "the example exists partly to exercise the regime handles"
    );
}

/// ⭐⭐⭐ THE PROPERTY, AND THE REASON THIS IS A DOCUMENT RATHER THAN AN ELEMENT.
///
/// A filing is attestable by the party that files it. A coupling inside entity A's
/// document naming entity B's layer is a claim A cannot attest to, because A cannot see
/// B's stack, so the observation is filed by a third party who has read both.
///
/// ⛔ If this ever passes with the witness on one end, somebody has used this document as
/// a `pm:Coupling` substitute and the attestation argument has been quietly discarded.
#[test]
fn the_two_ends_are_parties_the_witness_is_not() {
    let d = dependence(DEP);
    // ⭐ `provenance` is REQUIRED now. `Composition` says in its own words that a filing
    // without `provenance/standing` is a FABRICATION, and both were optional for three
    // revisions — the schema naming a condition and then permitting documents that fail it.
    let observer = d.provenance.party.clone().unwrap_or_default();

    for e in &d.entry {
        assert_ne!(
            e.from.party, e.to.party,
            "two ends of one party's own stack belong in pm:Coupling, inside that filing"
        );
        assert_ne!(
            e.from.filing.notation, e.to.filing.notation,
            "this example exists to show two SEPARATE filings"
        );
        for end in [&e.from, &e.to] {
            assert_ne!(
                end.party, d.witness,
                "the witness filed one of the ends, so this is not a third-party \
                 observation and belongs inside that filing instead"
            );
            assert_ne!(
                end.party, observer,
                "same, for the entity standing behind the witness"
            );
        }
    }
}

/// ⭐⭐ THE CONSOLIDATOR'S ORDINARY CASE: two ends measured under different frameworks,
/// and the document says so structurally rather than in prose. A statement that cannot
/// name which regime each end reported under has hidden the reason two numbers disagree,
/// which is `Absence`'s rule, arriving at an attribution instead of at a reason.
#[test]
fn the_two_ends_may_report_under_different_frameworks() {
    let d = dependence(DEP);
    assert!(
        d.regime.len() >= 2,
        "the example exists to show a cross-regime observation"
    );
    let e = d.entry.first().expect("one entry");
    assert_ne!(
        e.from.regime, e.to.regime,
        "the subsidiary and the parent report under different frameworks, and the \
         statement is what makes that queryable"
    );
}
