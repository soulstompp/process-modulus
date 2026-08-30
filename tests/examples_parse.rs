//! Reads every document in `examples/` with the generated types.
//!
//! These are not tests of the schema. The schema is checked by a validator, and a
//! validator is the thing other parties will run. They test the CRATE: that the
//! reference implementation can actually read a conforming document, and that the
//! facts the examples were written to demonstrate survive the round trip into Rust.
//!
//! ⚠️ `assert_layer_references_resolve` deliberately re-implements the schema's
//! `xs:keyref` in Rust. That is not redundancy: the two checks answer to different
//! authorities, and a document reaching this crate through some other path (an API,
//! a database, a hand-built value) was never validated at all.

use std::collections::HashSet;
use std::fs;

use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, FitType, HolderKindType, OperationTypeContent, ProcessModulusElementType,
    ConstraintOriginType, DivisibilityType, StatedBooleanType, StatedBorrowedTermType, StatedClaimType,
    StatedDivisibilityType, StatedHolderType, StatedRemainderType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

fn load(name: &str) -> ProcessModulusElementType {
    let path = format!("{}/examples/{name}", env!("CARGO_MANIFEST_DIR"));
    let xml = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let mut reader = SliceReader::new(&xml);
    ProcessModulusElementType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// Every `<draw>` and `<induces>` names a layer that the stack declares.
fn assert_layer_references_resolve(doc: &ProcessModulusElementType, what: &str) {
    let declared: HashSet<&str> = doc.stack.layer.iter().map(|l| l.name.as_str()).collect();

    for op in &doc.operation {
        for item in &op.content {
            let referenced = match item {
                OperationTypeContent::Draw(d) => &d.layer,
                OperationTypeContent::Induces(i) => &i.layer,
                _ => continue,
            };
            assert!(
                declared.contains(referenced.as_str()),
                "{what}: an operation draws on undeclared layer {referenced:?}"
            );
        }
    }

    for c in &doc.stack.coupling {
        for end in [&c.from, &c.to] {
            assert!(
                declared.contains(end.as_str()),
                "{what}: a coupling names undeclared layer {end:?}"
            );
        }
    }
}

fn layer<'a>(doc: &'a ProcessModulusElementType, name: &str) -> &'a process_modulus::pm::LayerType {
    doc.stack
        .layer
        .iter()
        .find(|l| l.name == name)
        .unwrap_or_else(|| panic!("no layer named {name:?}"))
}

#[test]
fn both_examples_parse_and_their_references_resolve() {
    for name in ["enterprise-contract.xml", "refutation.xml", "unstated.xml"] {
        let doc = load(name);
        assert!(!doc.stack.layer.is_empty(), "{name}: a stack needs a layer");
        assert_layer_references_resolve(&doc, name);
    }
}

/// The fourth-buffer argument, filed: a remainder that is real, held by people, and
/// has no number, and all three of those survive into the type system.
#[test]
fn the_labour_remainder_is_borne_and_unmeasured() {
    let doc = load("enterprise-contract.xml");
    let StatedRemainderType::Remainder(r) = &layer(&doc, "labour").remainder else {
        panic!("the labour layer should carry a remainder");
    };

    assert_eq!(r.sign, FitType::Interference);

    let StatedHolderType::Holder(h) = &r.holder else {
        panic!("the holder should be stated");
    };
    assert_eq!(h.kind, HolderKindType::People);

    let StatedClaimType::Absent(a) = &r.quantity else {
        panic!("nobody measures this; the example would be dishonest with a number");
    };
    assert_eq!(
        a.reason,
        AbsenceReasonType::Unmeasured,
        "`unmeasured` is the claim. `none` would assert somebody looked and found zero"
    );
}

/// The framework a regime actually names, for the examples that state one.
///
/// ⭐ Every example here names its framework. The wrapper exists for senders who
/// cannot yet, which is S-1; a test that silently tolerated `absent` would stop
/// checking the thing it is here to check.
fn stated_framework(r: &pm::RegimeType) -> &pm::BorrowedTermType {
    match &r.framework {
        StatedBorrowedTermType::Term(t) => t,
        StatedBorrowedTermType::Absent(_) => {
            panic!("this example is expected to name its framework")
        }
    }
}

