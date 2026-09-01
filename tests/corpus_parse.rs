//! Reads every document in `assets/corpus/` with the generated types.
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

use process_modulus::asrt::CompositionType;
use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, ConstraintOriginType, FitType, HolderKindType, NarrowingKindType,
    OperationTypeContent, ProcessModulusElementType, StatedBorrowedTermType, StatedClaimType,
    StatedConstraintOriginType, StatedDivisibilityType, StatedFitType, StatedHolderType,
    StatedLumpyQuantumType, StatedNarrowingType, StatedRemainderType,
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

/// ⛔⛔ EVERY FILING IN `assets/corpus/`, INCLUDING THE ONES INSIDE A COMPOSITION.
///
/// `load` deserializes a `pm:processModulus` ROOT, so it cannot read a composition at all —
/// and a composition's stack is an ordinary filing that happens to be embedded. Leaving
/// those two out is how a corpus check comes to read as coverage while exempting the newest
/// documents in the repository, which is `no_example_is_exempt_from_the_namespace_gate`'s
/// argument one layer down.
///
/// ⚠️ IT IS NOT HYPOTHETICAL. `assert_holder_rules` below was written after a `party`
/// landed on a `booked` holder inside `merge-group-composition.xml`, where no test in this
/// crate was looking.
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
/// ⭐⭐ `party`/`asOf` BELONG TO `counterparty` AND TO NOTHING ELSE, and the trap is a
/// consolidation: a `booked` share in a group filing IS booked in some member's books, and
/// naming which one looks exactly like what `party` is for. It is not — on a counterparty
/// holder `party` names whose OTHER books carry the burden; on a booked holder it would name
/// which of our OWN units records it. Two relations, one field.
///
/// ⭐ And the half that matters more: A `counterparty` HOLDER MUST NAME ITS PARTY. A burden
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
                 counterparty. Which of our own units books a share is a different relation \
                 from whose other books carry it, and a consolidation already answers the \
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

    // ⚠️ S-15's TRAP, GUARDED. A per-holder rule over a corpus with no counterparty in it
    // passes without running, and a profile counting rules exercised would score this as
    // covered while nothing was checked.
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

/// A three-point claim's bounds, for the rules the schemas state in prose and no
/// XSD 1.0 validator can reach.
fn bounds(c: &StatedClaimType, what: &str) -> (f64, f64, f64) {
    let StatedClaimType::Claim(c) = c else {
        panic!("{what}: expected a stated claim, found a typed absence");
    };
    (c.low, c.most_likely, c.high)
}

/// The fourth-buffer argument, filed — and it is SHARPER than the shape that used to
/// carry it.
///
/// ⭐ The magnitude was never the unmeasured thing. `|4 - [4.5, 5.2, 6.0]|` is
/// `[0.5, 1.2, 2.0]` people and this document already determines it, so `quantity` is
/// `derived`. What no instrument reaches is HOW MUCH OF IT THE TEAM ABSORBED, and that
/// is the holder's `share`.
///
/// ⛔ Filing the whole remainder as `unmeasured` understated the claim. It said we know
/// nothing, when in fact we know the size and not the bearer, which is the more
/// damaging of the two things to be able to say.
///
/// ⭐⭐ AND THE BEARER IS TWO THINGS, WHICH THIS TEST USED TO ASSERT IT WAS NOT. It read
/// `let [one_holder] = &r.holder[..]` with the message "labour has one holder, and nobody
/// has split it" — a shape assertion that made the document's own `timeSlack` note
/// unfileable. That note says work queues, waits and quietly ages out, and that the portion
/// which ages out is `unrealised` and NOT `people`. With a single `people` holder the
/// document asserted the team absorbed all of it and contradicted itself in the same layer.
///
/// ⚠️ BOTH SHARES ARE STILL `unmeasured`, so nothing was invented to make an arithmetic
/// check pass — per Holder, one unstated share suspends the sum rather than breaking it.
/// What the split adds is the ADMISSION that the remainder divides. Which half grew is the
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
        let StatedClaimType::Absent(share) = &h.share else {
            panic!(
                "the `{:?}` share is the thing with no instrument behind it, and a figure \
                 here would be one somebody invented to split a total nobody measured",
                h.kind
            );
        };
        assert_eq!(
            share.reason,
            AbsenceReasonType::Unmeasured,
            "`unmeasured` is the claim on the `{:?}` share. `none` would assert somebody \
             looked and found zero",
            h.kind
        );
    }

    let StatedClaimType::Absent(q) = &r.quantity else {
        panic!("demand and nameplate are both stated, so a carried total duplicates them");
    };
    assert_eq!(
        q.reason,
        AbsenceReasonType::Derived,
        "the receiver computes it; a stored copy can disagree with its own inputs"
    );
}

