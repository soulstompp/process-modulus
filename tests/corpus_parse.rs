//! Reads every document in `assets/corpus/` with the generated types.
//!
//! These are not tests of the schema. The schema is checked by a validator, and a validator is
//! what other parties will run. They test the crate: that the reference implementation can read
//! a conforming document, and that the facts the examples were written to demonstrate survive
//! being read into Rust.
//!
//! ## Reading only
//!
//! This file reads documents and never writes one. `tests/roundtrip.rs` is the other half: it
//! holds the crate to writing back what it was handed. Neither file is a validator, and neither
//! claims to be.
//!
//! ## Why the key references are checked twice
//!
//! `assert_layer_references_resolve` re-implements the schema's `xs:keyref` in Rust on purpose.
//! The two checks answer to different authorities, and a document that reaches this crate by
//! another path (an API, a database, a hand-built value) was never validated at all.

use std::collections::HashSet;
use std::fs;

use process_modulus::asrt::CompositionType;
use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, ClaimAbsenceReasonType, ClaimType, ConstraintOriginType, FitType,
    HolderKindType, IdentityType, NarrowingKindType, OperationTypeContent,
    ProcessModulusElementType, StatedBorrowedTermType, StatedClaimType,
    StatedConstraintOriginType, StatedDivisibilityType, StatedFitType, StatedHolderType,
    StatedLumpyQuantumType, StatedMagnitudeType, StatedNarrowingType, StatedRemainderType,
    StatedShareType, StatedSummedQuantityType, StatedTimeSlackType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

fn load(name: &str) -> ProcessModulusElementType {
    let path = format!("{}/assets/corpus/{name}", env!("CARGO_MANIFEST_DIR"));
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

    for c in couplings(&doc.stack) {
        for end in [&c.from, &c.to] {
            assert!(
                declared.contains(end.as_str()),
                "{what}: a coupling names undeclared layer {end:?}"
            );
        }
    }
}