/// The counter-example, filed: a supply with no quantum, no premium and no remainder.
#[test]
fn a_continuous_supply_files_a_remainder_of_none() {
    let doc = load("refutation.xml");
    let l = layer(&doc, "object-storage");

    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        panic!("this example states a divisibility rather than declining the axis");
    };
    let DivisibilityType::Continuous(q) = d else {
        panic!("object storage is bought continuously in this example");
    };
    let StatedClaimType::Absent(premium) = &q.premium else {
        panic!("the premium should be stated");
    };
    assert_eq!(
        premium.reason,
        AbsenceReasonType::None,
        "a zero premium is the counter-example; `unmeasured` would only be a gap"
    );

    let StatedRemainderType::Absent(r) = &l.remainder else {
        panic!("a continuous supply divides exactly");
    };
    assert_eq!(r.reason, AbsenceReasonType::None);
}

/// The falsifier is expressible, and it carries its evidence.
#[test]
fn a_coupling_is_filable_and_states_what_was_observed() {
    let doc = load("refutation.xml");
    let c = doc
        .stack
        .coupling
        .first()
        .expect("refutation.xml exists to file one");

    assert_ne!(c.from, c.to, "a layer coupled to itself says nothing");
    assert!(
        c.observed.len() > 40,
        "`observed` is required so that a coupling cannot be filed as an opinion"
    );
}

/// Two quanta of different origin, because they are not the same kind of fact: one
/// is a seller's terms and the other is arithmetic about people.
#[test]
fn constraint_origin_separates_the_negotiable_from_the_indivisible() {
    let doc = load("enterprise-contract.xml");

    let origins: Vec<(&str, ConstraintOriginType)> = doc
        .stack
        .layer
        .iter()
        .filter_map(|l| match &l.supply.nameplate.divisibility {
            StatedDivisibilityType::Divisibility(DivisibilityType::Lumpy(q)) => {
                Some((l.name.as_str(), q.origin.clone()))
            }
            StatedDivisibilityType::Divisibility(DivisibilityType::Continuous(_)) => None,
            StatedDivisibilityType::Absent(_) => None,
        })
        .collect();

    assert!(origins.contains(&("compute", ConstraintOriginType::Contractual)));
    assert!(origins.contains(&("labour", ConstraintOriginType::Intrinsic)));
    assert!(origins.contains(&("capability", ConstraintOriginType::Intrinsic)));
}

/// An induction names the layer that bears the commitment and, here, who made it.
/// The transfer is what no account records; this is the element that records it.
#[test]
fn an_induction_lands_on_a_different_layer_than_the_draw() {
    let doc = load("enterprise-contract.xml");
    let op = doc
        .operation
        .iter()
        .find(|o| {
            o.content
                .iter()
                .any(|c| matches!(c, OperationTypeContent::Induces(_)))
        })
        .expect("the enterprise contract induces work");

    let draws: Vec<&str> = op
        .content
        .iter()
        .filter_map(|c| match c {
            OperationTypeContent::Draw(d) => Some(d.layer.as_str()),
            _ => None,
        })
        .collect();

    let induced: Vec<&process_modulus::pm::InductionType> = op
        .content
        .iter()
        .filter_map(|c| match c {
            OperationTypeContent::Induces(i) => Some(i),
            _ => None,
        })
        .collect();

    for i in &induced {
        assert!(
            !draws.contains(&i.layer.as_str()),
            "the point of an induction is that the commitment lands somewhere the \
             operation is not drawing from"
        );
        assert!(
            i.decided_by.is_some(),
            "an induction without a decider records the transfer but not the transferor"
        );
    }
}

/// ⭐ Two authorities describing ONE entity, and de-duplicating them would destroy a
/// fact: the codes are not derivable from each other, so neither declaration says
/// what the pair says.
#[test]
fn one_entity_may_declare_two_regimes() {
    let doc = load("refutation.xml");
    assert_eq!(
        doc.regime.len(),
        2,
        "the Portuguese case files both codings"
    );

    let authorities: HashSet<&str> = doc
        .regime
        .iter()
        .map(|r| stated_framework(r).taxonomy.as_str())
        .collect();
    assert_eq!(
        authorities.len(),
        2,
        "two regimes citing the SAME authority would be a genuine duplicate; two \
         citing different ones are two facts"
    );

    let codes: HashSet<&str> = doc
        .regime
        .iter()
        .map(|r| stated_framework(r).value.as_str())
        .collect();
    assert_eq!(codes.len(), 2, "the whole point is that the codes differ");

    for r in &doc.regime {
        assert_eq!(
            r.jurisdiction.as_deref(),
            Some("PT"),
            "same jurisdiction, different coding authority: that is the trap"
        );
    }
}