/// Two holders on one remainder, which is the shape a single holder could not carry.
///
/// ⛔ `Fit` names BOTH `customer` and `unrealised` for an unserved excess, because a
/// customer who waited and one who never arrived are different people and only one of
/// them is still yours. The old shape made the sender pick one and discard the other,
/// and the discarded half is frequently the one somebody wanted.
///
/// ⭐ It also exercises the sum rule, which XSD 1.0 cannot express: the stated shares
/// add up to `|nameplate - demand|`.
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

    let (dl, dm, dh) = bounds(&l.demand, "capability demand");
    let (nl, nm, nh) = bounds(&l.supply.nameplate.amount, "capability nameplate");

    // ⚠️ Valid only because this fit is DETERMINATE: the whole demand range sits above
    // the nameplate, so `n - d` never crosses zero and taking the magnitude is just a
    // reflection. A straddling range has no single sign and this arithmetic would be
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

    let Some(q) = continuous(l) else {
        panic!("object storage is bought continuously in this example, and states so");
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
///
/// ⭐ `unmeasured` AND `none` ARE NOW DIFFERENT DOCUMENTS HERE, which they were not while
/// this was a boolean. `none` says somebody looked and there is no room above the rating;
/// `unmeasured` says nobody has established how much room there is. The old `true` meant
/// both at once and a reader could not tell which.
#[test]
fn a_capacity_slack_can_be_left_unmeasured_instead_of_guessed() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedClaimType::Absent(a) = &l.supply.nameplate.capacity_slack else {
        panic!("this example has not established how far this supply can run above rating");
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

/// S-5. What BOUNDS a range is a different question from what would NARROW it,
/// and a sender with both facts can now file both.
///
/// ⛔⛔ AND `narrowsWhen` NO LONGER ANSWERS `is_some()`, WHICH IS THE POINT OF S-29. It was
/// an optional bare string, so its absence meant "nobody said" and "nothing would narrow
/// this" and "there is no range to narrow" all at once — the boolean anti-pattern, in the
/// one field carrying the model's falsifiability claim. It is a required `StatedNarrowing`
/// now, so the question this test asks is no longer "is it there" but WHAT IT SAYS.
///
/// ⭐ The `kind` is where the fact lives. `instrument` means the width is IGNORANCE and a
/// better measurement reveals it; `intervention` means the width is VARIATION and only
/// changing the process reduces it; `experiment` means the filer does not know which and
/// is naming what would settle it.
#[test]
fn a_claim_can_carry_both_what_bounds_it_and_what_would_narrow_it() {
    let doc = load("unstated.xml");
    let l = layer(&doc, "margin-ratio");

    let StatedClaimType::Claim(c) = &l.demand else {
        panic!("this example states its demand");
    };
    let StatedConstraintOriginType::Origin(o) = &c.bound_origin else {
        panic!("this example names who owns the edge of its margin range")
    };
    assert_eq!(*o, ConstraintOriginType::Policy);

    let StatedNarrowingType::Narrowing(n) = &c.narrows_when else {
        panic!(
            "this claim names what would narrow it; an absence here would be the OTHER \
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
        "closing the quarter and landing actual cost is a MEASUREMENT arriving, so this \
         range is ignorance rather than variation"
    );
}

/// The couplings a stack filed, or an empty slice where it filed a typed reason instead.
///
/// ⛔⛔ THE EMPTY SLICE AND `absent reason="none"` ARE NOT THE SAME DOCUMENT, and no caller
/// may treat them as one. `Stack/couplings` used to be `minOccurs="0" maxOccurs="unbounded"`,
/// so a stack that had been tested for independence and a stack nobody had looked at were
/// byte-identical — the boolean anti-pattern wearing a plural. Use `coupling_absence` when
/// the question is which.
///
/// ⚠️ THE XSD GUARANTEE IS NOT VISIBLE IN THE TYPE. The choice is "one or more couplings, OR
/// one absence", and the generator flattens that to a `Vec` that could in principle hold
/// both. XSD refuses such a document; this helper simply reads the arm that is there, the
/// same way `lumpy` and `continuous` do for `Divisibility`.
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

/// A layer's demand claim, when it is stated.
fn stated(c: &StatedClaimType) -> Option<(f64, f64, f64, &str)> {
    match c {
        StatedClaimType::Claim(c) => Some((c.low, c.most_likely, c.high, c.unit.as_str())),
        StatedClaimType::Absent(_) => None,
    }
}

/// The `lumpy` arm of a divisibility, ignoring any `window` beside it.
///
/// ⚠️ `Divisibility` became a SEQUENCE — the `lumpy | continuous` choice, then an optional
/// `window` — when the time axis arrived, and the generated Rust flattens that to a
/// `Vec<DivisibilityTypeContent>`. So the XSD's guarantee of exactly one amount arm is no
/// longer visible in the type, and these three helpers put it back rather than letting every
/// call site rediscover it.
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
/// ⭐ THE TWO HALVES ARE ASKED SEPARATELY ON PURPOSE. `window` above answers "how much of
/// each period is this supply live for"; this answers "and if you did not say, why not" —
/// and the four reasons are not interchangeable. `notApplicable` is a unit with no
/// denominator, `none` is a supply that runs continuously, `unmeasured` is the one state
/// that leaves a derived `timeSlack` unjustified.
fn window_absence(l: &pm::LayerType) -> Option<&pm::AbsenceType> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        pm::DivisibilityTypeContent::Window(StatedLumpyQuantumType::Absent(a)) => Some(a),
        _ => None,
    })
}

/// The lumpy quantum of a layer's supply, if it has one and it is stated.
fn quantum(l: &pm::LayerType) -> Option<(f64, f64, f64, &str)> {
    stated(&lumpy(l)?.size)
}