/// Every filing in `assets/corpus/`, including the ones inside a composition.
///
/// `load` deserializes a `pm:processModulus` root, so it cannot read a composition at all, and
/// a composition's stack is an ordinary filing that happens to be embedded. Leaving those out
/// would let a corpus check read as coverage while exempting the newest documents, which is
/// `no_example_is_exempt_from_the_namespace_gate`'s argument one layer down. A `party` on a
/// `booked` holder inside `merge-group-composition.xml` would be the kind of defect only this
/// inclusion catches.
fn corpus() -> Vec<(&'static str, ProcessModulusElementType)> {
    let filings = [
        "enterprise-contract.xml",
        "contrato-empresarial.xml",
        "refutation.xml",
        "unstated.xml",
        "merge-us-member.xml",
        "merge-pt-member.xml",
    ];
    let compositions = [
        "merge-group-composition.xml",
        "merge-holding-composition.xml",
    ];

    let mut out: Vec<(&'static str, ProcessModulusElementType)> =
        filings.iter().map(|n| (*n, load(n))).collect();

    for name in compositions {
        let path = format!("{}/assets/corpus/{name}", env!("CARGO_MANIFEST_DIR"));
        let xml = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
        let mut reader = SliceReader::new(&xml);
        let c = CompositionType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{path}: {e}"));
        out.push((name, c.process_modulus));
    }
    out
}

/// The three `Holder` rules XSD 1.0 cannot reach, checked for every holder in every filing.
///
/// `party` and `asOf` belong to `counterparty` and to nothing else, and the trap is a
/// consolidation: a `booked` share in a group filing is booked in some member's books, and
/// naming which one looks exactly like what `party` is for. It is not: on a counterparty
/// holder `party` names whose other books carry the burden; on a booked holder it would name
/// which of the filer's own units records it. Two relations, one field.
///
/// And the half that matters more: a `counterparty` holder must name its party. A burden
/// asserted to sit in another entity's books with no entity named is a guess wearing the one
/// holder kind that promises an instrument.
fn assert_holder_rules(doc: &ProcessModulusElementType, what: &str) {
    for l in &doc.stack.layer {
        let StatedRemainderType::Remainder(r) = &l.remainder else {
            continue;
        };

        let mut seen: Vec<&HolderKindType> = Vec::new();
        for h in &r.holder {
            let StatedHolderType::Holder(h) = h else {
                continue;
            };

            let counterparty = h.kind == HolderKindType::Counterparty;
            assert!(
                counterparty || (h.party.is_none() && h.as_of.is_none()),
                "{what}/{}: a {:?} holder carries party/asOf, which belong only to a \
                 counterparty. Which of the filer's own units books a share is a different \
                 relation from whose other books carry it, and a consolidation already answers the \
                 first by naming the filed layer the share came from",
                l.name,
                h.kind
            );
            if counterparty {
                assert!(
                    h.party.as_deref().is_some_and(|p| !p.trim().is_empty()),
                    "{what}/{}: a counterparty holder does not name its party, so it \
                     asserts an instrument exists in books nobody can identify",
                    l.name
                );
            }

            assert!(
                !seen.contains(&&h.kind),
                "{what}/{}: holder kind {:?} appears twice in one remainder. Two entries \
                 for one kind is not a finer split, it is one share written twice",
                l.name,
                h.kind
            );
            seen.push(&h.kind);
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
fn every_corpus_document_parses_and_its_references_resolve() {
    for name in ["enterprise-contract.xml", "refutation.xml", "unstated.xml"] {
        let doc = load(name);
        assert!(!doc.stack.layer.is_empty(), "{name}: a stack needs a layer");
        assert_layer_references_resolve(&doc, name);
    }
}

#[test]
fn party_and_as_of_belong_to_a_counterparty_and_to_nothing_else() {
    let corpus = corpus();
    for (name, doc) in &corpus {
        assert_holder_rules(doc, name);
    }

    // A per-holder rule over a corpus with no counterparty in it passes without running, and
    // a profile counting rules exercised would score this as covered while nothing was
    // checked.
    let counterparties = corpus
        .iter()
        .flat_map(|(_, d)| &d.stack.layer)
        .filter_map(|l| match &l.remainder {
            StatedRemainderType::Remainder(r) => Some(&r.holder),
            StatedRemainderType::Absent(_) => None,
        })
        .flatten()
        .filter(
            |h| matches!(h, StatedHolderType::Holder(h) if h.kind == HolderKindType::Counterparty),
        )
        .count();
    assert!(
        counterparties > 0,
        "no document in the corpus files a counterparty holder, so the rule above ran \
         against nothing and reported success"
    );
}

/// What a value wrapper files.
///
/// The XSD gives every position that may be computed a wrapper of its own, so the generated types
/// are several of one shape: a claim, a derivation naming what computes it, or a typed absence
/// whose reason is a `ClaimAbsenceReason`. A test reading a claim wants the first; one reading
/// why there is none wants the third.
trait Filed {
    fn filed(&self) -> Option<&ClaimType>;
    fn absence(&self) -> Option<&ClaimAbsenceReasonType>;
}

macro_rules! filed {
    ($($t:ident),*) => {$(
        impl Filed for $t {
            fn filed(&self) -> Option<&ClaimType> {
                match self {
                    $t::Claim(c) => Some(c),
                    _ => None,
                }
            }
            fn absence(&self) -> Option<&ClaimAbsenceReasonType> {
                match self {
                    $t::Absent(a) => Some(&a.reason),
                    _ => None,
                }
            }
        }
    )*};
}

filed!(
    StatedClaimType,
    StatedSummedQuantityType,
    StatedMagnitudeType,
    StatedTimeSlackType,
    StatedShareType
);

/// A three-point claim's bounds, for the rules the schemas state in prose and no
/// XSD 1.0 validator can reach.
fn bounds(c: &impl Filed, what: &str) -> (f64, f64, f64) {
    let Some(c) = c.filed() else {
        panic!("{what}: expected a stated claim, found a derivation or a typed absence");
    };
    (c.low, c.most_likely, c.high)
}

/// The fourth-buffer argument, filed, and sharper than a shape assertion can carry it.
///
/// The magnitude is not the unmeasured thing. A nameplate of 4 against a demand of
/// [4.5, 5.2, 6.0] people already determines it, so `quantity` is `derived`. What no
/// instrument reaches is how much of it the team absorbed, and that is the holder's `share`.
///
/// Filing the whole remainder as `unmeasured` understates the claim. It says nothing is
/// known, where in fact the size is known and the bearer is not, which is the more damaging
/// of the two things to be able to say.
///
/// And the bearer is two things, which a shape assertion here would deny. Asserting a single
/// holder would make the document's own `timeSlack` note unfileable. That note says work
/// queues, waits and quietly ages out, and that the portion which ages out is `unrealised`
/// and not `people`. With a single `people` holder the document would assert the team
/// absorbed all of it and contradict itself in the same layer.
///
/// Both shares are still `unmeasured`, so nothing is invented to make an arithmetic check
/// pass: as `Holder` says, one unstated share suspends the sum rather than breaking it. What
/// the split adds is the admission that the remainder divides. Which half grew is the
/// question an instrument would have to answer.
#[test]
fn the_labour_remainder_is_derived_and_splits_across_two_unmeasured_bearers() {
    let doc = load("enterprise-contract.xml");
    let StatedRemainderType::Remainder(r) = &layer(&doc, "labour").remainder else {
        panic!("the labour layer should carry a remainder");
    };

    let StatedFitType::Fit(sign) = &r.sign else {
        panic!("this fit is `interference`, not `transition`: the demand range does not overlap the nameplate");
    };
    assert_eq!(*sign, FitType::Interference);

    let kinds: Vec<&HolderKindType> = r
        .holder
        .iter()
        .filter_map(|h| match h {
            StatedHolderType::Holder(h) => Some(&h.kind),
            _ => None,
        })
        .collect();
    assert!(
        kinds.contains(&&HolderKindType::People) && kinds.contains(&&HolderKindType::Unrealised),
        "labour bears its excess two ways: absorbed by the team and aged out of the queue. \
         Its own `timeSlack` note says the portion that ages out is `unrealised` and not \
         `people`, so a list naming only one of them contradicts the same layer. Found {kinds:?}"
    );

    for h in &r.holder {
        let StatedHolderType::Holder(h) = h else {
            continue;
        };
        let StatedShareType::Absent(share) = &h.share else {
            panic!(
                "the `{:?}` share is the thing with no instrument behind it, and a figure \
                 here would be one somebody invented to split a total nobody measured",
                h.kind
            );
        };
        assert_eq!(
            share.reason,
            ClaimAbsenceReasonType::Unmeasured,
            "`unmeasured` is the claim on the `{:?}` share. `none` would assert somebody \
             looked and found zero",
            h.kind
        );
    }

    let StatedMagnitudeType::Derivation(q) = &r.quantity else {
        panic!("demand and nameplate are both stated, so a carried total duplicates them");
    };
    assert_eq!(
        q.identity,
        IdentityType::Magnitude,
        "the receiver computes it; a stored copy can disagree with its own inputs"
    );
}

/// Two holders on one remainder, which is the shape a single holder could not carry.
///
/// `Fit` names both `customer` and `unrealised` for an unserved excess, because a
/// customer who waited and one who never arrived are different people and only one of
/// them is still yours. A single slot makes the sender pick one and discard the other, and
/// the discarded half is often the one somebody wanted.
///
/// It also exercises the sum rule, which XSD 1.0 cannot express: the stated shares add up
/// to the remainder's magnitude.
#[test]
fn an_unserved_excess_splits_across_two_holders_that_sum_to_the_magnitude() {
    let doc = load("enterprise-contract.xml");
    let l = layer(&doc, "capability");
    let StatedRemainderType::Remainder(r) = &l.remainder else {
        panic!("the capability layer should carry a remainder");
    };

    let StatedFitType::Fit(sign) = &r.sign else {
        panic!("this fit is `interference`, not `transition`: the demand range does not overlap the nameplate");
    };
    assert_eq!(*sign, FitType::Interference);

    let [StatedHolderType::Holder(a), StatedHolderType::Holder(b)] = &r.holder[..] else {
        panic!("capability splits across exactly two named holders");
    };
    assert_eq!(a.kind, HolderKindType::Customer, "the ones who waited");
    assert_eq!(
        b.kind,
        HolderKindType::Unrealised,
        "the ones who never arrived"
    );

    let (dl, dm, dh) = bounds(&l.demand.amount, "capability demand");
    let (nl, nm, nh) = bounds(&l.supply.nameplate.amount, "capability nameplate");

    // Valid only because this fit is determinate: the whole demand range sits above the
    // nameplate, so the remainder never crosses zero and taking its magnitude only flips
    // its sign. A straddling range has no single sign, and this arithmetic would be
    // meaningless there. See the compute layer of refutation.xml, which straddles.
    assert!(
        dl > nh,
        "capability demand exceeds its nameplate throughout"
    );
    let magnitude = ((nh - dl).abs(), (nm - dm).abs(), (nl - dh).abs());

    let (al, am, ah) = bounds(&a.share, "the customer share");
    let (bl, bm, bh) = bounds(&b.share, "the unrealised share");
    let summed = (al + bl, am + bm, ah + bh);

    assert_eq!(
        summed, magnitude,
        "the shares divide the remainder, so they must add back up to it"
    );
}

/// The framework a regime actually names, for the examples that state one.
///
/// Every example here names its framework. The wrapper exists for senders who
/// cannot yet, and a test that silently tolerated `absent` would stop checking the
/// thing it is here to check.
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

    let Some(q) = continuous(l) else {
        panic!("object storage is bought continuously in this example, and states so");
    };
    // The zero premium is the counter-example, and it is a claim. `Continuity` reads
    // above 0, at 0 or below 0, and the middle is a claim of zero rather than
    // `absent/reason = none`. Spelled as an absence while the ends stay claims, the
    // three-point scale would stop being comparable as arithmetic.
    let StatedClaimType::Claim(premium) = &q.premium else {
        panic!("the premium should be stated, and a zero premium is a claim of zero");
    };
    assert_eq!(
        (premium.low, premium.most_likely, premium.high),
        (0.0, 0.0, 0.0),
        "a zero premium is the counter-example; `unmeasured` would only be a gap"
    );

    let StatedRemainderType::Absent(r) = &l.remainder else {
        panic!("this layer states no nameplate, so it can carry no remainder");
    };
    // `notApplicable` and not `none`. With no nameplate there is nothing to take the demand
    // from, so the question is malformed rather than answered with nothing, and `none` is
    // not spellable on a `StatedRemainder` anyway, because a remainder of zero is a filed
    // clearance.
    assert_eq!(r.reason, ClaimAbsenceReasonType::NotApplicable);
}

/// The falsifier is expressible, and it carries its evidence.
#[test]
fn a_coupling_is_filable_and_states_what_was_observed() {
    let doc = load("refutation.xml");
    let c = couplings(&doc.stack)
        .first()
        .copied()
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
        .filter_map(|l| lumpy(l).map(|q| (l.name.as_str(), q.origin.clone())))
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

/// Two authorities describing one entity, and de-duplicating them would destroy a
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
        "two regimes citing the same authority would be a genuine duplicate; two \
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

/// A regime is a declaration, so the schema does not make it plural by accident:
/// a document reporting under one framework says so once.
#[test]
fn a_single_regime_is_the_ordinary_case() {
    let doc = load("enterprise-contract.xml");
    assert_eq!(doc.regime.len(), 1);
    assert_eq!(stated_framework(&doc.regime[0]).value, "us-gaap");
}

// ==========================================================================
// What a sender may decline.
//
// Each of these is a state a real adopter needs, and without its typed reason
// the only way to file it is a workaround that asserts something the adopter
// does not believe. A test that only showed the documents parse would not show
// the distinction is reachable, so every one below reads the reason back out.
// ==========================================================================

/// The pair that would otherwise share one encoding: "reports under something,
/// unnamed" and "reports under none" are different documents, and the difference
/// is readable rather than inferred from an omission.
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
        "a sender who has a framework but cannot name it must be able to say so"
    );
    assert!(
        reasons.contains(&AbsenceReasonType::None),
        "a sender who reports under no framework must be distinguishable from one \
         who simply omitted the regime, or the two read as one"
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

/// The state that would otherwise be unsayable. A tier nobody has assigned picks no
/// framework, and the framework picks the chart, so there will be a chart and nobody
/// has said which. Without the wrapper the only encodings would be "this entity has no
/// chart", which is false, or an invented taxonomy URI.
///
/// `none` would be the wrong reason here, and the test says so: `none` is a claim that
/// somebody looked and there is none.
#[test]
fn a_regime_can_decline_its_chart_without_claiming_it_has_none() {
    let doc = load("unstated.xml");
    let r1 = &regime(&doc, "r1").chart;
    match r1 {
        StatedBorrowedTermType::Absent(a) => assert_eq!(
            a.reason,
            AbsenceReasonType::Unmeasured,
            "the tier is unassigned, so the chart is unnamed rather than absent"
        ),
        StatedBorrowedTermType::Term(_) => {
            panic!("r1 is expected to decline the chart its unnamed framework selects")
        }
    }
}

/// There is no United States chart of accounts. What is published there is a reporting
/// taxonomy, the concepts a filing is tagged with, and every filer's chart of accounts is
/// their own and unpublished. The filer is genuinely the authority for it, so naming
/// themselves satisfies BorrowedTerm rather than evading it.
///
/// The test is that the chart is not the framework's taxonomy, because filing
/// `http://fasb.org/us-gaap` as a chart is the category error the annotation exists to
/// catch: it declares a chart nobody posts to.
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

/// The chart is a separate axis from the framework, and this is the document that shows it
/// rather than asserting it: two regimes, two authorities' codings of one framework (`NC-ME`
/// to IES and `M` to SAF-T), and one chart between them, because a chart is national and the
/// authority that codes the framework is not.
///
/// If these two collapse to one taxonomy, the claim that they are separate axes is lost.
#[test]
fn two_codings_of_one_framework_share_one_chart() {
    let doc = load("refutation.xml");
    let (a, b) = (
        regime(&doc, "ies-anexo-asnc"),
        regime(&doc, "saft-referencial"),
    );

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

/// `notApplicable` is not a kind of divisibility; it is the absence of one. Without it,
/// the workaround would assert `continuous` and deny it one level down, where no query
/// would meet the denial.
#[test]
fn a_subject_that_is_not_a_supply_can_decline_the_divisibility_axis() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedDivisibilityType::Absent(a) = &l.supply.nameplate.divisibility else {
        panic!("a margin ratio is neither lumpy nor continuous");
    };
    assert_eq!(a.reason, AbsenceReasonType::NotApplicable);
}

/// A required value a sender can still decline, and the fact new senders most often have
/// not established.
///
/// `unmeasured` and a claim of zero are different documents here, which a boolean cannot
/// say. A claim of zero says somebody looked and there is no room above the rating;
/// `unmeasured` says nobody has established how much room there is. A `true` would mean both
/// at once, and a reader could not tell which.
#[test]
fn a_capacity_slack_can_be_left_unmeasured_instead_of_guessed() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedClaimType::Absent(a) = &l.supply.nameplate.capacity_slack else {
        panic!("this example has not established how far this supply can run above rating");
    };
    assert_eq!(a.reason, ClaimAbsenceReasonType::Unmeasured);
}

/// Three parties that a single string would flatten into one are separately joinable here,
/// and `standing` is where `unverified` belongs: on the assertion, and never as another
/// absence reason.
#[test]
fn provenance_separates_the_three_parties_and_carries_standing() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedSummedQuantityType::Claim(c) = &l.demand.amount else {
        panic!("this example states its demand");
    };
    let p = c
        .provenance
        .as_ref()
        .expect("the demand carries its provenance");

    assert_eq!(p.party.as_deref(), Some("finance"));
    assert_eq!(p.entered_by.as_deref(), Some("analyst-04"));
    assert_eq!(p.approved_by.as_deref(), Some("controller-01"));

    let StatedBorrowedTermType::Term(standing) = &*p.standing else {
        panic!("this example files a standing rather than declining one")
    };
    assert_eq!(standing.value, "reviewed-not-verified");
    assert!(
        !standing.taxonomy.is_empty(),
        "standing is a BorrowedTerm because this model does not own the set"
    );
}

/// What bounds a range is a different question from what would narrow it, and a sender
/// with both facts can file both.
///
/// And `narrowsWhen` does not answer `is_some()`. As an optional bare string its absence
/// would mean "nobody said" and "nothing would narrow this" and "there is no range to
/// narrow" all at once: the boolean anti-pattern, in the one field carrying the model's
/// falsifiability claim. It is a required `StatedNarrowing`, so the question this test asks
/// is not "is it there" but what it says.
///
/// The `kind` is where the fact lives. `instrument` means the width is ignorance and a
/// better measurement reveals it; `intervention` means the width is variation and only
/// changing the process reduces it; `experiment` means the filer does not know which and
/// is naming what would settle it.
#[test]
fn a_claim_can_carry_both_what_bounds_it_and_what_would_narrow_it() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedSummedQuantityType::Claim(c) = &l.demand.amount else {
        panic!("this example states its demand");
    };
    let StatedConstraintOriginType::Origin(o) = &c.bound_origin else {
        panic!("this example names who owns the edge of its margin range")
    };
    assert_eq!(*o, ConstraintOriginType::Policy);

    let StatedNarrowingType::Narrowing(n) = &c.narrows_when else {
        panic!(
            "this claim names what would narrow it; an absence here would be the other \
             fact, that nothing would"
        );
    };
    assert!(
        !n.condition.trim().is_empty(),
        "a narrowing with no condition states nothing"
    );
    assert_eq!(
        n.kind,
        NarrowingKindType::Instrument,
        "closing the quarter and landing actual cost is a measurement arriving, so this \
         range is ignorance rather than variation"
    );
}

/// The couplings a stack filed, or an empty slice where it filed a typed reason instead.
///
/// The empty slice and `absent/reason = none` are not the same document, and no caller may
/// treat them as one. As a bare `minOccurs="0" maxOccurs="unbounded"`, `Stack/couplings` would
/// make a stack tested for independence and a stack nobody looked at byte-identical, which is
/// the boolean anti-pattern wearing a plural. Use `coupling_absence` when the question is
/// which.
///
/// The XSD guarantee is not visible in the type. The choice is "one or more couplings, or one
/// absence", and the generator flattens that to a `Vec` that could in principle hold both.
/// XSD refuses such a document; this helper simply reads the arm that is there, the same way
/// `lumpy` and `continuous` do for `Divisibility`.
fn couplings(s: &pm::StackType) -> Vec<&pm::CouplingType> {
    s.couplings
        .content
        .iter()
        .filter_map(|c| match c {
            pm::StatedCouplingsTypeContent::Coupling(k) => Some(k),
            pm::StatedCouplingsTypeContent::Absent(_) => None,
        })
        .collect()
}

/// The typed reason a stack filed no couplings, if that is what it filed.
fn coupling_absence(s: &pm::StackType) -> Option<&pm::AbsenceType> {
    s.couplings.content.iter().find_map(|c| match c {
        pm::StatedCouplingsTypeContent::Absent(a) => Some(a),
        pm::StatedCouplingsTypeContent::Coupling(_) => None,
    })
}

/// A claim's bounds and unit, when it is stated.
fn stated(c: &impl Filed) -> Option<(f64, f64, f64, &str)> {
    c.filed().map(|c| (c.low, c.most_likely, c.high, c.unit.as_str()))
}

/// The `lumpy` arm of a divisibility, ignoring any `window` beside it.
///
/// `Divisibility` is a sequence, the `lumpy | continuous` choice and then the `window`, and the
/// generated Rust flattens that to a `Vec<DivisibilityTypeContent>`. So the XSD's guarantee of
/// exactly one amount arm is not visible in the type, and these three helpers put it back
/// rather than letting every call site rediscover it.
fn lumpy(l: &pm::LayerType) -> Option<&pm::LumpyQuantumType> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        pm::DivisibilityTypeContent::Lumpy(q) => Some(q),
        _ => None,
    })
}