/// A regime is a DECLARATION, so the schema does not make it plural by accident:
/// a document reporting under one framework says so once.
#[test]
fn a_single_regime_is_the_ordinary_case() {
    let doc = load("enterprise-contract.xml");
    assert_eq!(doc.regime.len(), 1);
    assert_eq!(stated_framework(&doc.regime[0]).value, "us-gaap");
}

// ==========================================================================
// WHAT A SENDER MAY DECLINE.
//
// Each of these was UNWRITABLE before the Stated* pass, and each was filed by a
// real adopter as a workaround that asserted something they did not believe. A
// test that only proved the documents parse would not prove the distinction is
// reachable, so every one below reads the reason back out.
// ==========================================================================

/// S-1. The pair that shared one encoding: "reports under something, unnamed"
/// and "reports under none" are now different documents, and the difference is
/// readable rather than inferred from an omission.
#[test]
fn a_regime_can_decline_its_framework_without_merging_none_into_unmeasured() {
    let doc = load("unstated.xml");
    assert_eq!(doc.regime.len(), 2, "one regime for each side of the pair");

    let reasons: Vec<AbsenceReasonType> = doc
        .regime
        .iter()
        .map(|r| match &r.framework {
            StatedBorrowedTermType::Absent(a) => a.reason.clone(),
            StatedBorrowedTermType::Term(_) => {
                panic!("this example declines both frameworks on purpose")
            }
        })
        .collect();

    assert!(
        reasons.contains(&AbsenceReasonType::Unmeasured),
        "a sender who HAS a framework but cannot name it must be able to say so"
    );
    assert!(
        reasons.contains(&AbsenceReasonType::None),
        "a sender who reports under NO framework must be distinguishable from one \
         who simply omitted the regime -- that merge is what S-1 reported"
    );
}

/// The chart a regime declares, or `None` where it declined to name one.
fn stated_chart(r: &pm::RegimeType) -> Option<&pm::BorrowedTermType> {
    match &r.chart {
        StatedBorrowedTermType::Term(t) => Some(t),
        StatedBorrowedTermType::Absent(_) => None,
    }
}

fn regime<'a>(doc: &'a ProcessModulusElementType, id: &str) -> &'a pm::RegimeType {
    doc.regime
        .iter()
        .find(|r| r.id == id)
        .unwrap_or_else(|| panic!("no regime `{id}`"))
}

/// ⭐⭐ S-11. THE STATE THAT WAS UNSAYABLE. A tier nobody has assigned picks no
/// framework, and the framework picks the chart -- so there WILL be a chart and
/// nobody has said which. Before the wrapper the only encodings were "this entity
/// has no chart", which is false, or an invented taxonomy URI.
///
/// ⛔ `none` would be the wrong reason here, and the test says so: `none` is a claim
/// that somebody looked and there is none.
#[test]
fn a_regime_can_decline_its_chart_without_claiming_it_has_none() {
    let doc = load("unstated.xml");
    let r1 = &regime(&doc, "r1").chart;
    match r1 {
        StatedBorrowedTermType::Absent(a) => assert_eq!(
            a.reason,
            AbsenceReasonType::Unmeasured,
            "the tier is unassigned, so the chart is UNNAMED rather than absent"
        ),
        StatedBorrowedTermType::Term(_) => {
            panic!("r1 is expected to decline the chart its unnamed framework selects")
        }
    }
}