/// ⭐⭐ A QUANTUM IS IN THE UNIT OF THE NAMEPLATE IT DIVIDES, AND THE RULE IS ARITHMETICAL.
///
/// `conformance/README.md` states this and nothing enforced it, so one filing read it the
/// other way for two passes: `enterprise-contract.xml` filed a `capability` layer whose
/// demand is `launches per quarter` against a quantum of `launches`.
///
/// ⛔ THE BARE-THING READING IS NOT A STYLE PREFERENCE, IT IS WRONG. The purpose of a
/// quantum is that `nameplate / q` and `demand / q` are COUNTS. `(launches per quarter) /
/// launches` is a frequency, and the decomposition it feeds means nothing. The lump on a
/// rate is a lump OF THE RATE — one launch slot per quarter, not one launch.
///
/// It computed anyway, because the size was 1. That is the whole hazard: a dimensional
/// error that is numerically invisible until somebody files a quantum larger than one.
#[test]
fn a_quantum_is_expressed_in_the_unit_of_the_supply_it_divides() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let (Some((_, _, _, du)), Some((_, _, _, qu))) = (stated(&l.demand), quantum(l)) else {
                continue;
            };
            assert_eq!(
                qu, du,
                "{name} `{}`: a quantum of `{qu}` against a demand of `{du}` cannot be \
                 divided into it. If the supply really comes in a different unit from the \
                 demand, that is a CONVERSION and it belongs to whoever composes them",
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

/// ⛔⛔⛔ THE DECOMPOSITION IS AN IDENTITY, AND ITS TWO HALVES ARE NOT `Claim`s.
///
/// `conformance/README.md` gives `m = nameplate/q − ⌊demand/q⌋`, `residue = demand mod q`,
/// `r = m·q − residue`. Substituting `k = n/q` shows the floors cancel outright:
///
/// ```text
/// r = (n/q − ⌊d/q⌋)·q − (d − ⌊d/q⌋·q) = n − d
/// ```
///
/// ⭐ SO `r` IS EXACT FOR ANY DEMAND AND ANY NAMEPLATE, INTERVAL OR NOT. `⌊⌋` appears twice
/// with opposite signs and never has to resolve. A finding claiming the decomposition
/// "assumes point values" was wrong about the part that matters, and the first half of this
/// test is that correction executed rather than asserted.
///
/// ⛔⛔ WHAT IS ACTUALLY FRAGILE IS THE SPLIT, AND IT IS FRAGILE IN HALF THIS CORPUS RATHER
/// THAN AT SOME EXOTIC EDGE. `d mod q` jumps at every multiple of `q`, so evaluated at a
/// demand range's three points it need not be ordered at all — and in exactly ten of the
/// twenty lumpy layers here it is not. `refutation.xml#compute` has demand
/// `(11, 13.2, 16.4)` at `q = 8` and residues `(3.0, 5.2, 0.4)`; that file predates every
/// pass that discussed this and nobody noticed. A residue like that violates
/// `low ≤ mostLikely ≤ high`, the FIRST rule in the conformance table, while the demand
/// that produced it is perfectly well formed.
///
/// ⭐⭐ AND THE SCHEMA IS ALREADY SAFE, WHICH IS THE HAPPY PART. `Remainder` carries
/// `quantity`, `sign`, `absorber` and `holder` — the TOTAL and never the two components.
/// That shape was right before the reasoning for it was written down. What is not safe is
/// `conformance/README.md` presenting `m·q` and `residue` as though a sender could file
/// them, and an implementer who reads that block as a filing instruction will produce
/// documents this schema would reject.
#[test]
fn the_decomposition_is_an_identity_and_its_two_halves_are_not_claims() {
    let mut checked = 0;
    let mut sawtooth: Vec<String> = Vec::new();

    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let (Some((dl, dm, dh, _)), Some((ql, qm, qh, _))) = (stated(&l.demand), quantum(l))
            else {
                continue;
            };
            let Some((nl, nm, nh, _)) = stated(&l.supply.nameplate.amount) else {
                continue;
            };
            assert_eq!(
                (ql, qh),
                (qm, qm),
                "{name} `{}`: an interval quantum makes `⌊d/q⌋` genuinely ambiguous, and \
                 nothing in this repository has forced that case yet",
                l.name
            );

            // ⭐ The identity, evaluated the long way round: build `m` and the residue as
            // the conformance block writes them, recombine, and check against `n − d`.
            for (n, d) in [(nl, dl), (nm, dm), (nh, dh)] {
                let residue = d - (d / qm).floor() * qm;
                let m = n / qm - (d / qm).floor();
                assert!(
                    ((m * qm - residue) - (n - d)).abs() < 1e-9,
                    "{name} `{}`: the decomposition is supposed to be `nameplate − demand` \
                     identically, and at n={n}, d={d}, q={qm} it is not",
                    l.name
                );
            }

            let r = |d: f64| d - (d / qm).floor() * qm;
            let (rl, rm, rh) = (r(dl), r(dm), r(dh));
            if !((rl <= rm && rm <= rh) || (rl >= rm && rm >= rh)) {
                sawtooth.push(format!(
                    "{name}#{} residues ({:.4}, {:.4}, {:.4})",
                    l.name, rl, rm, rh
                ));
            }
            checked += 1;
        }
    }

    assert!(
        checked >= 15,
        "only {checked} lumpy layers were reachable; an identity with nothing to check \
         passes loudest"
    );
    // ⚠️ HALF, NOT A HANDFUL, AND THE NUMBER IS THE ARGUMENT. A rule broken by one exotic
    // document is an outlier; one broken by half the corpus is a rule nobody can follow.
    assert!(
        sawtooth.len() * 3 >= checked,
        "the un-filable residue is supposed to be pervasive, which is what stops anyone \
         treating the split as generally available. Only {} of {checked}:\n  {}",
        sawtooth.len(),
        sawtooth.join("\n  ")
    );
}

/// The slack of the buffer a remainder's `absorber` names, if that buffer has one sized.
///
/// ⚠️ THE UNIT IS RETURNED AND IT USED TO BE DROPPED HERE — `.map(|(lo, ml, hi, _)| ...)`,
/// discarded on the last field. That made the bound below a comparison between two bare
/// floats, and the whole reason the comparison is legitimate is that both sides are in the
/// layer's unit. See `a_slack_is_expressed_in_the_unit_of_the_shares_it_bounds`.
fn absorber_slack(l: &pm::LayerType) -> Option<(f64, f64, f64, &str)> {
    let StatedRemainderType::Remainder(r) = &l.remainder else {
        return None;
    };
    let StatedBorrowedTermType::Term(t) = &r.absorber else {
        return None;
    };
    let c = match t.value.as_str() {
        "capacity" => &l.supply.nameplate.capacity_slack,
        "inventory" => &l.supply.nameplate.inventory_slack,
        "time" => &l.time_slack,
        _ => return None,
    };
    stated(c)
}