/// The `continuous` arm of a divisibility, if that is the one filed.
fn continuous(l: &pm::LayerType) -> Option<&pm::ContinuityType> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        pm::DivisibilityTypeContent::Continuous(q) => Some(q),
        _ => None,
    })
}

/// The `window` beside the amount axis: the part of each period the supply exists in.
fn window(l: &pm::LayerType) -> Option<&pm::LumpyQuantumType> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        pm::DivisibilityTypeContent::Window(StatedLumpyQuantumType::Quantum(w)) => Some(w),
        _ => None,
    })
}

/// The typed reason a layer files no window, if that is what it files.
///
/// The two halves are asked separately on purpose. `window` above answers "how much of each
/// period is this supply live for"; this answers "and if you did not say, why not", and the
/// reasons are not interchangeable. `notApplicable` is a unit with no denominator;
/// `unmeasured` is the one state that leaves a derived `timeSlack` unjustified.
///
/// There is no other reason. "The supply runs continuously" is a value and not an absence: a
/// duty fraction of one, with an origin saying who could change it. It is filed as one whole
/// period, and the absence arm is a `ClaimAbsence`, so `none` cannot spell it.
fn window_absence(l: &pm::LayerType) -> Option<&pm::ClaimAbsenceType> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        pm::DivisibilityTypeContent::Window(StatedLumpyQuantumType::Absent(a)) => Some(a),
        _ => None,
    })
}

/// Whether the supply is live for the whole of its period, which is a duty fraction of one.
///
/// A whole period is quoted as `1` in the period's own unit, and that is what makes this
/// readable without converting anything: `1 week` against a period of `week` is a duty
/// fraction you can see, and `5 days` against the same period is a proper part. The same
/// test is `assets/sqlc/layers/derivation_licensed.sqlc`, which does no unit arithmetic
/// either, on purpose: `window_not_applicable_on_a_rate` says why a rule here never guesses
/// at units.
fn runs_the_whole_period(l: &pm::LayerType) -> bool {
    let Some(w) = window(l) else { return false };
    let StatedClaimType::Claim(size) = &w.size else {
        return false;
    };
    let StatedSummedQuantityType::Claim(amount) = &l.supply.nameplate.amount else {
        return false;
    };
    let pm::StatedDenominatorType::Period(p) = &amount.denominator else {
        return false;
    };
    size.low == 1.0 && size.high == 1.0 && size.unit == *p
}

/// The lumpy quantum of a layer's supply, if it has one and it is stated.
fn quantum(l: &pm::LayerType) -> Option<(f64, f64, f64, &str)> {
    stated(&lumpy(l)?.size)
}