/// ⭐⭐⭐ S-11. THERE IS NO UNITED STATES CHART OF ACCOUNTS. What is published there is
/// a reporting TAXONOMY -- concepts a filing is tagged with -- and every filer's chart
/// of accounts is their own and unpublished. The filer is genuinely the authority for
/// it, so naming themselves satisfies BorrowedTerm rather than evading it.
///
/// ⛔ THE TEST IS THAT THE CHART IS NOT THE FRAMEWORK'S TAXONOMY, because filing
/// `http://fasb.org/us-gaap` as a chart is the exact category error the annotation
/// exists to catch: it declares a chart nobody posts to.
#[test]
fn a_chart_with_no_publishing_authority_names_the_entity_as_its_own() {
    for (file, id) in [
        ("enterprise-contract.xml", "us-gaap"),
        ("unstated.xml", "r2"),
    ] {
        let doc = load(file);
        let r = regime(&doc, id);
        let chart = stated_chart(r)
            .unwrap_or_else(|| panic!("{file}/{id}: a self-authored chart is still a chart"));
        if let StatedBorrowedTermType::Term(fw) = &r.framework {
            assert_ne!(
                chart.taxonomy, fw.taxonomy,
                "{file}/{id}: a reporting taxonomy is not a chart of accounts"
            );
        }
        assert!(
            !chart.taxonomy.is_empty() && !chart.value.is_empty(),
            "{file}/{id}: the authority and the edition both travel"
        );
    }
}

/// ⭐⭐ S-9. THE CHART IS A SEPARATE AXIS FROM THE FRAMEWORK, and this is the document
/// that proves it rather than asserting it: two regimes, two authorities' codings of
/// one framework -- `NC-ME` to IES and `M` to SAF-T -- and ONE chart between them,
/// because a chart is national and the authority that codes the framework is not.
///
/// ⛔ If these two ever collapse to one taxonomy, the axis claim has been lost.
#[test]
fn two_codings_of_one_framework_share_one_chart() {
    let doc = load("refutation.xml");
    let (a, b) = (regime(&doc, "ies-anexo-asnc"), regime(&doc, "saft-referencial"));

    assert_ne!(
        stated_framework(a).taxonomy,
        stated_framework(b).taxonomy,
        "the two regimes are coded by different authorities"
    );
    assert_eq!(
        stated_chart(a).expect("ies names its chart").taxonomy,
        stated_chart(b).expect("saft names its chart").taxonomy,
        "one chart, two framework codings -- the axes are separate"
    );
}

/// S-8. `notApplicable` is not a kind of divisibility; it is the absence of one.
/// The workaround it replaces asserted `continuous` and denied it one level down,
/// where no query would meet the denial.
#[test]
fn a_subject_that_is_not_a_supply_can_decline_the_divisibility_axis() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedDivisibilityType::Absent(a) = &l.supply.nameplate.divisibility else {
        panic!("a margin ratio is neither lumpy nor continuous");
    };
    assert_eq!(a.reason, AbsenceReasonType::NotApplicable);
}

/// S-2. The one required value a sender could not decline, and the fact new
/// senders most often have not established.
#[test]
fn admits_interference_can_be_left_unmeasured_instead_of_guessed() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedBooleanType::Absent(a) = &l.supply.nameplate.admits_interference else {
        panic!("this example has not established whether interference is admitted");
    };
    assert_eq!(a.reason, AbsenceReasonType::Unmeasured);
}

/// S-3 and S-7, which turned out to be one repair. Three parties that used to
/// flatten into one string are separately joinable, and `standing` is where
/// `unverified` belongs -- on the assertion, never as a fifth AbsenceReason.
#[test]
fn provenance_separates_the_three_parties_and_carries_standing() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedClaimType::Claim(c) = &l.demand else {
        panic!("this example states its demand");
    };
    let p = c.provenance.as_ref().expect("the demand carries its provenance");

    assert_eq!(p.party.as_deref(), Some("finance"));
    assert_eq!(p.entered_by.as_deref(), Some("analyst-04"));
    assert_eq!(p.approved_by.as_deref(), Some("controller-01"));

    let standing = p.standing.as_ref().expect("standing is filed here");
    assert_eq!(standing.value, "reviewed-not-verified");
    assert!(
        !standing.taxonomy.is_empty(),
        "standing is a BorrowedTerm because this model does not own the set"
    );
}

/// S-5. What BOUNDS a range is a different question from what would NARROW it,
/// and a sender with both facts can now file both.
#[test]
fn a_claim_can_carry_both_what_bounds_it_and_what_would_narrow_it() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedClaimType::Claim(c) = &l.demand else {
        panic!("this example states its demand");
    };
    assert_eq!(c.bound_origin, Some(ConstraintOriginType::Policy));
    assert!(
        c.narrows_when.is_some(),
        "both facts are present, which is the case that could not be filed before"
    );
}