/// ⛔⛔⛔ A WINDOW IS A NOTE ON THE UNIT'S DENOMINATOR, SO THE UNIT MUST HAVE ONE.
///
/// The denominator supplies the period, the window supplies the live part of it, and the ratio
/// is the duty fraction — `3 hours` against `2160 muffins per day` is 3h/1day. Which makes the
/// denominator rule its precondition rather than a separate convention: the denominator must
/// cover a whole cycle so that the window has a well-defined thing to be a fraction OF.
///
/// ⛔ So a window on a STOCK is malformed, not merely unmeasured. `12 people` has no period, so
/// "5 days" has nothing to be five days of, and `GPU-hour` carries its hour in the numerator —
/// it is a quantity of resource-time, not a rate. ⭐ That is why this element is rare rather
/// than under-used: of every nameplate unit in this corpus only `shifts per week`, `turnos por
/// semana` and `launches per quarter` have a denominator at all.
///
/// ⚠️ THE CHECK IS A STRING TEST OVER FREE TEXT AND SHOULD BE READ AS ONE. A unit is an
/// `xs:token` and nothing in the model distinguishes a rate from a stock, so this looks for a
/// `per`/`por` token and would miss `muffins/day` or an unrecognised language. It catches the
/// mistake that is actually available — a window filed against `people` — and not the general case.
#[test]
fn a_window_requires_a_unit_with_a_period_to_be_a_fraction_of() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            if window(l).is_none() {
                continue;
            }
            let StatedClaimType::Claim(amount) = &l.supply.nameplate.amount else {
                panic!(
                    "{name} `{}`: a window on a nameplate with no stated amount",
                    l.name
                );
            };
            let unit = &amount.unit;
            assert!(
                unit.split_whitespace().any(|w| w == "per" || w == "por"),
                "{name} `{}`: a window is filed against a nameplate in `{unit}`, which names no \
                 period. A window is the live PART of the unit's denominator, so a unit without \
                 one gives it nothing to be a fraction of — a stock has no cycle to be live in",
                l.name
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

/// ⛔⛔⛔ A WINDOW IS A PROPERTY OF THE MACHINE, SO IT IS CARRIED THROUGH A FUSION AND NEVER
/// SUMMED. This is the one rule that separates the new time axis from every quantity beside it.
///
/// Demand sums: two members asking for the same line want more line. A window does not, and the
/// reason is not a convention — both members name THE SAME MACHINE, and a line staffed weekdays
/// by two customers is still staffed weekdays. Summing would say ten days a week.
///
/// ⭐ IT IS THE NAMEPLATE'S CASE ARRIVING BY ANOTHER ROUTE. The group eliminates the duplicated
/// nameplate for exactly this reason — two members, one machine — and files the elimination. A
/// window needs no elimination because it never summed: it is a property, not a quantity, which
/// is why `EliminationAgainst` has three members and deliberately no fourth.
///
/// ⚠️ The two members file it in different languages — `days` and `dias` — so the check is on
/// the figure. Two parties describing one machine is the case this corpus exists for.
#[test]
fn a_window_is_carried_through_a_fusion_and_never_summed() {
    let mut sizes: Vec<(String, f64)> = Vec::new();
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            if let Some(w) = window(l) {
                let (_, ml, _, _) = stated(&w.size)
                    .unwrap_or_else(|| panic!("{name} `{}`: a window with no size", l.name));
                sizes.push((format!("{name}#{}", l.name), ml));
            }
        }
    }

    assert!(
        sizes.len() >= 3,
        "only {} windows were filed; the carry-not-sum rule needs the parts AND the fused \
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

    // ⛔ THE PERTURBATION THIS RULE EXISTS FOR. A fused window equal to the sum of its parts
    // is the mistake a reader who has just learned how `demand` composes will make.
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

/// ⛔⛔⛔ A SIZED SLACK SAYS WHO SET IT, AND THE THREE SLACKS WERE THE ONLY CONSTRAINTS IN
/// THIS MODEL THAT DID NOT.
///
/// `Nameplate/amountOrigin` says who can hold a different number of units. `LumpyQuantum/origin`
/// says who sets the size of one. A slack said how much room a buffer has and nothing whatever
/// about whether anybody could move it — while `Claim/boundOrigin` sat there optional and was
/// filed exactly ONCE in the whole corpus.
///
/// ⭐ THE CASE THAT FORCED IT IS AN SLA. Two layers can file the same `timeSlack` and mean
/// opposite things: one is how long queued work physically keeps, the other is how long a
/// contract says the customer waits. The first is not a lever and the second is a negotiation,
/// and no reader can tell them apart from the number. The corpus now files one of each —
/// `capability` intrinsic, `shift-line` contractual — which is the smallest population that
/// makes the distinction visible rather than asserted.
#[test]
fn a_sized_slack_says_who_can_move_it() {
    let mut origins = Vec::new();
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            for (what, c) in [
                ("capacitySlack", &l.supply.nameplate.capacity_slack),
                ("inventorySlack", &l.supply.nameplate.inventory_slack),
                ("timeSlack", &l.time_slack),
            ] {
                let StatedClaimType::Claim(claim) = c else {
                    continue; // an absent slack constrains nothing, so it sets nothing
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
    // ⚠️ ONE ORIGIN ACROSS EVERY SLACK WOULD MEAN THE FIELD IS DECORATION. The point is that
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

/// ⛔⛔ A SLACK IS COMPARED AGAINST HOLDER SHARES, SO IT MUST BE IN THE SHARES' UNIT.
///
/// The rule `sum of shares <= slack` is arithmetic between two claims, and arithmetic between
/// two claims is only meaningful when they are measured in the same thing. `Claim` says so
/// itself — "a unit is NOT a conversion licence, and two claims in different units do not
/// combine" — and until this test there was nothing checking it for the one comparison the
/// three slacks exist to make. The quantum has had this check since S-20; the slack had none.
///
/// ⚠️⚠️ AND IT CATCHES LESS THAN IT LOOKS LIKE IT DOES, WHICH IS WORTH SAYING BEFORE ANYBODY
/// COUNTS IT AS COVERAGE. A buffer's size is naturally measured as a DURATION — how long work
/// sits, how long before a caller leaves — while this field takes a QUANTITY, so the filer
/// owes a `quantity = duration x rate` conversion. A filer who skips the multiplication and
/// writes the right unit on the unconverted number passes this test cleanly. It catches a
/// MISLABELLED quantity and never a RELABELLED one; only the arithmetic catches that.
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

    // The same vacuity trap as the bound itself: every slack was `unmeasured` once.
    assert!(
        checked >= 2,
        "only {checked} share/slack pairs were reachable; a unit rule with nothing to compare \
         passes loudest"
    );
}

/// ⛔⛔⛔ A HOLDER'S SHARE MUST NOT EXCEED THE SLACK OF THE BUFFER ITS ABSORBER NAMES.
///
/// This is the rule the three availability conditions were retyped for, and it could not be
/// written while they were booleans. A boolean says a buffer is available; it cannot say
/// AVAILABLE, BARELY. On a conveyor at a hundred slots an hour carrying ninety-five muffins,
/// five slots an hour are free and that is the whole of the buffer — and a sender attributing
/// fifty muffins an hour to it could still file `true`, quite honestly. The boolean caught a
/// CONTRADICTION and never an ATTRIBUTION.
///
/// ⚠️ AN EARLIER DRAFT OF THIS COMMENT SIZED THAT BUFFER AT "ABOUT TWELVE MINUTES", which is
/// the same dimension error `Layer/timeSlack` now warns about at length: twelve minutes is
/// `q / clearance`, a duration, and what the bound below compares is a quantity in the layer's
/// unit. Five muffins an hour is the slack; twelve minutes describes the same belt in a
/// dimension this rule cannot use.
///
/// ⭐ THE BOUND IS ON THE INTERFERENCE SIDE ONLY, and `capacitySlack`'s annotation says why:
/// spare capacity under a clearance fit is the unused part of a rating, which the remainder
/// already carries. A slack is the room at the other end — above the nameplate, in the
/// stockroom, in the queue — which is what a buffer draws on when demand exceeds supply.
///
/// ⭐⭐ AND `unrealised` IS EXEMPT, WHICH IS THE INTERESTING PART. Demand that never
/// arrived was absorbed by nothing; it is what OVERFLOWED every buffer. So a sized slack
/// begins to explain the unrealised share rather than merely recording it — on
/// `merge-holding-composition#shift-line` the queue holds about 2.5 shifts, the customers
/// who waited account for 1.7, and the 1.0 that did not fit is exactly the unrealised
/// figure.
///
/// ⚠️ EVALUATED AT `mostLikely`, following the `sign` rule, which is the existing precedent
/// for comparing two independent intervals without inventing a convention. A profile
/// wanting the strict reading — worst share against smallest slack — is choosing a policy,
/// and that choice belongs to the profile rather than to the model.
#[test]
fn a_share_does_not_exceed_the_slack_of_the_buffer_that_absorbed_it() {
    let mut checked = 0;
    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let StatedRemainderType::Remainder(r) = &l.remainder else {
                continue;
            };
            // Only an interference side draws on a slack; clearance is spare, not overflow.
            // ⭐ `transition` is admitted because part of its range IS interference — the
            // bound applies to that part, and a `transition` layer excluded here would be a
            // layer whose overflow nothing bounds.
            if !matches!(
                &r.sign,
                StatedFitType::Fit(FitType::Interference | FitType::Transition)
            ) {
                continue;
            }
            let Some((_, slack, _, _)) = absorber_slack(l) else {
                continue; // unmeasured or none-with-no-figure: the check SUSPENDS
            };

            let borne: f64 = r
                .holder
                .iter()
                .filter_map(|h| match h {
                    StatedHolderType::Holder(h) if h.kind != HolderKindType::Unrealised => {
                        stated(&h.share).map(|(_, ml, _, _)| ml)
                    }
                    _ => None,
                })
                .sum();

            assert!(
                borne <= slack + 1e-9,
                "{name} `{}`: {borne} is attributed to the `{}` buffer, whose slack is \
                 {slack}. A buffer cannot absorb more than it holds, and the excess is \
                 `unrealised` — demand that overflowed every buffer — not a bigger buffer",
                l.name,
                match &r.absorber {
                    StatedBorrowedTermType::Term(t) => t.value.as_str(),
                    StatedBorrowedTermType::Absent(_) => "?",
                }
            );
            checked += 1;
        }
    }

    // ⚠️ S-15's TRAP. Every slack in this corpus was `unmeasured` when this rule was
    // written, so it passed by checking nothing and would have scored as covered.
    assert!(
        checked >= 2,
        "only {checked} layers pair an interference fit with a sized slack; a bound with \
         nothing to bound passes loudest"
    );
}

/// A three-point range, stripped of its unit. Both sides of a fit comparison are in the
/// layer's own unit by construction, which is what makes the comparison legitimate.
type Range = (f64, f64, f64);

/// The demand and nameplate ranges of a layer, where both are stated.
fn demand_and_nameplate(l: &pm::LayerType) -> Option<(Range, Range)> {
    let (dl, dm, dh, _) = stated(&l.demand)?;
    let (nl, nm, nh, _) = stated(&l.supply.nameplate.amount)?;
    Some(((dl, dm, dh), (nl, nm, nh)))
}

/// ⛔⛔ ISO 286'S OWN CRITERION, WHICH COMPARES TWO RANGES AND NEVER TWO POINTS.
///
/// A fit class is decided by how the hole's tolerance zone lies against the shaft's, and it
/// decides all three cases exhaustively. `mostLikely` decides nothing.
fn iso_fit(d: Range, n: Range) -> FitType {
    if n.0 >= d.2 {
        FitType::Clearance
    } else if n.2 <= d.0 {
        FitType::Interference
    } else {
        FitType::Transition
    }
}

/// ⭐ HOW FAR DEMAND CAN RUN PAST THE SUPPLY AT THE WORST CORNER, from `demand` and
/// `nameplate` and nothing else.
///
/// ⛔ It is NOT recoverable from the remainder magnitude, which is why it is computed here.
/// `|n - d|` is sign-blind, so under a transition fit it keeps only the LARGER of the two
/// sides and the smaller one is invisible inside it. On `refutation#compute` the magnitude is
/// `[0.0, 2.8, 5.0]` — the clearance side — and the 0.4 of interference sits inside that
/// interval indistinguishable from 0.4 of clearance.
fn exposure(d: Range, n: Range) -> f64 {
    (d.2 - n.0).max(0.0)
}

/// True where somebody looked at how far this supply can run above its rating and found zero.
fn cannot_run_hot(l: &pm::LayerType) -> bool {
    matches!(
        &l.supply.nameplate.capacity_slack,
        StatedClaimType::Absent(a) if a.reason == AbsenceReasonType::None
    )
}

/// ⛔⛔⛔ THE FIT IS A COMPARISON OF TWO RANGES, AND IT WAS A COMPARISON OF TWO POINTS UNTIL
/// `Fit` GAINED ITS THIRD MEMBER.
///
/// ⭐ While the enumeration had two members it took ONE value and therefore had to be read at
/// ONE point, `mostLikely`, while the magnitude beside it was computed across the range. Two
/// conventions in one type. Three members are read across the range and the conventions
/// become one, which is most of the argument for the member.
///
/// ⚠️ THE CORPUS BARELY MOVED, AND THAT IS THE EVIDENCE RATHER THAN A DISAPPOINTMENT. Twenty
/// of twenty-one layers classify identically under both rules. The twenty-first is
/// `refutation#compute`, whose numbers are the ones `Fit`'s own annotation uses to illustrate
/// a crossing — the schema described the missing member using the one document that had it.
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

/// ⛔⛔ A SUPPLY THAT CANNOT RUN ABOVE ITS RATING CANNOT HAVE ABSORBED WHAT IT COULD NOT
/// SERVE, SO THAT DEMAND WENT UNSERVED AND THE UNSERVED SHARE HAS TO APPEAR ON THE LIST.
///
/// ⭐ Under `interference` `Fit` states this as a UNIVERSAL rule — every holder must be
/// `customer` or `unrealised`, because the whole remainder is excess. Under `transition` that
/// would be wrong: part of the range is genuinely clearance, and a `booked` share is
/// legitimate there. A reserved block paid for and not fully drawn is exactly that. So the
/// rule weakens to PRESENCE, and the weakening is correct rather than a concession.
///
/// ⛔ WHAT CANNOT BE CHECKED HERE IS THE SIZE OF IT, and the reason is worth knowing
/// before trusting this test: the interference PORTION of a share is not a filed field, and
/// the magnitude the shares sum to has already swallowed it. `the_unserved_share_does_not_
/// exceed_the_derived_exposure` bounds it from the other direction, from demand and nameplate.
///
/// ⚠️ "UNSERVED" AND NOT "REFUSED": a reserved card that errors a request did refuse it, but a
/// caller who waits past their patience and leaves was refused by nobody. Both land in these two
/// holders, so the word must not decide which happened. `Layer/timeSlack` says it outright —
/// the holder does not get to refuse, the demand DECAYED.
///
/// ⚠️ `refutation#compute` failed this and nothing caught it, because the universal rule is
/// gated on `sign = interference` and that layer filed `clearance` at the mode. It is the
/// defect the third fit member exists to make visible.
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
                 any price. The {expo:.4} it could not serve therefore went UNSERVED rather \
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

/// ⭐⭐⭐ THE ONE PLACE THIS MODEL MEASURES SOMETHING WITH NO INSTRUMENT BEHIND IT.
///
/// Everywhere else a slack BOUNDS shares that were already filed. Here it closes an equation
/// over quantities a filer had to supply anyway:
///
/// ```text
/// max(0, demand.high - nameplate.low)  ≤  capacitySlack.high + SUM(unserved share highs)
/// ```
///
/// In words: what your own numbers say could have gone wrong is at most what you can absorb
/// plus what you admit went unserved. The SHORTFALL is the interesting number — the part of
/// a remainder that happened and that nothing recorded.
///
/// ⚠️ EVALUATED AT ONE CORNER, deliberately. The clearance and interference sides are
/// anti-correlated — clearance falls as demand rises and interference rises — so anything
/// summed across the range pairs the slack week's spare with the busy week's unserved demand and
/// reports a state that occurs in no week. At a single demand there is one value each.
///
/// ⛔⛔ AND IT CANNOT BE TESTED NON-VACUOUSLY AGAINST THIS CORPUS, WHICH IS RECORDED HERE
/// RATHER THAN LEFT TO BE DISCOVERED. Thirteen of twenty-one layers file `capacitySlack` as
/// `unmeasured` and six more are `none` with zero exposure, so the check is silent on
/// nineteen. NOT ONE LAYER FILES A NUMERIC `capacitySlack`. The single reachable case,
/// `enterprise-contract#capability`, passes exactly — `[1,2,3] + [1,1,2]` against an exposure
/// of `[2,3,5]` — but it is a PURE INTERFERENCE fit, where the exposure IS the magnitude's
/// high bound, so it is the sum rule at Holder wearing different clothes and proves nothing
/// new. ⭐ The guard below is therefore `1`, and a guard of `1` is the S-15 trap in progress.
/// The cure is a filer measuring how far a supply can run hot, not a figure invented to give
/// this rule something to chew on.
#[test]
fn the_unserved_share_does_not_exceed_the_derived_exposure() {
    let mut checked = 0;
    for (name, doc) in corpus() {
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

            // A slack that is `unmeasured` suspends the check: the ceiling is unknown, not
            // zero. `none` is a MEASURED zero and contributes nothing, which is the case
            // that makes the inequality bite.
            let absorbable = match &l.supply.nameplate.capacity_slack {
                StatedClaimType::Claim(c) => c.high,
                StatedClaimType::Absent(a) if a.reason == AbsenceReasonType::None => 0.0,
                StatedClaimType::Absent(_) => continue,
            };

            // One unstated unserved share suspends the sum, exactly as at Holder: what
            // went unserved is unknown, not zero.
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
                 have gone unserved. The supply can absorb {absorbable} and the document \
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
        "no layer pairs a positive exposure with a decidable capacity slack and stated \
         unserved shares; see this test's own note on why that number is 1"
    );
}

/// ⛔⛔ S-29. ALL THREE NARROWING KINDS ARE EXERCISED, AND WITHOUT THIS THEY WOULD NOT BE.
///
/// `narrowsWhen` was an optional bare string until this pass, which made its absence mean
/// three things at once — nobody said, nothing would narrow it, or there is no range. That
/// is the boolean anti-pattern in the one field carrying the model's falsifiability claim,
/// and it is the fourth time this shape has turned up: the three buffer slacks were
/// booleans, `Fit` was two members where ISO 286 has three, and a `lumpy boolean NOT NULL`
/// in the DDL met a document filing divisibility as a typed absence.
///
/// ⭐ The `kind` is what makes the width's COMPOSITION statable:
///
/// - `instrument` — the width is IGNORANCE. A better measurement reveals what was always
///   there. Eighteen of the corpus's twenty-three, and the reading `Claim`'s prose assumes.
/// - `intervention` — the width is VARIATION. Only changing the process reduces it. The
///   sharpest case is a month being `[672, 720, 744]` hours: billing on a fixed 30-day
///   cycle removes that, and NO instrument measures it away.
/// - `experiment` — the filer does not know which, and names what would settle it. This is
///   the honest third answer, and it is why the field is not an `ignorance | variation` flag.
///
/// ⚠️ A corpus using only `instrument` would leave two thirds of the enum untested while
/// every rule above it passed. Hence this test rather than trust.
#[test]
fn the_corpus_exercises_every_narrowing_kind() {
    // ⚠️ Counters rather than collected references: `corpus()` yields owned documents that
    // drop each iteration, so nothing borrowed from one outlives the loop.
    let (mut instrument, mut stated, mut not_applicable, mut unmeasured) = (0, 0, 0, 0);

    for (_, doc) in corpus() {
        for l in &doc.stack.layer {
            for c in [
                &l.demand,
                &l.time_slack,
                &l.supply.nameplate.amount,
                &l.supply.nameplate.capacity_slack,
                &l.supply.nameplate.inventory_slack,
            ] {
                let StatedClaimType::Claim(c) = c else {
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
        "no claim files `notApplicable`, so the point-value case — 59 of the corpus's 124 \
         claims — is unrepresented in what this test can see"
    );
    assert!(
        unmeasured > 0,
        "no claim files `unmeasured`, which was what the old blank usually meant"
    );

    // ⚠️ `intervention` and `experiment` sit on holder shares, coupling strengths and
    // conversion factors, which this walk does not reach. assets/sql/rules.sql groups
    // every narrowing in a document regardless of where it hangs, and reports the split.
}

/// ⭐⭐⭐ THE MODEL'S CENTRAL ASSUMPTION IS NOW COUNTABLE, AND THAT IS WHAT THE WRAPPER
/// BOUGHT. A stack asserts that its layers hold their remainders independently. `Coupling`'s
/// own annotation says a document with no couplings "is not evidence of independence; it is
/// a document where nobody looked" — and for two revisions the element it says that about was
/// `minOccurs="0" maxOccurs="unbounded"`, so the schema named the defect and then encoded it.
///
/// ⛔ THIS TEST DOES NOT DEMAND A PARTICULAR ANSWER. It demands that every stack GIVE one,
/// and that the corpus hold more than a single answer, because a field where every document
/// says the same thing is decoration.
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
                // ⭐ `notApplicable` is a claim about the STACK's shape rather than about
                // anybody's diligence: one layer, so there is no pair to couple.
                if a.reason == AbsenceReasonType::NotApplicable {
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

    // ⛔⛔ AND HERE IS THE READING THE OLD ENCODING COULD NOT PRODUCE. Not one stack in this
    // corpus files `none` — nobody has relieved a layer's constraint and watched the others
    // and reported independence. Every stack that declines says `unmeasured` or has no pair
    // to test, and one stack files a coupling that CONTRADICTS the assumption outright. That
    // is a fact about the evidence rather than about any one filing, and it is a fact only
    // because the empty list stopped being an answer.
    assert!(
        !reasons.contains(&"None".to_string()),
        "a stack now claims tested independence. That is a heavy claim and a welcome one — \
         update this test, and check that `Absence/note` says how it was established"
    );
}

/// ⭐⭐ A WINDOW'S ABSENCE IS FOUR DIFFERENT FACTS AND `Divisibility` ALREADY DESCRIBED THREE
/// OF THEM IN PROSE IT COULD NOT FILE. It says a window is MALFORMED on a unit with no
/// denominator, and it used to say a supply that is always on "does not need saying so" —
/// `notApplicable` and `none`, encoded identically as a missing element, and indistinguishable
/// from nobody having asked.
///
/// ⛔ THE RULE THE DISTINCTION BUYS BACK IS THE ONE THE ELEMENT ASKS FOR. `q / clearance`
/// assumes the spare is spread evenly across the denominator; a window denies it. So a filed
/// window forbids a `derived` time slack — and so does `unmeasured`, because nobody knows
/// whether the spare is spread evenly, which is the case the old rule could not reach.
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

            // `notApplicable` is a claim about the UNIT, and the unit is right there.
            if let Some(a) = absence {
                if a.reason == AbsenceReasonType::NotApplicable {
                    if let Some((_, _, _, unit)) = stated(&l.supply.nameplate.amount) {
                        assert!(
                            !unit.contains(" per ") && !unit.contains(" por "),
                            "{name} `{}`: the window question is malformed only where the unit \
                             has no denominator, and `{unit}` has one",
                            l.name
                        );
                    }
                }
                reasons.push(format!("{:?}", a.reason));
            }

            let derivable = absence.is_some_and(|a| {
                matches!(
                    a.reason,
                    AbsenceReasonType::None | AbsenceReasonType::NotApplicable
                )
            });
            if !derivable {
                if let StatedClaimType::Absent(a) = &l.time_slack {
                    assert_ne!(
                        a.reason,
                        AbsenceReasonType::Derived,
                        "{name} `{}`: the supply is intermittent, or nobody has said it is not, \
                         so the spare is not spread evenly across the denominator and a time \
                         slack cannot be computed from the clearance",
                        l.name
                    );
                }
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

/// ⭐⭐⭐ WHO OWNS THE EDGE OF THIS RANGE. `Claim/boundOrigin` was an optional bare
/// enumeration and it was filed ONCE IN 124 CLAIMS — which `Nameplate/capacitySlack`'s own
/// annotation complains about, three types away, while asking for exactly this field.
///
/// ⛔ AN OPTIONAL FIELD NOBODY FILLS IS NOT A WEAK SIGNAL, IT IS AN ABSENT ONE, and its blank
/// could not separate "nobody has asked" from "NOTHING sets this bound — the range is where
/// the measurements fell". It is a required `StatedConstraintOrigin` now, and the interesting
/// result came out of filing it rather than out of the change itself.
///
/// ⭐⭐ THE MODEL ALREADY ANSWERS THIS QUESTION IN A SIBLING ELEMENT FOR HALF THE CORPUS.
/// `Nameplate/amountOrigin` says who could hold a different number; `LumpyQuantum/origin` says
/// who sets the size of one. Where a sibling states it, the claim files `derived` and points
/// there rather than restating it — which is the same argument `Absence` makes about `derived`
/// generally: a value sent here could disagree with its own inputs.
#[test]
fn every_claim_says_who_owns_the_edge_of_its_range() {
    let mut origins = Vec::new();
    let mut reasons = Vec::new();
    let mut derived_beside_a_sibling = 0;

    for (name, doc) in corpus() {
        for l in &doc.stack.layer {
            let mut check = |what: &str, c: &StatedClaimType, sibling: bool| {
                let StatedClaimType::Claim(c) = c else { return };
                match &c.bound_origin {
                    StatedConstraintOriginType::Origin(o) => origins.push(format!("{o:?}")),
                    StatedConstraintOriginType::Absent(a) => {
                        if a.reason == AbsenceReasonType::Derived {
                            assert!(
                                sibling,
                                "{name} `{}` {what}: `derived` says the author of this edge is \
                                 stated elsewhere, and there is no sibling element here that \
                                 states one. A receiver following the pointer finds nothing",
                                l.name
                            );
                            derived_beside_a_sibling += 1;
                        }
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

            // ⭐ `amount` sits beside `amountOrigin`, and a lumpy `size` beside its own
            // `origin`; `demand` and a `draw` sit beside nothing at all.
            check("demand", &l.demand, false);
            check("timeSlack", &l.time_slack, false);
            check("nameplate", &l.supply.nameplate.amount, true);
            check("capacitySlack", &l.supply.nameplate.capacity_slack, false);
            check("inventorySlack", &l.supply.nameplate.inventory_slack, false);
            if let Some(q) = lumpy(l) {
                check("quantum", &q.size, true);
            }
        }
    }

    assert!(
        derived_beside_a_sibling >= 20,
        "only {derived_beside_a_sibling} claims point at a sibling for their origin; the whole \
         finding here is that the model already answered this for the nameplate half of the \
         corpus and had no way to say so"
    );
    origins.sort();
    origins.dedup();
    reasons.sort();
    reasons.dedup();
    assert!(
        origins.len() >= 2 && reasons.len() >= 2,
        "{origins:?} stated and {reasons:?} declined; a field where every claim gives the same \
         answer proves nothing about the distinction it was added for"
    );
}