/// A quantum is in the unit of the nameplate it divides.
///
/// `conformance/README.md` states the rule. Read the other way, a `capability` layer whose
/// demand is in `launches per quarter` would file a quantum of `launches`.
///
/// That reading is not a style preference, it is wrong. A quantum exists so that the
/// nameplate and the demand each come to a count of whole units. Launches per quarter divided
/// by launches is a frequency, and the split it feeds means nothing. The lump on a rate is a
/// lump of the rate: one launch slot per quarter, not one launch.
///
/// It computes anyway when the size is 1. That is the whole hazard: a unit error that is
/// invisible in the numbers until somebody files a quantum larger than one.
#[test]
fn a_quantum_is_expressed_in_the_unit_of_the_supply_it_divides() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let (Some((_, _, _, du)), Some((_, _, _, qu))) = (stated(&l.demand.amount), quantum(l)) else {
                continue;
            };
            assert_eq!(
                qu, du,
                "{name} `{}`: a quantum of `{qu}` against a demand of `{du}` cannot be \
                 divided into it. If the supply really comes in a different unit from the \
                 demand, that is a conversion and it belongs to whoever composes them",
                l.name
            );
            checked += 1;
        }
    }
    assert!(
        checked >= 8,
        "only {checked} lumpy layers were reachable; this rule scores as covered whether \
         or not anything ran, so the count is the guard"
    );
}

/// The remainder is exact, and its two halves, whole units and residue, are not `Claim`s.
///
/// However the nameplate and the demand are filed, ranges or points, the whole units and the
/// residue put back together give the nameplate less the demand exactly. The first half of
/// this test checks that on every lumpy layer, the long way round.
///
/// What is fragile is the split, and in a large share of this corpus rather than at some
/// exotic edge. The residue starts again from zero at every whole quantum, so a demand range
/// that crosses one need not give ordered residues at its three points, while a range that
/// stays between two whole quanta always does. `refutation.xml#compute` files a demand of
/// `(11, 13.2, 16.4)` against a quantum of 8 and crosses 16, so the residue at its high comes
/// out below the residue at its mode. A residue like that breaks the first rule in the
/// conformance table, that a range runs in order, while the demand that gave it is perfectly
/// well formed.
///
/// And the schema is safe already. `Remainder` carries `quantity`, `sign`, `absorber` and
/// `holder`: the total, never the two halves, and `conformance/README.md` says the split is
/// the receiver's to work out and is never filed.
#[test]
fn the_decomposition_is_an_identity_and_its_two_halves_are_not_claims() {
    let mut checked = 0;
    let mut crossing: Vec<String> = Vec::new();

    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let (Some((dl, dm, dh, _)), Some((ql, qm, qh, _))) = (stated(&l.demand.amount), quantum(l))
            else {
                continue;
            };
            let Some((nl, nm, nh, _)) = stated(&l.supply.nameplate.amount) else {
                continue;
            };
            assert_eq!(
                (ql, qh),
                (qm, qm),
                "{name} `{}`: with a quantum that is a range, how many whole units the demand \
                 holds is genuinely ambiguous, and no document here files that case",
                l.name
            );

            // The long way round: build the whole units and the residue, put them back
            // together, and hold the result to the nameplate less the demand.
            for (n, d) in [(nl, dl), (nm, dm), (nh, dh)] {
                let residue = d - (d / qm).floor() * qm;
                let m = n / qm - (d / qm).floor();
                assert!(
                    ((m * qm - residue) - (n - d)).abs() < 1e-9,
                    "{name} `{}`: the whole units less the residue must equal the nameplate \
                     less the demand exactly, and at nameplate {n}, demand {d}, quantum {qm} \
                     they do not",
                    l.name
                );
            }

            let r = |d: f64| d - (d / qm).floor() * qm;
            let (rl, rm, rh) = (r(dl), r(dm), r(dh));
            if (dl / qm).floor() != (dh / qm).floor() {
                crossing.push(format!(
                    "{name}#{} residues ({:.4}, {:.4}, {:.4})",
                    l.name, rl, rm, rh
                ));
            } else {
                assert!(
                    rl <= rm && rm <= rh,
                    "{name} `{}`: a demand range between two whole quanta of {qm} gave \
                     residues ({rl}, {rm}, {rh}), which must be in order",
                    l.name
                );
            }
            checked += 1;
        }
    }

    assert!(
        checked >= 15,
        "only {checked} lumpy layers were reachable; a rule with nothing to check passes \
         loudest"
    );
    // A share, not a handful, and the share is the argument. A rule broken by one exotic
    // document is an outlier; one that a third of the corpus crosses is a rule nobody can follow.
    assert!(
        crossing.len() * 3 >= checked,
        "a demand range crossing a whole quantum is supposed to be common, which is what stops \
         anyone treating the split as generally available. Only {} of {checked}:\n  {}",
        crossing.len(),
        crossing.join("\n  ")
    );
}

/// The slack of the buffer a remainder's `absorber` names, if that buffer has one sized.
///
/// The unit is returned and must not be dropped. `.map(|(lo, ml, hi, _)| ...)` discards it
/// on the last field, which makes the bound below a comparison between two bare floats, and
/// that comparison is legitimate only because both sides are in the layer's unit. See
/// `a_slack_is_expressed_in_the_unit_of_the_shares_it_bounds`.
fn absorber_slack(l: &pm::LayerType) -> Option<(f64, f64, f64, &str)> {
    let StatedRemainderType::Remainder(r) = &l.remainder else {
        return None;
    };
    let StatedBorrowedTermType::Term(t) = &r.absorber else {
        return None;
    };
    match t.value.as_str() {
        "capacity" => stated(&l.supply.nameplate.capacity_slack),
        "inventory" => stated(&l.supply.nameplate.inventory_slack),
        "time" => stated(&l.time_slack),
        _ => None,
    }
}

/// What a claim files under its line, in words, for a failure message.
///
/// The three arms are three different answers, and only one of them is a period. `each` is a
/// denominator that exists and is not a period, as in `GPU-hour per GPU`, which is the
/// distinction a string test over the unit token cannot make.
fn denominator_says(d: &pm::StatedDenominatorType) -> String {
    match d {
        pm::StatedDenominatorType::Period(p) => format!("the period `{p}`"),
        pm::StatedDenominatorType::Each(e) => format!("`each {e}`, which is not a period"),
        pm::StatedDenominatorType::Absent(a) => format!("no denominator ({:?})", a.reason),
    }
}

/// A window is a note on the unit's denominator, so the unit must have one.
///
/// The denominator supplies the period, the window supplies the live part of it, and the ratio
/// is the duty fraction: `3 hours` against `2160 muffins per day` is three hours of one day. So
/// the denominator rule is its precondition rather than a separate convention: the
/// denominator must cover a whole period so that the window has something to be a fraction of.
///
/// So a window on a stock is malformed, not merely unmeasured. `12 people` has no period, so
/// "5 days" has nothing to be five days of, and `GPU-hour` carries its hour in the numerator:
/// it is a quantity of resource-time, not a rate. That is why this element is rare rather than
/// under-used: few nameplate units in this corpus have a period under the line.
///
/// The model answers this and a string test cannot. A unit is an `xs:token`, and without
/// `pm:StatedDenominator` nothing in the model would tell a rate from a stock. Reading the
/// token for a `per` or `por` word is the `LIKE '% per %'` the SQL side refuses: it misses
/// `muffins/day`, misses a third language, and counts `GPU-hour per GPU` as a period when the
/// arm that document files is `each`, explicitly not a period. The schema forbids the read in
/// as many words: a unit is an `xs:token`, and nothing may read inside it.
#[test]
fn a_window_requires_a_unit_with_a_period_to_be_a_fraction_of() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            if window(l).is_none() {
                continue;
            }
            let StatedSummedQuantityType::Claim(amount) = &l.supply.nameplate.amount else {
                panic!(
                    "{name} `{}`: a window on a nameplate with no stated amount",
                    l.name
                );
            };
            assert!(
                matches!(&amount.denominator, pm::StatedDenominatorType::Period(_)),
                "{name} `{}`: a window is filed against a nameplate in `{}`, which files {}. A \
                 window is the live part of a period, so a unit with no period under the line \
                 gives it nothing to be a fraction of: a stock has no period to be live in",
                l.name,
                amount.unit,
                denominator_says(&amount.denominator),
            );
            checked += 1;
        }
    }
    assert!(
        checked >= 3,
        "only {checked} windows were reachable; a rule about how they are filed passes loudest \
         when nothing is filed"
    );
}

/// A window is a property of the machine, so it is carried through a fusion and never summed.
/// This is the rule that separates the time axis from every quantity beside it.
///
/// Demand sums: two members asking for the same line want more line. A window does not, and the
/// reason is not a convention: both members name the same machine, and a line staffed weekdays
/// by two customers is still staffed weekdays. Summing would say ten days a week.
///
/// It is the nameplate's case arriving by another route. The group eliminates the duplicated
/// nameplate for exactly this reason (two members, one machine) and files the elimination. A
/// window needs no elimination because it never sums: it is a property, not a quantity, which
/// is why `EliminationAgainst` has three members and, on purpose, no fourth.
///
/// The two members file it in different languages, `days` and `dias`, so the check is on the
/// figure. Two parties describing one machine is the case this corpus exists for.
///
/// And a window of one whole period is skipped, which is not an exemption but the rule's own
/// scope. This check compares figures across documents because, in this corpus, a calendar
/// that carves a period up belongs to exactly one machine: the shared packing line, filed in
/// two languages. A duty fraction of one carves nothing. It says "always on", every document
/// that files it says the same thing, and there is no calendar to lose in a fusion, so
/// including them would compare a support desk against a packing line and call the
/// disagreement a defect. The narrowness is a choice and has to be visible as one: spelled as
/// `absent/reason = none`, "always on" would give `window()` nothing, and the same scope would
/// arrive free with nothing to show that anybody chose it.
#[test]
fn a_window_is_carried_through_a_fusion_and_never_summed() {
    let mut sizes: Vec<(String, f64)> = Vec::new();
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            if runs_the_whole_period(l) {
                continue;
            }
            if let Some(w) = window(l) {
                let (_, ml, _, _) = stated(&w.size)
                    .unwrap_or_else(|| panic!("{name} `{}`: a window with no size", l.name));
                sizes.push((format!("{name}#{}", l.name), ml));
            }
        }
    }

    assert!(
        sizes.len() >= 3,
        "only {} windows were filed; the carry-not-sum rule needs the parts and the fused \
         layer to be checking anything at all",
        sizes.len()
    );

    let first = sizes[0].1;
    for (where_, ml) in &sizes {
        assert_eq!(
            *ml, first,
            "{where_} files a window of {ml} where the rest of the corpus files {first}. One \
             machine has one calendar: if this is a genuinely different machine it needs a \
             different layer, and if it is the same one the figures cannot disagree"
        );
    }

    // The mistake this rule exists for. A fused window equal to the sum of its parts is what
    // a reader who has just learned how `demand` composes will write.
    let parts: f64 = sizes
        .iter()
        .filter(|(w, _)| w.contains("member"))
        .map(|(_, m)| m)
        .sum();
    let fused = sizes
        .iter()
        .find(|(w, _)| w.contains("composition"))
        .map(|(_, m)| *m)
        .expect("the fused layer must file the window too, or nothing tests the carry");
    assert!(
        fused < parts,
        "the fused window ({fused}) equals or exceeds the sum of its parts ({parts}), which is \
         what summing a calendar looks like. Two members sharing one line do not get a longer week"
    );
}

/// A sized slack says who set it, as every other constraint in this model does.
///
/// `Nameplate/amountOrigin` says who can hold a different number of units. `LumpyQuantum/origin`
/// says who sets the size of one. Without its origin a slack would say how much room a buffer
/// has and nothing whatever about whether anybody could move it.
///
/// The case that needs it is an SLA. Two layers can file the same `timeSlack` and mean
/// opposite things: one is how long queued work physically keeps, the other is how long a
/// contract says the customer waits. The first is not a lever and the second is a negotiation,
/// and no reader can tell them apart from the number. The corpus files both kinds, so the
/// distinction is visible rather than asserted.
#[test]
fn a_sized_slack_says_who_can_move_it() {
    let mut origins = Vec::new();
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            for (what, c) in [
                ("capacitySlack", l.supply.nameplate.capacity_slack.filed()),
                ("inventorySlack", l.supply.nameplate.inventory_slack.filed()),
                ("timeSlack", l.time_slack.filed()),
            ] {
                let Some(claim) = c else {
                    continue; // an unsized slack constrains nothing, so it sets nothing
                };
                let StatedConstraintOriginType::Origin(origin) = &claim.bound_origin else {
                    panic!(
                        "{name} `{}`: {what} is sized at {} but does not say who set it. A \
                         shelf life is `intrinsic` and not a lever; an SLA is `contractual` \
                         and is one. The number alone cannot tell a reader which",
                        l.name, claim.most_likely
                    )
                };
                origins.push(format!("{:?}", origin));
            }
        }
    }

    assert!(
        origins.len() >= 2,
        "only {} sized slacks were reachable; a rule about how they are filed passes loudest \
         when nothing is filed",
        origins.len()
    );
    // One origin across every slack would mean the field is decoration. The point is that
    // a negotiable slack and a physical one look identical without it, so the corpus has to
    // hold both to be evidence of anything.
    origins.sort();
    origins.dedup();
    assert!(
        origins.len() >= 2,
        "every sized slack in the corpus has the same origin ({}), so nothing here shows the \
         distinction doing work",
        origins.join(", ")
    );
}

/// A slack is compared against holder shares, so it must be in the shares' unit.
///
/// The rule that the shares stay within the slack is arithmetic between two claims, and
/// arithmetic between two claims means something only when they measure the same thing.
/// `Claim` says so itself: a unit is not a conversion licence, and two claims in different
/// units do not combine. This holds the slack to it for the one comparison the three slacks
/// exist to make, as `a_quantum_is_expressed_in_the_unit_of_the_supply_it_divides` holds the
/// quantum.
///
/// And it catches less than it looks as if it does, which is worth saying before anybody
/// counts it as coverage. A buffer's size is naturally measured as a duration (how long work
/// sits, how long before a caller leaves) while this field takes a quantity, so the filer owes
/// a conversion from the duration to a quantity at the rate work arrives. A filer who skips
/// it and writes the right unit on the unconverted number passes this test cleanly. It
/// catches a mislabelled quantity and never a relabelled one; only the arithmetic catches that.
#[test]
fn a_slack_is_expressed_in_the_unit_of_the_shares_it_bounds() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            let Some((_, _, _, slack_unit)) = absorber_slack(l) else {
                continue; // unmeasured or none: nothing to be in the wrong unit
            };
            for h in &r.holder {
                let StatedHolderType::Holder(h) = h else {
                    continue;
                };
                let Some((_, _, _, share_unit)) = stated(&h.share) else {
                    continue;
                };
                assert_eq!(
                    slack_unit, share_unit,
                    "{name} `{}`: the `{:?}` share is in `{share_unit}` and the slack that \
                     bounds it is in `{slack_unit}`. One of them is measuring something the \
                     other is not, and the bound between them is arithmetic on two different \
                     quantities",
                    l.name, h.kind
                );
                checked += 1;
            }
        }
    }

    // The same trap as the bound itself: with every slack `unmeasured`, this compares nothing.
    assert!(
        checked >= 2,
        "only {checked} share/slack pairs were reachable; a unit rule with nothing to compare \
         passes loudest"
    );
}

/// A holder's share must not exceed the slack of the buffer its absorber names.
///
/// This rule needs the three availability conditions as quantities; as booleans it could not
/// be written. A boolean says a buffer is available; it cannot say available, barely. On a
/// conveyor at a hundred slots an hour carrying ninety-five muffins, five slots an hour are
/// free and that is the whole of the buffer, and a sender attributing fifty muffins an hour
/// to it could still file `true`, quite honestly. A boolean catches a contradiction and never
/// an attribution.
///
/// The slack is a quantity in the layer's unit: five muffins an hour. "About twelve minutes"
/// describes the same belt as a duration, the conversion `Layer/timeSlack` warns about, and
/// the bound below cannot use it.
///
/// The bound is on the interference side only, and `capacitySlack`'s annotation says why:
/// spare capacity under a clearance fit is the unused part of a rating, which the remainder
/// already carries. A slack is the room at the other end (above the nameplate, in the
/// stockroom, in the queue), which is what a buffer draws on when demand exceeds supply.
///
/// And the unserved pair is exempt, not `unrealised` alone. Both name demand nobody met:
/// overflow, not a load the buffer held. Exempting only one of the two would sum a
/// customer's borne degradation into the buffer's load.
///
/// So this rule examines nothing in this corpus, and that is a finding about the evidence
/// rather than a gap in it. On every interference layer that sizes its absorbing buffer,
/// every holder is `customer` or `unrealised`: nothing was absorbed at all, the demand was
/// turned away. The left side of the bound is empty because no share was served, which is
/// the model's own subject stated by the data. `entries/borne.sqlc` traces the same emptiness
/// stage by stage, and `algebra/borne.sqlc` prints it every run, per layer, rather than as a
/// count in a comment.
///
/// Read at both ends, as `checks/share_exceeds_slack.sqlc` reads it: the share breaks the bound
/// only when the whole of it is above the whole slack, its lowest point above the slack's
/// highest. Where the two ranges overlap, the document does not settle it.
#[test]
fn a_share_does_not_exceed_the_slack_of_the_buffer_that_absorbed_it() {
    let mut candidates = 0;
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            // Only an interference side draws on a slack; clearance is spare, not overflow.
            // `transition` is excluded, and its overflow is still bounded:
            // `exposure_unaccounted` derives the exposure from the layer's own demand and
            // nameplate and bounds it against the unserved shares, which is the comparison a
            // transition admits. What this rule reads is the holder shares, and under a
            // transition those carry the clearance magnitude, the larger side and the one a
            // filer can count. Bounding it by the absorbing slack would compare opposite
            // edges of one buffer.
            if !matches!(&r.sign, StatedFitType::Fit(FitType::Interference)) {
                continue;
            }
            let Some((_, _, slack, _)) = absorber_slack(l) else {
                continue; // unmeasured or none-with-no-figure: the check suspends
            };
            candidates += 1;

            // The split into two classes, asserted here because the exemption below rests on
            // it. `booked`, `counterparty` and `people` name somebody who absorbed; `customer`
            // and `unrealised` name demand nobody met. Between them the two classes must cover
            // the stated shares. If they stop doing so, a share is dropped by both, and the
            // empty left side below stops being a finding and becomes an artefact nobody can
            // see. algebra/borne.sqlc asserts the same over the same two relations.
            let stated_shares = |unserved_class: bool| -> Vec<f64> {
                r.holder
                    .iter()
                    .filter_map(|h| match h {
                        StatedHolderType::Holder(h)
                            if matches!(
                                h.kind,
                                HolderKindType::Unrealised | HolderKindType::Customer
                            ) == unserved_class =>
                        {
                            stated(&h.share).map(|(_, ml, _, _)| ml)
                        }
                        _ => None,
                    })
                    .collect()
            };
            let held: f64 = r
                .holder
                .iter()
                .filter_map(|h| match h {
                    StatedHolderType::Holder(h) => stated(&h.share).map(|(_, ml, _, _)| ml),
                    _ => None,
                })
                .sum();
            let unserved: f64 = stated_shares(true).iter().sum();

            // The unserved pair is exempt, not `unrealised` alone. Both name demand nobody
            // met, overflow, not a load the buffer held, and `Fit` calls the same pair a
            // violation under a clearance. Exempting only one of the two would sum a
            // customer's borne degradation into the buffer's load.
            let absorbed = stated_shares(false);
            let borne: f64 = absorbed.iter().sum();
            assert!(
                (held - borne - unserved).abs() < 1e-9,
                "{name} `{}`: {held} held is not {borne} absorbed + {unserved} unserved. The \
                 two holder classes do not cover the stated shares between them",
                l.name
            );
            if absorbed.is_empty() {
                continue; // nothing was attributed to the buffer: no bound to test
            }
            // The lowest the absorbed shares can be, against the most the slack can hold.
            let borne_low: f64 = r
                .holder
                .iter()
                .filter_map(|h| match h {
                    StatedHolderType::Holder(h)
                        if !matches!(
                            h.kind,
                            HolderKindType::Unrealised | HolderKindType::Customer
                        ) =>
                    {
                        stated(&h.share).map(|(low, _, _, _)| low)
                    }
                    _ => None,
                })
                .sum();

            assert!(
                borne_low <= slack + 1e-9,
                "{name} `{}`: at least {borne_low} is attributed to the `{}` buffer, whose slack \
                 is at most {slack}. A buffer cannot absorb more than it holds, and the excess is \
                 `unrealised`, demand that overflowed every buffer, not a bigger buffer",
                l.name,
                match &r.absorber {
                    StatedBorrowedTermType::Term(t) => t.value.as_str(),
                    StatedBorrowedTermType::Absent(_) => "?",
                }
            );
            checked += 1;
        }
    }

    // The guard is on the population that can go silent. A corpus whose slacks are all
    // `unmeasured` lets this rule pass by checking nothing, and score as covered.
    //
    // It guards the candidates and not `checked`, because with the unserved pair exempt
    // `checked` is empty here on purpose: every candidate is removed by the exemption, not by
    // a filter that matched nothing. Demanding otherwise would demand a document the model
    // predicts is rare, an absorbing holder with a stated share against a sized slack, where
    // `Remainder` says the share on a labour layer is unmeasured by design and for good, and
    // `capacitySlack` says a person is the one supply that can run hot.
    //
    // What must not go silent is the population that reaches the exemption. If an upstream
    // filter empties that, the split above never runs, and the emptiness stops being a
    // finding about the evidence and becomes a defect nothing reports.
    assert!(
        candidates >= 2,
        "only {candidates} layers pair an interference fit with a sized absorber slack, and \
         {checked} of those had a served share to bound; a bound with nothing to bound \
         passes loudest"
    );
}

/// A three-point range, stripped of its unit. Both sides of a fit comparison are in the
/// layer's own unit by construction, which is what makes the comparison legitimate.
type Range = (f64, f64, f64);

/// The demand and nameplate ranges of a layer, where both are stated.
fn demand_and_nameplate(l: &pm::LayerType) -> Option<(Range, Range)> {
    let (dl, dm, dh, _) = stated(&l.demand.amount)?;
    let (nl, nm, nh, _) = stated(&l.supply.nameplate.amount)?;
    Some(((dl, dm, dh), (nl, nm, nh)))
}

/// ISO 286's own criterion, which compares two ranges and never two points.
///
/// A fit class is decided by how the hole's tolerance zone lies against the shaft's, and that
/// decides every case among the three. `mostLikely` decides nothing.
fn iso_fit(d: Range, n: Range) -> FitType {
    if n.0 >= d.2 {
        FitType::Clearance
    } else if n.2 <= d.0 {
        FitType::Interference
    } else {
        FitType::Transition
    }
}

/// How far demand can run past the supply at the worst corner, from `demand` and
/// `nameplate` and nothing else.
///
/// It is not recoverable from the remainder's magnitude, which is why it is computed here.
/// The magnitude has no sign, so under a transition fit it keeps only the larger of the two
/// sides, and the smaller one is invisible inside it. On `refutation#compute` the magnitude is
/// the clearance side, and the interference sits inside that range, indistinguishable from as
/// much clearance.
fn exposure(d: Range, n: Range) -> f64 {
    (d.2 - n.0).max(0.0)
}

/// True where somebody looked at how far this supply can run above its rating and found zero.
///
/// A measured zero has one spelling, a claim of `[0, 0, 0]`, so this reads the claim arm.
/// Reading only the absence arm would find none, and the assertion downstream would examine
/// nothing rather than fail on a document. `pm:ClaimAbsence` has no `none`, so there is no
/// second spelling to union with, here or on the SQL side, where `layers/absorption.sqlc`
/// reads the one spelling straight off `entries/slacks.sqlc`.
///
/// A sized slack is not automatically headroom. Sized at zero is the strongest statement the
/// element can make, that the supply cannot be run hot at any price, and the `boundOrigin`
/// says by whose authority: a shelf life, a reserved block, or somebody's own ceiling.
fn cannot_run_hot(l: &pm::LayerType) -> bool {
    match &l.supply.nameplate.capacity_slack {
        StatedClaimType::Absent(_) => false,
        StatedClaimType::Claim(c) => c.low == 0.0 && c.most_likely == 0.0 && c.high == 0.0,
    }
}

/// The fit is a comparison of two ranges.
///
/// With two members, `Fit` could take one value only by being read at one point,
/// `mostLikely`, while the magnitude beside it is computed across the range: two conventions
/// in one type. With three members it is read across the range, and the conventions become
/// one, which is most of the case for the third member.
///
/// Almost every corpus layer classifies the same either way, and that is the evidence rather
/// than a disappointment. The one that does not is `refutation#compute`, whose numbers are
/// the ones `Fit`'s own annotation uses to illustrate a crossing.
#[test]
fn a_fit_is_classified_across_the_whole_demand_range() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            let StatedFitType::Fit(sign) = &r.sign else {
                continue; // the direction was not filed; nothing to agree with
            };
            let Some((d, n)) = demand_and_nameplate(l) else {
                continue;
            };

            let expected = iso_fit(d, n);
            assert_eq!(
                *sign, expected,
                "{name} `{}`: demand [{}, {}, {}] against nameplate [{}, {}, {}] is a \
                 `{expected:?}` fit by the range comparison, and the document files \
                 `{sign:?}`. A fit read at `mostLikely` alone cannot see that the ranges \
                 overlap",
                l.name, d.0, d.1, d.2, n.0, n.1, n.2
            );
            checked += 1;
        }
    }

    assert!(
        checked >= 20,
        "only {checked} layers pair a stated fit with a stated demand and nameplate"
    );
}

/// A supply that cannot run above its rating cannot have absorbed what it could not serve, so
/// that demand went unserved, and the unserved share has to appear on the list.
///
/// Under `interference`, `Fit` states this for every holder: each must be `customer` or
/// `unrealised`, because the whole remainder is excess. Under `transition` that would be
/// wrong: part of the range is genuinely clearance, and a `booked` share is legitimate there.
/// A reserved block paid for and not fully drawn is exactly that. So the rule weakens to
/// presence, and the weakening is correct rather than a concession.
///
/// What cannot be checked here is the size of it, and the reason is worth knowing before
/// trusting this test: the interference portion of a share is not a filed field, and the
/// magnitude the shares sum to has already swallowed it.
/// `the_unserved_share_does_not_exceed_the_derived_exposure` bounds it from the other
/// direction, from demand and nameplate.
///
/// "Unserved" and not "refused": a reserved card that errors a request did refuse it, but a
/// caller who waits past their patience and leaves was refused by nobody. Both land in these
/// two holders, so the word must not decide which happened. `Layer/timeSlack` says it
/// outright: the holder does not get to refuse, the demand decayed.
///
/// A layer whose range crosses and that files `clearance` at the mode would never meet the
/// rule for `interference`; the third fit member is what makes that layer visible.
#[test]
fn a_supply_that_cannot_run_hot_names_whose_demand_went_unserved() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            if !cannot_run_hot(l) {
                continue; // unmeasured, or a sized slack: absorption is possible
            }
            let Some((d, n)) = demand_and_nameplate(l) else {
                continue;
            };
            let expo = exposure(d, n);
            if expo <= 1e-9 {
                continue; // the whole range clears; nothing went unserved
            }

            let unserved = r.holder.iter().any(|h| {
                matches!(
                    h,
                    StatedHolderType::Holder(h)
                        if h.kind == HolderKindType::Customer
                            || h.kind == HolderKindType::Unrealised
                )
            });
            assert!(
                unserved,
                "{name} `{}`: demand reaches {} against a nameplate of {}, and this supply's \
                 `capacitySlack` is a measured zero — it cannot be run above its rating at \
                 any price. The {expo:.4} it could not serve therefore went unserved rather \
                 than absorbed, and no holder says so. Unserved demand is `customer` or \
                 `unrealised`",
                l.name, d.2, n.0
            );
            checked += 1;
        }
    }

    assert!(
        checked >= 2,
        "only {checked} layers pair a measured-zero capacity slack with a positive exposure"
    );
}

/// The one place this model measures something with no instrument behind it.
///
/// Everywhere else a slack bounds shares that were already filed. Here the three buffers close a
/// bound over quantities a filer had to supply anyway: what your own numbers say could have gone
/// wrong, the demand's high above the nameplate's low, is at most what the buffers could absorb
/// at their highs plus what you admit went unserved at its high. The buffers are substitutes
/// (running hot, drawing on stock, making the demand wait), so all three are added, and one whose
/// room nobody sized suspends the check: that route's ceiling is unknown, not zero.
/// `notApplicable` is a route that does not arise and contributes nothing.
///
/// Evaluated at one corner, on purpose. The clearance and interference sides move in opposite
/// directions, so anything summed across the range pairs the slack week's spare with the busy
/// week's unserved demand and reports a state that occurs in no week.
///
/// No corpus layer reaches it. The one with every buffer stated leaves its unserved share
/// unmeasured, which suspends the sum. `assets/fixtures/every-unserved-excess.xml` exists to put
/// the state in front of this test, so the test reads it beside the corpus.
#[test]
fn the_unserved_share_does_not_exceed_the_derived_exposure() {
    let excess = {
        let path = format!(
            "{}/assets/fixtures/every-unserved-excess.xml",
            env!("CARGO_MANIFEST_DIR")
        );
        let xml = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
        let mut reader = SliceReader::new(&xml);
        ProcessModulusElementType::deserialize(&mut reader)
            .unwrap_or_else(|e| panic!("{path}: {e}"))
    };
    let mut documents = corpus();
    documents.push(("every-unserved-excess.xml", excess));

    let mut checked = 0;
    for (name, doc) in &documents {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            let Some((d, n)) = demand_and_nameplate(l) else {
                continue;
            };
            let expo = exposure(d, n);
            if expo <= 1e-9 {
                continue;
            }

            let mut absorbable = 0.0;
            let mut known = true;
            let slacks: [&dyn Filed; 3] = [
                &l.supply.nameplate.capacity_slack,
                &l.supply.nameplate.inventory_slack,
                &l.time_slack,
            ];
            for slack in slacks {
                match (slack.filed(), slack.absence()) {
                    (Some(c), _) => absorbable += c.high,
                    (None, Some(ClaimAbsenceReasonType::NotApplicable)) => {}
                    // Unmeasured, or the clearance this bound does not compute.
                    (None, _) => known = false,
                }
            }
            if !known {
                continue;
            }

            // One unstated unserved share suspends the sum, exactly as at Holder: what went
            // unserved is unknown, not zero.
            let mut unserved = 0.0;
            let mut all_stated = true;
            for h in &r.holder {
                let StatedHolderType::Holder(h) = h else {
                    continue;
                };
                if h.kind != HolderKindType::Customer && h.kind != HolderKindType::Unrealised {
                    continue;
                }
                match stated(&h.share) {
                    Some((_, _, hi, _)) => unserved += hi,
                    None => all_stated = false,
                }
            }
            if !all_stated {
                continue;
            }

            assert!(
                expo <= absorbable + unserved + 1e-9,
                "{name} `{}`: demand reaches {} against a nameplate of {}, so {expo:.4} could \
                 have gone unserved. The buffers can absorb {absorbable} and the document \
                 says {unserved} went unserved. The difference happened and nothing here \
                 records it",
                l.name,
                d.2,
                n.0
            );
            checked += 1;
        }
    }

    assert!(
        checked >= 1,
        "no layer pairs a positive exposure with every buffer decidable and stated unserved \
         shares, so this test checked nothing"
    );
}

/// The narrowing kinds are exercised, and so are the two typed absences beside them.
///
/// `narrowsWhen` as an optional bare string would make its absence mean three things at once:
/// nobody said, nothing would narrow it, or there is no range. That is the boolean
/// anti-pattern in the one field carrying the model's falsifiability claim, the same shape as
/// the three buffer slacks as booleans, `Fit` with two members where ISO 286 has three, and a
/// `lumpy boolean NOT NULL` in the DDL meeting a document that files divisibility as a typed
/// absence.
///
/// The `kind` is what makes the make-up of a range's width statable:
///
/// - `instrument`: the width is ignorance. A better measurement reveals what was always
///   there. Most of the corpus files this, and it is the reading `Claim`'s prose assumes.
/// - `intervention`: the width is variation. Only changing the process reduces it. The
///   sharpest case is a month being `[672, 720, 744]` hours: billing on a fixed 30-day
///   period removes that, and no instrument measures it away.
/// - `experiment`: the filer does not know which, and names what would settle it. This is
///   the honest third answer, and it is why the field is not an `ignorance | variation` flag.
///
/// A corpus using only `instrument` would leave two of the three kinds untested while every
/// rule above it passed. This walk reaches the claims on a layer, where it finds `instrument`
/// and both typed absences; the note at its end says where the other two kinds are counted.
#[test]
fn the_corpus_exercises_every_narrowing_kind() {
    // Counters rather than collected references: `corpus()` yields owned documents that
    // drop each iteration, so nothing borrowed from one outlives the loop.
    let (mut instrument, mut stated, mut not_applicable, mut unmeasured) = (0, 0, 0, 0);

    for (_, doc) in corpus() {
        for l in &doc.stack.layer {
            for c in [
                l.demand.amount.filed(),
                l.time_slack.filed(),
                l.supply.nameplate.amount.filed(),
                l.supply.nameplate.capacity_slack.filed(),
                l.supply.nameplate.inventory_slack.filed(),
            ] {
                let Some(c) = c else {
                    continue;
                };
                match &c.narrows_when {
                    StatedNarrowingType::Narrowing(n) => {
                        stated += 1;
                        if n.kind == NarrowingKindType::Instrument {
                            instrument += 1;
                        }
                    }
                    StatedNarrowingType::Absent(a) => match a.reason {
                        AbsenceReasonType::NotApplicable => not_applicable += 1,
                        AbsenceReasonType::Unmeasured => unmeasured += 1,
                        _ => {}
                    },
                    // A claim computed from others narrows as their terms do; none of these
                    // counters is about it.
                    StatedNarrowingType::Derivation(_) => {}
                }
            }
        }
    }

    assert!(
        instrument > 0,
        "no claim reached here files `instrument`, which is the reading `Claim`'s own prose \
         assumes throughout"
    );
    assert!(
        stated >= 3,
        "only {stated} stated narrowings were reached; a kind nobody files is a kind nobody \
         checks"
    );
    assert!(
        not_applicable > 0,
        "no claim files `notApplicable`, so the point-value case, which \
         `assets/sql/reports/absences_in_the_corpus.sql` counts and which is most of the \
         corpus, is unrepresented in what this test can see"
    );
    assert!(
        unmeasured > 0,
        "no claim files `unmeasured`, which is what a blank usually means"
    );

    // `intervention` and `experiment` sit on holder shares, coupling strengths and
    // conversion factors, which this walk does not reach. assets/sql/rules.sql groups
    // every narrowing in a document regardless of where it hangs, and reports the split.
}

/// The model's central assumption is countable, and the wrapper is what makes it so. A stack
/// asserts that its layers hold their remainders independently. `Coupling`'s own annotation
/// says a document with no couplings is not evidence of independence but a document where
/// nobody looked, and an optional, repeatable element would encode exactly that defect.
///
/// This test does not demand a particular answer. It demands that every stack give one, and
/// that the corpus hold more than a single answer, because a field where every document says
/// the same thing is decoration.
#[test]
fn every_stack_says_whether_anybody_looked_for_couplings() {
    let mut filed = 0;
    let mut reasons = Vec::new();

    for (name, doc) in corpus() {
        let ks = couplings(&doc.stack);
        match coupling_absence(&doc.stack) {
            None => {
                assert!(
                    !ks.is_empty(),
                    "{name}: a stack files couplings or a typed reason it has none, never an \
                     empty list"
                );
                filed += 1;
            }
            Some(a) => {
                assert!(
                    ks.is_empty(),
                    "{name}: a stack cannot both file couplings and file a reason it has none"
                );
                // `notApplicable` is a claim about the stack's shape rather than about
                // anybody's diligence: one layer, so there is no pair to couple.
                if a.reason == pm::AbsenceReasonType::NotApplicable {
                    assert_eq!(
                        doc.stack.layer.len(),
                        1,
                        "{name}: the coupling question has no population only in a one-layer \
                         stack, and this one has {}",
                        doc.stack.layer.len()
                    );
                }
                assert!(
                    a.note.as_deref().is_some_and(|n| n.len() > 20),
                    "{name}: an untested assumption is worth saying in words as well as in a \
                     reason code"
                );
                reasons.push(format!("{:?}", a.reason));
            }
        }
    }

    assert!(
        filed >= 2 && reasons.len() >= 2,
        "{filed} stacks filed couplings and {} declined; both arms have to be exercised or \
         this rule is about nothing",
        reasons.len()
    );

    // And here is the reading an empty list cannot give. Not one stack in this corpus files
    // `none`: nobody has relieved a layer's constraint, watched the others and reported
    // independence. Every stack that declines says `unmeasured` or has no pair to test, and
    // every stack that files a coupling contradicts the assumption outright. That is a fact
    // about the evidence rather than about any one filing, and it is reachable only because
    // an empty list is not an answer here.
    assert!(
        !reasons.contains(&"None".to_string()),
        "a stack now claims tested independence. That is a heavy claim and a welcome one — \
         update this test, and check that `Absence/note` says how it was established"
    );
}

/// A window's absence is typed, and the type decides the time slack. `Divisibility` says a
/// window is malformed on a unit with no denominator, which is `notApplicable`, and a supply
/// that is always on files a window of one whole period. A missing element would encode both
/// identically, and both would look the same as nobody having asked.
///
/// The rule the distinction buys back is the one the element asks for. Deriving a time slack
/// from the clearance assumes the spare is spread evenly across the denominator; a window
/// denies it. So a filed window forbids a `derived` time slack, and so does `unmeasured`,
/// because nobody knows whether the spare is spread evenly, which is the case a rule reading
/// presence alone cannot reach.
#[test]
fn a_windows_absence_is_typed_and_it_decides_whether_a_time_slack_can_be_derived() {
    let mut reasons = Vec::new();
    let mut checked = 0;

    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedDivisibilityType::Divisibility(_) = &l.supply.nameplate.divisibility else {
                continue; // no divisibility at all, so no window slot to fill
            };
            let quantum = window(l);
            let absence = window_absence(l);
            assert!(
                quantum.is_some() != absence.is_some(),
                "{name} `{}`: a divisibility files a window or a typed reason it has none, \
                 never both and never neither",
                l.name
            );

            // `notApplicable` is a claim about the unit, and what sits under its line is
            // filed one element over. Reading the unit's text for " per " cannot tell a
            // period from a denominator that merely exists: `GPU-hour per GPU` files `each`,
            // and a window is still malformed there.
            if let Some(a) = absence {
                if a.reason == ClaimAbsenceReasonType::NotApplicable {
                    if let Some(amount) = l.supply.nameplate.amount.filed() {
                        assert!(
                            !matches!(&amount.denominator, pm::StatedDenominatorType::Period(_)),
                            "{name} `{}`: the window question is malformed only where the unit \
                             has no period under the line, and `{}` files {}",
                            l.name,
                            amount.unit,
                            denominator_says(&amount.denominator),
                        );
                    }
                }
                reasons.push(format!("{:?}", a.reason));
            }

            // Two licences, and neither may be read out of an absence. Deriving the time
            // slack from the clearance spreads the spare evenly across the denominator, so it
            // needs either no denominator at all (`notApplicable`) or a supply that is live
            // for the whole of one (a window of one whole period). Spelling the second as
            // `absent/reason = none` would file a number as a nothing.
            let derivable = absence
                .is_some_and(|a| a.reason == ClaimAbsenceReasonType::NotApplicable)
                || runs_the_whole_period(l);
            if !derivable {
                assert!(
                    !matches!(l.time_slack, StatedTimeSlackType::Derivation(_)),
                    "{name} `{}`: the supply is intermittent, or nobody has said it is not, \
                     so the spare is not spread evenly across the denominator and a time \
                     slack cannot be computed from the clearance",
                    l.name
                );
                checked += 1;
            }
        }
    }

    assert!(
        checked >= 4,
        "only {checked} layers reached the derivation rule; it bites on filed and unmeasured \
         windows, and both have to exist for it to be a rule"
    );
    reasons.sort();
    reasons.dedup();
    assert!(
        reasons.len() >= 2,
        "every declined window in the corpus gives the same reason ({reasons:?}), so nothing \
         here shows the distinction doing work"
    );
}

/// Who owns the edge of this range. As an optional bare enumeration, `Claim/boundOrigin`
/// would be filed almost nowhere, and an optional field nobody fills is not a weak signal, it
/// is an absent one: its blank cannot separate "nobody has asked" from "nothing sets this
/// bound, the range is where the measurements fell". It is a required
/// `StatedConstraintOrigin`, and `assets/sql/reports/bound_ownership.sql` prints what it gets.
///
/// The model already answers this question in a sibling element for half the corpus.
/// `Nameplate/amountOrigin` says who could hold a different number; `LumpyQuantum/origin` says
/// who sets the size of one. Where a sibling states it, the claim names that sibling as the
/// identity computing its edge (`amountOrigin`, `quantumOrigin`) rather than restating it: a
/// value sent here could disagree with its own inputs, and a name a receiver follows cannot.
#[test]
fn every_claim_says_who_owns_the_edge_of_its_range() {
    let mut origins = Vec::new();
    let mut reasons = Vec::new();
    let mut derived_beside_a_sibling = 0;

    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let mut check = |what: &str, c: Option<&ClaimType>, sibling: Option<IdentityType>| {
                let Some(c) = c else { return };
                match &c.bound_origin {
                    StatedConstraintOriginType::Origin(o) => origins.push(format!("{o:?}")),
                    StatedConstraintOriginType::Derivation(d) => {
                        if matches!(d.identity, IdentityType::AmountOrigin | IdentityType::QuantumOrigin) {
                            assert_eq!(
                                Some(&d.identity),
                                sibling.as_ref(),
                                "{name} `{}` {what}: `{:?}` says the author of this edge is \
                                 stated in a sibling element, and this claim sits beside no such \
                                 element. A receiver following the name finds nothing",
                                l.name,
                                d.identity
                            );
                            derived_beside_a_sibling += 1;
                        }
                    }
                    StatedConstraintOriginType::Absent(a) => {
                        assert!(
                            a.note.as_deref().is_some_and(|n| n.len() > 15),
                            "{name} `{}` {what}: a typed reason with no words beside it makes a \
                             reader guess which of the four readings was meant",
                            l.name
                        );
                        reasons.push(format!("{:?}", a.reason));
                    }
                }
            };

            // `amount` sits beside `amountOrigin`, and a lumpy `size` beside its own
            // `origin`; `demand` and a `draw` sit beside nothing at all.
            check("demand", l.demand.amount.filed(), None);
            check("draw", l.supply.jagged.draw.filed(), None);
            check("timeSlack", l.time_slack.filed(), None);
            check("nameplate", l.supply.nameplate.amount.filed(), Some(IdentityType::AmountOrigin));
            check("capacitySlack", l.supply.nameplate.capacity_slack.filed(), None);
            check("inventorySlack", l.supply.nameplate.inventory_slack.filed(), None);
            if let Some(q) = lumpy(l) {
                check("quantum", q.size.filed(), Some(IdentityType::QuantumOrigin));
            }
        }
    }

    assert!(
        derived_beside_a_sibling >= 20,
        "only {derived_beside_a_sibling} claims point at a sibling for their origin; the whole \
         finding here is that the model answers this for the nameplate half of the corpus in \
         a sibling element, and a claim says so by naming it"
    );
    origins.sort();
    origins.dedup();
    reasons.sort();
    reasons.dedup();
    assert!(
        origins.len() >= 2 && reasons.len() >= 2,
        "{origins:?} stated and {reasons:?} declined; a field where every claim gives the same \
         answer shows nothing about the distinction it is there for"
    );
}
