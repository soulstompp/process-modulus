//! Two members of one group, filed under two regimes, and the third document that
//! consolidates them.
//!
//! ⭐ This is not a parser check. `coverage_parse.rs` asks whether two witnesses
//! ANSWERING one corpus stay comparable; this file asks the harder question one step
//! further in: whether two independently authored STACKS can be merged at all. A
//! consolidator holding a parent and a subsidiary has to answer it before adding up
//! a single number.
//!
//! ⛔⛔ AND THE ANSWER FROM THE TWO MEMBERS ALONE IS NO, IN BOTH DIRECTIONS AT ONCE.
//! Joining on the layer NAME merges two unrelated vendor contracts and reports success.
//! Joining on the FACTS FILED misses the pair that is genuinely one layer, and misses it
//! BECAUSE one side is better instrumented. Two strategies, wrong in opposite directions,
//! on one pair of honest documents. Both are asserted below, in the direction that is
//! true, so that they stay demonstrations rather than aspirations.
//!
//! ⭐⭐⭐ THE REPAIR IS NOT IN EITHER MEMBER. Neither entity has seen the other's stack,
//! neither has standing to name the other's layers, and a filing cannot cite a list
//! published after it. The composer supplies the mapping IN ITS OWN FILING and signs it,
//! and every test after `the_composition_parses…` is the merge succeeding through that
//! document rather than through a heuristic.
//!
//! ⭐ That document is `asrt:composition`, and its three types are the whole vocabulary:
//! a `Fusion` says which filed layers are ONE layer and why, a `Part` carries one filed
//! layer in with the `factor` that puts it in the composed unit, and an `Elimination`
//! says what was removed so the fused figure is not the sum. A composed layer with no
//! fusion is the third state — one the composer ORIGINATED.
//!
//! ⚠️ **The composition tests are not all here, and the split is by what they answer to.**
//! This file reads the corpus, so every assertion is about documents that claim something
//! about a business. `tests/fixtures.rs` holds the sum rule's stipulations and the negative
//! controls, which mutate a parsed fusion in memory to prove the checker bites;
//! `tests/corpus_parse.rs` holds `a_window_is_carried_through_a_fusion_and_never_summed`,
//! because a window is a property of the stock half that a fusion must not touch; and
//! `tests/state_coverage.rs` walks compositions for the table of every admitted state.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;

use process_modulus::asrt::{
    CompositionType, EliminationAgainstType, EliminationType, FusionType, PartType,
    StatedEliminationsTypeContent,
};
use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, AbsenceType, FitType, HolderKindType, LayerType, ProcessModulusElementType,
    RemainderType, StatedBorrowedTermType, StatedClaimType, StatedFitType, StatedHolderType,
    StatedRemainderType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

const US: &str = "merge-us-member.xml";
const PT: &str = "merge-pt-member.xml";
const GROUP: &str = "merge-group-composition.xml";
const HOLDING: &str = "merge-holding-composition.xml";

fn read(name: &str) -> String {
    let path = format!("{}/assets/corpus/{name}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

fn load(name: &str) -> ProcessModulusElementType {
    let xml = read(name);
    let mut reader = SliceReader::new(&xml);
    ProcessModulusElementType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{name}: {e}"))
}

fn composed(name: &str) -> CompositionType {
    let xml = read(name);
    let mut reader = SliceReader::new(&xml);
    CompositionType::deserialize(&mut reader).unwrap_or_else(|e| panic!("{name}: {e}"))
}

fn composition() -> CompositionType {
    composed(GROUP)
}

/// ⭐⭐ THE CATALOGUE, AND IT BELONGS TO THIS TEST RATHER THAN TO ANY DOCUMENT.
///
/// `FiledLayer/filing/notation` is the URI of another filing, and its annotation is
/// explicit that nothing validates it: "an implementer that can fetch the other filing
/// still owes the check; one that cannot owes the reader the knowledge that it did not
/// happen." This function is this crate paying that debt, for the four documents it
/// happens to hold. ⛔ A receiver holding filings it cannot fetch owes the second half
/// instead, and must not silently skip the reconciliation below.
///
/// ⚠️ A NOTATION DOES NOT SAY WHICH KIND OF DOCUMENT IT NAMES, and once compositions nest
/// that matters: a layer sits at `/pm:processModulus/…` in a plain filing and one level
/// deeper, at `/asrt:composition/pm:processModulus/…`, in a composition. A real resolver
/// reads the root element. Here the pairing is a `match`, which is the same knowledge held
/// less honestly.
fn resolve(notation: &str) -> &'static str {
    match notation {
        "urn:example:filing:us-member:2026-08-31" => US,
        "urn:example:filing:pt-member:2026-08-31" => PT,
        "urn:example:filing:group-parent:2026-08-31" => GROUP,
        other => panic!("no filing in this repository is published at `{other}`"),
    }
}

fn is_composition(name: &str) -> bool {
    name == GROUP || name == HOLDING
}

/// The stack a notation resolves to, whichever kind of document it turns out to be.
fn filing(name: &str) -> ProcessModulusElementType {
    if is_composition(name) {
        composed(name).process_modulus
    } else {
        load(name)
    }
}

fn names(doc: &ProcessModulusElementType) -> BTreeSet<&str> {
    doc.stack.layer.iter().map(|l| l.name.as_str()).collect()
}

fn layer<'a>(doc: &'a ProcessModulusElementType, name: &str) -> &'a LayerType {
    doc.stack
        .layer
        .iter()
        .find(|l| l.name == name)
        .unwrap_or_else(|| panic!("no layer named `{name}`"))
}

/// The layer's unit, taken from its demand. Every quantity on a layer is in it.
fn unit(l: &LayerType) -> &str {
    match &l.demand {
        StatedClaimType::Claim(c) => c.unit.as_str(),
        StatedClaimType::Absent(_) => panic!("`{}`: demand is not stated", l.name),
    }
}

fn remainder(l: &LayerType) -> &RemainderType {
    match &l.remainder {
        StatedRemainderType::Remainder(r) => r,
        StatedRemainderType::Absent(_) => panic!("`{}`: no remainder is stated", l.name),
    }
}

fn fit(l: &LayerType) -> &FitType {
    match &remainder(l).sign {
        StatedFitType::Fit(f) => f,
        StatedFitType::Absent(_) => panic!("`{}`: the fit is not stated", l.name),
    }
}

fn holder_kinds(l: &LayerType) -> Vec<&HolderKindType> {
    remainder(l)
        .holder
        .iter()
        .filter_map(|h| match h {
            StatedHolderType::Holder(h) => Some(&h.kind),
            StatedHolderType::Absent(_) => None,
        })
        .collect()
}

/// The taxonomy every absorber in a document cites. This is the authority question,
/// asked of the one borrowed term that carries the model's own argument.
fn absorber_authorities(doc: &ProcessModulusElementType) -> BTreeSet<&str> {
    doc.stack
        .layer
        .iter()
        .filter_map(|l| match &remainder(l).absorber {
            StatedBorrowedTermType::Term(t) => Some(t.taxonomy.as_str()),
            StatedBorrowedTermType::Absent(_) => None,
        })
        .collect()
}

#[test]
fn both_members_parse_and_declare_what_they_report_under() {
    for name in [US, PT] {
        let doc = load(name);
        assert!(
            !doc.stack.layer.is_empty(),
            "{name}: a stack with no layers describes nothing"
        );
        assert!(
            !doc.regime.is_empty(),
            "{name}: a member of a group that does not say what it reports under \
             cannot be consolidated with anything"
        );
    }
}

/// ⭐⭐ WHAT COMPARES FOR FREE, AND IT IS MORE THAN IT LOOKS.
///
/// `Fit` and `HolderKind` are closed sets contributed by THIS namespace, so a value read
/// out of a United States filing and a value read out of a Portuguese one are the same
/// value. No mapping, no authority, no negotiation. That is the entire return on refusing
/// to borrow these.
///
/// ⚠️ THE THREE BUFFER SLACKS USED TO BE ON THIS LIST AND NO LONGER BELONG ON IT. They
/// were booleans, which compare for free because there are only two of them; they are now
/// quantities in each layer's own unit, and two filings agree about a slack only when they
/// agree about a unit. That is a real loss and it buys the ability to say `barely`.
///
/// ⚠️ NOTE WHAT THIS TEST HAD TO DO TO RUN AT ALL: it pairs `labour` with `pessoal`
/// BY HAND, because I read both documents and know they are one layer. Nothing in
/// either file says so. That is what the composition supplies.
#[test]
fn the_contributed_vocabulary_compares_with_no_authority_at_all() {
    let (us, pt) = (load(US), load(PT));
    let (us_labour, pt_labour) = (layer(&us, "labour"), layer(&pt, "pessoal"));

    assert_eq!(
        fit(us_labour),
        fit(pt_labour),
        "both members are short of people and both said so with the same word, which \
         is a word neither of them had to look up"
    );

    for l in [us_labour, pt_labour] {
        assert!(
            holder_kinds(l).contains(&&HolderKindType::People),
            "`{}`: both filings put people among the holders, and `people` means the \
             same thing in both because this namespace owns it",
            l.name
        );
    }

    // ⭐ AND THE DIFFERENCE IS AS LEGIBLE AS THE AGREEMENT. Portugal's hours bank
    // gives part of the same absorption a counterparty, so a `booked` holder stands
    // beside the `people` one. The US member has no such instrument and files one
    // holder. Neither filing is wrong; the countries differ.
    assert!(
        holder_kinds(pt_labour).contains(&&HolderKindType::Booked)
            && !holder_kinds(us_labour).contains(&&HolderKindType::Booked),
        "the visible half of the Portuguese remainder is the finding this pair exists \
         to carry: an instrument exists there and does not here"
    );
}

/// ⭐⭐ WHAT COMPARES ONLY ON PRESENTATION OF AN AUTHORITY, WHICH IS THE POINT OF
/// `BorrowedTerm`.
///
/// Both members absorb into Hopp & Spearman's buffers and most of the time cite the
/// same URI, so those rows compare directly. One Portuguese layer cites a TRANSLATED
/// EDITION of the same three buffers, and the schema's answer is neither to merge
/// them nor to reject the document: it is to make the fork visible to whoever can
/// resolve it.
///
/// ⛔ A BARE CODE WOULD HAVE MADE THIS A DISAGREEMENT. `capacity` and `capacidade`
/// as plain strings are two unequal values and nothing more. With the taxonomy
/// carried, a receiver can see that two editions of one vocabulary are in play,
/// which is a completely different problem with a completely different fix.
#[test]
fn a_borrowed_term_compares_only_where_the_two_cite_one_authority() {
    let (us, pt) = (load(US), load(PT));
    let (a, b) = (absorber_authorities(&us), absorber_authorities(&pt));

    let shared: BTreeSet<_> = a.intersection(&b).copied().collect();
    assert!(
        !shared.is_empty(),
        "the two members must share at least one buffer authority or their absorbers \
         are not comparable at all"
    );

    let only_pt: BTreeSet<_> = b.difference(&a).copied().collect();
    assert!(
        !only_pt.is_empty(),
        "this pair exists partly to show a fork. If it ever disappears, the example \
         stopped exercising the case rather than the case going away"
    );

    // Where the authority is shared the values agree; where it forks they do not,
    // and the taxonomy is the only thing that can tell those two situations apart.
    let value_under = |doc: &ProcessModulusElementType, authority: &str| -> BTreeSet<String> {
        doc.stack
            .layer
            .iter()
            .filter_map(|l| match &remainder(l).absorber {
                StatedBorrowedTermType::Term(t) if t.taxonomy == authority => Some(t.value.clone()),
                _ => None,
            })
            .collect()
    };
    let authority = shared.iter().next().copied().unwrap();
    assert_eq!(
        value_under(&us, authority),
        value_under(&pt, authority),
        "under one authority the two members absorb into the same buffer, and that \
         row of the merge needs no adjudication"
    );
}

/// ⭐ THE NATIONAL HALF, WHICH IS `coverage_parse.rs`'s PROPERTY ARRIVING IN A STACK.
///
/// The charts share nothing and are supposed to. Portugal publishes a national chart
/// and the entity borrows it; the United States publishes none and the entity has to
/// name itself. A merge that joined on chart position would be comparing unrelated
/// strings, and the taxonomy is what stops it.
#[test]
fn the_two_members_report_into_charts_that_share_no_authority() {
    let (us, pt) = (load(US), load(PT));

    let charts = |doc: &ProcessModulusElementType| -> BTreeSet<String> {
        doc.regime
            .iter()
            .filter_map(|r| match &r.chart {
                StatedBorrowedTermType::Term(t) => Some(t.taxonomy.clone()),
                StatedBorrowedTermType::Absent(_) => None,
            })
            .collect()
    };
    let (a, b) = (charts(&us), charts(&pt));
    assert!(!a.is_empty() && !b.is_empty());
    assert!(
        a.is_disjoint(&b),
        "two members of one group in two countries do not share a chart, and a \
         document that implied they did would be hiding the consolidation entry"
    );
}

// ======================================================================================
// THE TWO JOINS A CONSOLIDATOR CAN ATTEMPT WITH THE MEMBER FILINGS ALONE, AND WHY
// NEITHER IS SOUND. ⚠️ Both are asserted in the direction that is TRUE, so they are
// demonstrations rather than aspirations: if either ever flips, the examples stopped
// exercising the case and the composition below has nothing left to repair.
// ======================================================================================

/// ⛔⛔ JOIN ON THE NAME: A FALSE POSITIVE, AND A SILENT ONE.
///
/// `xs:key layerName` is document-scoped: it guarantees `name` is unique inside one
/// file and says nothing whatever about a second. So the join key across two filings
/// is a bare `xs:token`, and the two `compute` layers are two unrelated vendor
/// contracts that happen to have been given one word by two teams who never spoke.
///
/// The cheapest necessary condition for a join is that both sides be measured in the
/// same unit. It fails, and nothing in either document is able to say so.
#[test]
fn joining_two_filings_on_the_layer_name_produces_a_false_positive() {
    let (us, pt) = (load(US), load(PT));

    let joined: Vec<&str> = names(&us).intersection(&names(&pt)).copied().collect();
    assert!(
        !joined.is_empty(),
        "the two members must share at least one layer name or there is no join to test"
    );

    assert!(
        joined.iter().any(|name| {
            let (a, b) = (layer(&us, name), layer(&pt, name));
            unit(a) != unit(b)
        }),
        "at least one name-join must pair two layers whose quantities cannot be added, \
         or this pair of documents has stopped carrying the collision it exists for"
    );
}

/// Everything about a layer that this namespace owns outright, as a join key. This is
/// the fallback a consolidator reaches for once names have failed: match on the facts.
/// A stated slack reduced to the fact, and never to the prose beside it.
///
/// ⛔⛔ `Absence/note` IS PROSE, AND PROSE IS WRITTEN IN THE FILER'S OWN LANGUAGE. Debugging
/// the whole `StatedClaim` swept the note into the fingerprint, so two layers agreed only
/// while both filings happened to be written in English. Translating the Portuguese member
/// broke it, which is the right failure: it was reporting a property of the WRITING as a
/// property of the supply. The reason is the fact this namespace owns; the note is not.
fn slack_fact(s: &StatedClaimType) -> String {
    match s {
        StatedClaimType::Claim(c) => format!("{},{},{},{}", c.low, c.most_likely, c.high, c.unit),
        StatedClaimType::Absent(a) => format!("{:?}", a.reason),
    }
}

fn fingerprint(l: &LayerType) -> String {
    let mut kinds: Vec<String> = holder_kinds(l).iter().map(|k| format!("{k:?}")).collect();
    kinds.sort();
    format!(
        "{:?}|{}|{}|{}|{}",
        fit(l),
        slack_fact(&l.time_slack),
        slack_fact(&l.supply.nameplate.capacity_slack),
        slack_fact(&l.supply.nameplate.inventory_slack),
        kinds.join(",")
    )
}

/// ⛔⛔ JOIN ON THE FACTS: A FALSE NEGATIVE, AND IT PENALISES THE BETTER FILING.
///
/// `labour` and `pessoal` ARE one layer and their fingerprints differ. They differ
/// because the Portuguese filing carries an extra holder, and it carries an extra
/// holder precisely BECAUSE its jurisdiction supplies an instrument that makes part of
/// the same remainder visible. ⭐ Being better instrumented is what broke the match.
///
/// ⭐⭐ AND THE SAME KEY MATCHES THE PAIR THAT IS NOT ONE LAYER, which is the half that
/// makes this a missing field rather than a missing heuristic. Both strategies wrong, in
/// opposite directions, on one pair of honest documents. No cleverness recovers an
/// identity that was never filed.
#[test]
fn joining_two_filings_on_the_facts_produces_a_false_negative() {
    let (us, pt) = (load(US), load(PT));

    assert_ne!(
        fingerprint(layer(&us, "labour")),
        fingerprint(layer(&pt, "pessoal")),
        "these two ARE one layer, and if the facts ever recognise them as one the \
         example stopped carrying the asymmetric instrument that is the whole point"
    );

    assert_eq!(
        fingerprint(layer(&us, "compute")),
        fingerprint(layer(&pt, "compute")),
        "these two are NOT one layer — different vendor, different contract, different \
         unit — and every fact this namespace owns agrees across them"
    );
}

// ======================================================================================
// THE MERGE, THROUGH THE COMPOSITION. ⭐ Everything below is the repair: a third filing,
// by the one party with standing to make it, saying what it treated as one and what it
// removed to do so.
// ======================================================================================

/// A three-point interval, in the order the schema files it.
type Triple = (f64, f64, f64);

/// One of the three quantities `Elimination/against` names, with the accessor that reads
/// it off a layer. ⭐ The model insists these are THREE and not two, so a check that walks
/// them walks all three or it is not checking the model.
type Quantity = (
    EliminationAgainstType,
    fn(&LayerType) -> Triple,
    &'static str,
);

/// ⚠️ NOT EXACT EQUALITY, AND THE REASON IS ARITHMETIC RATHER THAN TASTE. `Claim` holds
/// f64, and `10.0 - 10.4` is `-0.40000000000000036` in doubles: 7,168 of the 39,601
/// one-decimal pairs below 20 fail an exact `==` on their own sum. A tolerance is a
/// policy number, which is why the model states this rule in prose and leaves the number
/// to whoever runs the check.
const TOLERANCE: f64 = 1e-9;

fn close(a: Triple, b: Triple) -> bool {
    (a.0 - b.0).abs() < TOLERANCE && (a.1 - b.1).abs() < TOLERANCE && (a.2 - b.2).abs() < TOLERANCE
}

fn add(a: Triple, b: Triple) -> Triple {
    (a.0 + b.0, a.1 + b.1, a.2 + b.2)
}

/// ⭐⭐ COMPONENT-WISE, AND IT DOES NOT REVERSE BOUNDS, WHICH IS THE OPPOSITE OF
/// `magnitude` below. An elimination removes a COMPONENT OF the figure it is taken from,
/// so the low case of the total already carries the low case of the component. A
/// remainder subtracts an INDEPENDENT quantity, so there the bounds do reverse.
fn eliminate(total: Triple, removed: Triple) -> Triple {
    (
        total.0 - removed.0,
        total.1 - removed.1,
        total.2 - removed.2,
    )
}

fn triple(s: &StatedClaimType) -> Option<Triple> {
    match s {
        StatedClaimType::Claim(c) => Some((c.low, c.most_likely, c.high)),
        StatedClaimType::Absent(_) => None,
    }
}

fn demand(l: &LayerType) -> Triple {
    triple(&l.demand).unwrap_or_else(|| panic!("`{}`: demand is not stated", l.name))
}

fn nameplate(l: &LayerType) -> Triple {
    triple(&l.supply.nameplate.amount)
        .unwrap_or_else(|| panic!("`{}`: nameplate is not stated", l.name))
}

fn draw(l: &LayerType) -> Triple {
    triple(&l.supply.jagged.draw).unwrap_or_else(|| panic!("`{}`: draw is not stated", l.name))
}

/// `nameplate - demand`, KEEPING THE SIGN, with the bound reversal the subtraction of two
/// independent quantities requires. `magnitude` below is this with the sign thrown away,
/// and the sign is what one test here exists to watch.
fn signed(l: &LayerType) -> Triple {
    let (n, d) = (nameplate(l), demand(l));
    (n.0 - d.2, n.1 - d.1, n.2 - d.0)
}

/// `|nameplate - demand|`, with the bound reversal the subtraction requires.
fn magnitude(l: &LayerType) -> Triple {
    let (n, d) = (nameplate(l), demand(l));
    let signed = (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    let (lo, hi) = (signed.0.abs(), signed.2.abs());
    // A signed interval straddling zero reaches a magnitude of exactly zero inside its
    // own range, so the low bound is 0 rather than the nearer endpoint.
    let low = if signed.0 <= 0.0 && signed.2 >= 0.0 {
        0.0
    } else {
        lo.min(hi)
    };
    (low, signed.1.abs(), lo.max(hi))
}

fn fusion<'a>(c: &'a CompositionType, name: &str) -> &'a FusionType {
    c.fusion
        .iter()
        .find(|f| f.name == name)
        .unwrap_or_else(|| panic!("no fusion composes `{name}`"))
}

/// The eliminations a fusion filed, or an empty slice where it filed a typed reason instead.
///
/// ⛔⛔ AN EMPTY SLICE IS NOT `absent reason="none"`, AND `expected` BELOW IS WHERE THAT COSTS
/// SOMETHING. `Fusion/eliminations` used to be `minOccurs="0" maxOccurs="unbounded"`, so a
/// composer who checked for double counting and found none produced the same bytes as one who
/// never looked — and the sum rule the `Elimination` type exists to make EXACT quietly went
/// back to being a warning for every fusion that filed nothing. Three of this corpus's eight
/// fusions are in that state.
fn eliminations(f: &FusionType) -> Vec<&EliminationType> {
    f.eliminations
        .content
        .iter()
        .filter_map(|e| match e {
            StatedEliminationsTypeContent::Elimination(e) => Some(e),
            StatedEliminationsTypeContent::Absent(_) => None,
        })
        .collect()
}

/// The typed reason a fusion filed no eliminations, if that is what it filed.
fn elimination_absence(f: &FusionType) -> Option<&AbsenceType> {
    f.eliminations.content.iter().find_map(|e| match e {
        StatedEliminationsTypeContent::Absent(a) => Some(a),
        StatedEliminationsTypeContent::Elimination(_) => None,
    })
}

/// The couplings a stack filed, or an empty slice where it filed a typed reason instead.
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

fn elimination_against(f: &FusionType, against: EliminationAgainstType) -> &EliminationType {
    eliminations(f)
        .into_iter()
        .find(|e| e.against == against)
        .unwrap_or_else(|| {
            panic!(
                "`{}` files no elimination against {against:?}, so a reader cannot tell \
                 whether that quantity double counts or whether nobody looked",
                f.name
            )
        })
}

/// The filed layers a fusion names, as `(party, layer name)`.
fn parts(f: &FusionType) -> Vec<(&str, &str)> {
    f.part
        .iter()
        .map(|p| (p.layer.party.as_str(), p.layer.filing.id.as_str()))
        .collect()
}

#[test]
fn the_composition_parses_and_is_signed_by_a_party_that_filed_neither_member() {
    let c = composition();

    assert!(
        !c.witness.is_empty() && !c.observed_at.is_empty(),
        "a composed stack is an assertion that two entities are ONE SYSTEM. \
         `Dependence` rejects that assertion when it comes from a filer; it stands only \
         because a parent signs it, so an unsigned or undated one is a fabrication"
    );

    let members: BTreeSet<&str> = c
        .fusion
        .iter()
        .flat_map(|f| f.part.iter().map(|p| p.layer.party.as_str()))
        .collect();
    assert!(
        !members.contains(c.witness.as_str()),
        "the composer is a party to none of the filings it composes; a witness who filed \
         an end is in the wrong document"
    );

    assert!(
        !c.fusion.is_empty(),
        "a composition naming nothing it was built from is an unsourced filing that \
         looks sourced"
    );
}

/// ⭐⭐⭐ THE FALSE NEGATIVE, REPAIRED. The fingerprint join could not see that `labour`
/// and `pessoal` are one layer. The composer says so, by name, in a document the
/// composer attests to — and the reason is prose, because a fungibility judgement is a
/// claim a reader is entitled to disagree with rather than a fact a validator can settle.
#[test]
fn the_composition_says_which_filed_layers_are_one_layer() {
    let c = composition();
    let f = fusion(&c, "labour");

    assert_eq!(
        parts(f),
        vec![("us-member", "labour"), ("pt-member", "pessoal")],
        "the pair the fact-based join missed, filed as one composed layer"
    );

    assert!(
        f.observed.contains("fungib") || f.observed.contains("queue"),
        "`FUSE ONLY WHAT IS FUNGIBLE` is the whole claim a fusion makes, and a fusion \
         whose `observed` does not say why these are one layer has asserted it silently"
    );

    // And the two parts really are the layers the earlier join could not pair.
    let (us, pt) = (load(US), load(PT));
    assert_ne!(
        fingerprint(layer(&us, "labour")),
        fingerprint(layer(&pt, "pessoal"))
    );
}

/// ⭐⭐⭐ THE FALSE POSITIVE, REPAIRED, AND NOT BY A HEURISTIC. Two one-part fusions
/// under two names. A fusion of one part is not degenerate: it is the composer saying
/// "I read this layer, it fuses with nothing, I carried it through" — and `observed` is
/// required, so they had to say why.
#[test]
fn the_composition_tells_the_two_compute_layers_apart() {
    let c = composition();

    assert_eq!(
        parts(fusion(&c, "compute-us")),
        vec![("us-member", "compute")]
    );
    assert_eq!(
        parts(fusion(&c, "compute-pt")),
        vec![("pt-member", "compute")]
    );

    // Both members filed the layer under one token; the composer filed them under two.
    let composed: BTreeSet<&str> = c.fusion.iter().map(|f| f.name.as_str()).collect();
    assert!(
        !composed.contains("compute"),
        "carrying the colliding token forward would have preserved the collision"
    );

    for name in ["compute-us", "compute-pt"] {
        assert!(
            !fusion(&c, name).observed.trim().is_empty(),
            "`{name}` was separated by a party who looked, and the reason is the repair"
        );
    }
}

/// ⭐⭐ A CONSOLIDATION RULE A VALIDATOR CAN ACTUALLY ENFORCE, re-implemented here for
/// `dependence_parse.rs`'s stated reason: a document reaching this crate through some
/// other path — an API, a database, a hand-built value — was never validated at all.
#[test]
fn no_filed_layer_is_consolidated_twice() {
    let c = composition();
    let mut seen: BTreeMap<(&str, &str), &str> = BTreeMap::new();

    for f in &c.fusion {
        for p in &f.part {
            let key = (p.layer.filing.notation.as_str(), p.layer.filing.id.as_str());
            if let Some(first) = seen.insert(key, f.name.as_str()) {
                panic!(
                    "{}#{} is consolidated into both `{first}` and `{}`, which counts it \
                     twice in the group's figures",
                    key.0, key.1, f.name
                );
            }
        }
    }
    assert!(!seen.is_empty());
}

#[test]
fn every_fusion_names_a_layer_the_composer_actually_filed() {
    let c = composition();
    let composed = names(&c.process_modulus);

    for f in &c.fusion {
        assert!(
            composed.contains(f.name.as_str()),
            "`{}` is composed out of {} filed layer(s) and is not in the composed stack, \
             so the parts were folded into nothing",
            f.name,
            f.part.len()
        );
    }
}

/// ⭐ THE THIRD STATE, AND IT NEEDS NO MACHINERY. A composed layer that no fusion names
/// is one the composer ORIGINATED: the parent staffs the out-of-hours rota itself and
/// neither member files it. A parent is an entity too.
#[test]
fn a_composed_layer_with_no_fusion_is_one_the_composer_originated() {
    let c = composition();
    let fused: BTreeSet<&str> = c.fusion.iter().map(|f| f.name.as_str()).collect();

    let originated: Vec<&str> = names(&c.process_modulus)
        .into_iter()
        .filter(|n| !fused.contains(n))
        .collect();

    assert_eq!(
        originated,
        vec!["on-call"],
        "the rota is the group's own layer, and a model that forced every composed layer \
         to come from a member could not file it at all"
    );

    // ⭐⭐ AND IT IS COUPLED TO A FUSED LAYER WITHOUT BEING PART OF ONE, which is the
    // distinction this whole document turns on. `pm:Coupling` is reachable only because
    // the composition carries a real stack; a mapping-only document could not say it.
    assert!(
        couplings(&c.process_modulus.stack).iter().any(|k| {
            (k.from == "labour" && k.to == "on-call") || (k.from == "on-call" && k.to == "labour")
        }),
        "coupled and not fused: relieving delivery headcount moves the rota, and they are \
         still two layers because an extra engineer on the rota delivers no features"
    );
}

/// One part's quantity put in the composed layer's unit — or `None` when the composer
/// filed a conversion they could not size.
///
/// ⛔⛔ NO `factor` ELEMENT AND A `factor` OF 1 ARE DIFFERENT DOCUMENTS AND THIS KEEPS THEM
/// APART. Absent means the part is already in the composed unit and nothing was converted.
/// An `unmeasured` factor means a conversion IS needed and nobody has sized it, which makes
/// the sum uncomputable in exactly the way an unsized elimination does — not zero, and not
/// one either.
///
/// ⭐ THE PRODUCT IS COMPONENT-WISE, AND THAT IS SAFE ONLY HERE. Interval multiplication in
/// general takes the extremes of four corner products, because a factor spanning zero
/// reorders the bounds. A unit conversion is strictly positive, so `low·low` really is the
/// low bound. Nothing outside this function may assume that.
fn convert(t: Triple, p: &PartType) -> Option<Triple> {
    match &p.factor {
        None => Some(t),
        Some(StatedClaimType::Claim(c)) => {
            assert!(
                c.low > 0.0,
                "a unit conversion is strictly positive; the component-wise product below \
                 is wrong for a factor that reaches zero"
            );
            Some((t.0 * c.low, t.1 * c.most_likely, t.2 * c.high))
        }
        Some(StatedClaimType::Absent(_)) => None,
    }
}

/// What a fusion's parts sum to for one quantity, once its eliminations are taken out —
/// or `None` when the composer could not size an elimination.
///
/// ⛔⛔ `None` IS NOT ZERO AND MUST NOT BE COLLAPSED INTO ONE. `sum()` over a missing
/// value silently returns the sum of the rest, which is a clean pass on a false equation
/// — the exact defect `Absence` exists to prevent, reintroduced by the checker.
/// ⚠️ `none` as an absence REASON is different again, and does mean zero: it is the
/// composer saying they looked and there was nothing to remove.
///
/// ⭐ A PART IS CONVERTED BEFORE IT IS ADDED, and an elimination is not converted at all:
/// it is already stated in the composed unit. See `convert`.
fn expected(
    f: &FusionType,
    against: EliminationAgainstType,
    of: fn(&LayerType) -> Triple,
) -> Option<Triple> {
    let mut total = (0.0, 0.0, 0.0);
    for p in &f.part {
        // ⭐ `filing` and not `load`: at the second level a part names a layer inside
        // another COMPOSITION's embedded stack, and the arithmetic does not care which.
        let doc = filing(resolve(&p.layer.filing.notation));
        total = add(total, convert(of(layer(&doc, &p.layer.filing.id)), p)?);
    }

    // ⛔⛔ AND THE SUSPENSION APPLIES AT THE LIST LEVEL TOO, WHICH IS THE WHOLE REASON
    // `Fusion/eliminations` IS A WRAPPER. A composer who never looked for double counting
    // owes no equation; reading their empty list as "nothing to remove" is the same clean
    // pass on a false sum that an unsized elimination produces one level down, and it used
    // to be unavoidable because an unchecked fusion and a checked-clean one were one shape.
    if let Some(a) = elimination_absence(f) {
        if a.reason == AbsenceReasonType::Unmeasured {
            return None;
        }
    }

    for e in eliminations(f).into_iter().filter(|e| e.against == against) {
        match &e.quantity {
            StatedClaimType::Claim(c) => total = eliminate(total, (c.low, c.most_likely, c.high)),
            StatedClaimType::Absent(a) if a.reason == AbsenceReasonType::None => {}
            StatedClaimType::Absent(_) => return None,
        }
    }
    Some(total)
}

/// ⭐⭐⭐ THE RULE THAT COULD NOT BE WRITTEN UNTIL `Elimination` EXISTED.
///
/// Before it, a checker comparing a fused figure against the sum of its parts had no way
/// to tell an elimination from an error, so the strongest thing it could report was a
/// warning. With eliminations filed the rule is exact: `Σ parts - Σ eliminations` equals
/// the composed claim, per quantity, and any leftover difference is a finding.
///
/// ⛔ NOT REACHABLE BY A VALIDATOR. Both members are other documents; this test can only
/// run at all because `resolve` above happens to hold them.
#[test]
fn the_fused_demand_reconciles_with_its_parts_less_the_eliminations() {
    let c = composition();
    let labour = fusion(&c, "labour");

    let stated = demand(layer(&c.process_modulus, "labour"));
    let computed = expected(labour, EliminationAgainstType::Demand, demand)
        .expect("the labour eliminations are all sized, so this reconciles");

    assert!(
        close(stated, computed),
        "the composed demand is {stated:?} and its parts less their eliminations are \
         {computed:?}. A difference here is either an elimination nobody filed or an \
         arithmetic error, and the document cannot tell a reader which"
    );

    // ⭐ THE ASYMMETRY, ASSERTED. Demand was double counted because both members booked
    // the same work; the PEOPLE were not, because two establishments are two sets of
    // people. An implementation that eliminated symmetrically would have invented a
    // headcount reduction, so the composer filed the nameplate elimination as `none`
    // rather than leaving a reader to guess that nobody looked.
    let np = expected(labour, EliminationAgainstType::Nameplate, nameplate)
        .expect("`none` means zero: the composer looked and there was nothing to remove");
    assert!(close(nameplate(layer(&c.process_modulus, "labour")), np));

    // And the elimination is doing real work: without it the equation fails.
    let unadjusted = {
        let (us, pt) = (load(US), load(PT));
        add(demand(layer(&us, "labour")), demand(layer(&pt, "pessoal")))
    };
    assert!(
        !close(stated, unadjusted),
        "if the composed demand equalled the bare sum, this document would be exercising \
         nothing that a mapping-only file could not have expressed"
    );
}

/// ⭐⭐⭐ THE MOST USEFUL THING THIS DOCUMENT SAYS ABOUT `compute-pt`, AND IT IS A BLANK.
///
/// The group KNOWS those hours are double counted and cannot size it: the spill is
/// metered in GPU-hour and the US demand it belongs to is filed in GPU, and nobody has
/// filed a conversion. A required number would have been answered with a zero, and a zero
/// is a lie a receiver cannot detect. `unmeasured` tells a receiver the figure is
/// overstated by an amount nobody knows, which is strictly more than silence.
#[test]
fn an_elimination_nobody_could_size_is_not_a_zero() {
    let c = composition();
    let f = fusion(&c, "compute-pt");

    let reasons: Vec<&AbsenceReasonType> = eliminations(f)
        .into_iter()
        .filter_map(|e| match &e.quantity {
            StatedClaimType::Absent(a) => Some(&a.reason),
            StatedClaimType::Claim(_) => None,
        })
        .collect();
    assert!(
        reasons.contains(&&AbsenceReasonType::Unmeasured),
        "this layer's double count is certain and its size is not; the document has to be \
         able to say both"
    );

    // ⛔ AND THE RECONCILIATION MUST REPORT UNAVAILABLE RATHER THAN PASS. A checker that
    // read the blank as zero would find this layer reconciling exactly, and would report
    // success about a figure it knows to be overstated.
    assert_eq!(
        expected(f, EliminationAgainstType::Demand, demand),
        None,
        "an unsized elimination makes the sum uncomputable, and `unchecked` is a third \
         state that must not be folded into `checked and passed`"
    );

    // The layers whose eliminations ARE all sized still reconcile, so the third state is
    // reported per fusion rather than sinking the whole document.
    assert!(expected(fusion(&c, "labour"), EliminationAgainstType::Demand, demand).is_some());
}

/// ⭐⭐⭐ ALL THREE QUANTITIES, ON ONE LAYER, ANSWERING DIFFERENTLY.
///
/// `pm:Layer` says an ERP keeps one of demand, nameplate and draw, most dashboards keep
/// two, and the third is never the spare one. An elimination vocabulary that kept two
/// would be the same mistake one level up, and this layer is where that shows: the group
/// eliminates nameplate and draw and eliminates NOTHING from demand.
#[test]
fn all_three_quantities_eliminate_on_one_layer_and_answer_differently() {
    let c = composition();
    let f = fusion(&c, "shift-line");
    let composed = layer(&c.process_modulus, "shift-line");

    let quantities: [Quantity; 3] = [
        (EliminationAgainstType::Demand, demand, "demand"),
        (EliminationAgainstType::Nameplate, nameplate, "nameplate"),
        (EliminationAgainstType::Draw, draw, "draw"),
    ];

    for (against, of, what) in quantities {
        let computed = expected(f, against, of)
            .unwrap_or_else(|| panic!("`shift-line`: the {what} eliminations are all sized"));
        assert!(
            close(of(composed), computed),
            "`shift-line` {what}: composed {:?} against parts-less-eliminations {computed:?}",
            of(composed)
        );
    }

    // ⭐ AND THE LINE IS SATURATED, WHICH ONLY THE DRAW ELIMINATION MAKES VISIBLE.
    // Summing the two filed draws puts a ten-shift line at 14.4 shifts a week.
    let (us, pt) = (load(US), load(PT));
    let both = add(
        draw(layer(&us, "shift-line")),
        draw(layer(&pt, "linha-partilhada")),
    );
    assert!(
        both.1 > nameplate(composed).1,
        "the unadjusted draw is {:?} against a nameplate of {:?}, a utilisation nobody \
         observed and the machine cannot produce",
        both.1,
        nameplate(composed).1
    );
    assert!(close(draw(composed), nameplate(composed)));
}

/// ⭐⭐⭐ THE ARGUMENT FOR `against` BEING A REQUIRED FIELD, IN TWO LAYERS OF ONE DOCUMENT.
///
/// `labour` doubles its DEMAND and not its nameplate: both members book the same work, and
/// two establishments are still two sets of people. `shift-line` doubles its NAMEPLATE and
/// not its demand: two schedulers are still one machine, and each is asked for its own
/// work. ⛔ AN IMPLEMENTATION WITH ONE ELIMINATION CONCEPT GETS ONE OF THESE WRONG
/// WHICHEVER WAY IT GUESSES — inventing a headcount reduction, or a second production line.
#[test]
fn which_quantity_an_elimination_names_decides_the_answer() {
    let c = composition();
    let (labour, line) = (fusion(&c, "labour"), fusion(&c, "shift-line"));

    let sized = |f: &FusionType, a: EliminationAgainstType| {
        triple(&elimination_against(f, a).quantity).is_some()
    };

    assert!(sized(labour, EliminationAgainstType::Demand));
    assert!(!sized(labour, EliminationAgainstType::Nameplate));

    assert!(sized(line, EliminationAgainstType::Nameplate));
    assert!(!sized(line, EliminationAgainstType::Demand));

    // ⚠️ BOTH UNSIZED ONES ARE `none` AND NOT `unmeasured`: the composer looked and there
    // was nothing to remove. Filing no elimination at all would have said neither.
    for (f, a) in [
        (labour, EliminationAgainstType::Nameplate),
        (line, EliminationAgainstType::Demand),
    ] {
        match &elimination_against(f, a).quantity {
            StatedClaimType::Absent(x) => assert_eq!(x.reason, AbsenceReasonType::None),
            StatedClaimType::Claim(_) => unreachable!(),
        }
    }
}

/// ⭐⭐⭐ THE FINDING NO MEMBER CAN REACH AND NO CONSOLIDATED P&L PRODUCES: BOTH MEMBERS
/// FILE SLACK AND THE GROUP IS SHORT.
///
/// Each member files the shared line's ten shifts as its own nameplate, and each is right
/// to — either can schedule onto all ten. The group has one line. A reader netting the two
/// filings sees 7.3 shifts spare; the group is 2.7 shifts short, and the error is exactly
/// the ten shifts that were filed twice.
#[test]
fn a_shared_facility_flips_the_sign_when_it_is_consolidated() {
    let c = composition();
    let (us, pt) = (load(US), load(PT));

    let (a, b) = (layer(&us, "shift-line"), layer(&pt, "linha-partilhada"));
    let group = layer(&c.process_modulus, "shift-line");

    assert_eq!(fit(a), &FitType::Clearance, "the US member files slack");
    assert_eq!(
        fit(b),
        &FitType::Clearance,
        "the Portuguese member files slack"
    );
    assert_eq!(
        fit(group),
        &FitType::Interference,
        "and the group is short. Neither filing is wrong; the line is one line"
    );

    let naive = add(signed(a), signed(b));
    let truth = signed(group);
    assert!(
        naive.1 > 0.0 && truth.1 < 0.0,
        "netting the two filings gives {:?} shifts and the group holds {:?}. The sign is \
         the difference between a facility with room to spare and one turning work away",
        naive.1,
        truth.1
    );

    let removed = triple(
        &elimination_against(fusion(&c, "shift-line"), EliminationAgainstType::Nameplate).quantity,
    )
    .expect("the nameplate elimination is sized");
    assert!(
        (naive.1 - truth.1 - removed.1).abs() < TOLERANCE,
        "the whole error is the double-counted line: {:?} against {:?}",
        naive.1 - truth.1,
        removed.1
    );
}

/// ⭐⭐⭐ WHAT THE WHOLE PAIR OF DOCUMENTS WAS FOR.
///
/// A reader who simply added the two members' labour remainders gets [0.9, 2.3, 4.2]
/// people. The group's actual labour remainder is [0.4, 1.5, 3.0], and the entire
/// difference is the work each member books as its own demand because the other member
/// asked for it. Both filings are honest. Their sum is not.
///
/// ⭐ AND OF THE 1.5 PEOPLE AT THE MODE, ONLY 0.7 SITS IN AN ACCOUNT ANYWHERE — because
/// one of the group's two jurisdictions supplies an instrument for it and the other does
/// not. No consolidated statement of profit or loss produces either number.
#[test]
fn the_group_labour_remainder_is_smaller_than_the_sum_of_its_members() {
    let c = composition();
    let (us, pt) = (load(US), load(PT));

    let group = magnitude(layer(&c.process_modulus, "labour"));
    let naive = add(
        magnitude(layer(&us, "labour")),
        magnitude(layer(&pt, "pessoal")),
    );

    assert!(
        close(group, (0.4, 1.5, 3.0)),
        "group labour remainder: {group:?}"
    );
    assert!(close(naive, (0.9, 2.3, 4.2)), "naive sum: {naive:?}");

    // ⭐ The overstatement IS the elimination, exactly, because both members are short of
    // people and the signs therefore agree. Where the signs differ it would not be, and
    // the difference between those two cases is the fungibility judgement.
    let removed = eliminations(fusion(&c, "labour"))
        .into_iter()
        .find(|e| e.against == EliminationAgainstType::Demand)
        .and_then(|e| triple(&e.quantity))
        .expect("the demand elimination is sized");
    assert!(
        close(eliminate(naive, removed), group),
        "a reader who added the two filings overstates the group's labour shortfall by \
         {removed:?} people, which is precisely the work that was counted twice"
    );

    let booked = remainder(layer(&c.process_modulus, "labour"))
        .holder
        .iter()
        .find_map(|h| match h {
            StatedHolderType::Holder(h) if h.kind == HolderKindType::Booked => triple(&h.share),
            _ => None,
        })
        .expect("the Portuguese instrument survives consolidation");
    assert!(
        booked.1 < group.1,
        "the group can account for {} of {} people at the mode, and only because one \
         jurisdiction supplies an instrument. The rest is carried by people and recorded \
         nowhere",
        booked.1,
        group.1
    );
}

// ======================================================================================
// THE SECOND LEVEL. A holding company composing the group composition, which is itself
// composed from two member filings. ⭐ Nothing in the schema changed to allow this.
// ======================================================================================

/// ⭐⭐⭐ FUSIONS HAVE FUSIONS, AND NO ELEMENT IS DIFFERENT FOR IT.
///
/// Every part of the holding's `staff` names a layer inside another COMPOSITION's embedded
/// stack rather than inside a member's filing, and the reconciliation that discharges at
/// level one discharges here unchanged.
#[test]
fn a_composition_composes_another_composition() {
    let h = composed(HOLDING);
    let staff = fusion(&h, "staff");

    assert_eq!(
        parts(staff),
        vec![("group-parent", "labour"), ("group-parent", "on-call")],
        "both parts are layers of a composition, not of a member filing"
    );
    for p in &staff.part {
        assert!(
            is_composition(resolve(&p.layer.filing.notation)),
            "`staff` is the case this test exists for; a part resolving to a plain filing \
             would prove only what level one already proved"
        );
    }

    let composed_layer = layer(&h.process_modulus, "staff");
    for (against, of) in [
        (
            EliminationAgainstType::Demand,
            demand as fn(&LayerType) -> Triple,
        ),
        (EliminationAgainstType::Nameplate, nameplate),
    ] {
        let what = format!("{against:?}");
        let computed = expected(staff, against, of).expect("both eliminations are `none`");
        assert!(
            close(of(composed_layer), computed),
            "level-2 {what}: composed {:?} against parts-less-eliminations {computed:?}",
            of(composed_layer)
        );
    }

    // The shares still divide the magnitude exactly, two consolidations up.
    let mag = magnitude(composed_layer);
    let summed = remainder(composed_layer)
        .holder
        .iter()
        .filter_map(|h| match h {
            StatedHolderType::Holder(h) => triple(&h.share),
            StatedHolderType::Absent(_) => None,
        })
        .fold((0.0, 0.0, 0.0), add);
    assert!(
        close(summed, mag),
        "shares {summed:?} against magnitude {mag:?}"
    );
}

/// ⛔⛔⛔ THE GUARANTEE NESTING WEAKENS, AND THE CHECK THAT REPLACES IT.
///
/// `partIdentity` is an `xs:key` over `(notation, id)` and it is complete only while every
/// part is a leaf. At two levels it is not: a holding naming both `group#labour` and
/// `us-member#labour` has two distinct keys, the member's layer is consolidated twice — once
/// directly, once through the group — and no validator sees it, because the second path runs
/// through a document the first one does not contain.
///
/// The transitive rule is that NO LEAF IS REACHABLE THROUGH TWO PATHS, and it is owed by
/// whoever can fetch the chain. This crate can, so this crate owes it.
#[test]
fn no_leaf_layer_is_reachable_through_two_paths() {
    /// Resolve ONE composed layer of one composition down to the leaf filings under it.
    ///
    /// ⚠️ One layer, not the whole document: a part names a specific layer, and the fusion
    /// that produced THAT layer is the only one below it. Walking every fusion of the
    /// target instead reports a leaf once per sibling layer and calls it a double count.
    fn walk(
        name: &str,
        layer_name: &str,
        seen: &mut BTreeMap<(String, String), Vec<String>>,
        path: &str,
    ) {
        let here = format!("{path} -> {name}#{layer_name}");
        let c = composed(name);
        let Some(f) = c.fusion.iter().find(|f| f.name == layer_name) else {
            // ⭐ A layer the composer ORIGINATED. Nothing was folded into it, so the path
            // ends here rather than reaching a leaf, and that is not an error.
            return;
        };
        for p in &f.part {
            let target = resolve(&p.layer.filing.notation);
            if is_composition(target) {
                walk(target, &p.layer.filing.id, seen, &here);
            } else {
                seen.entry((p.layer.filing.notation.clone(), p.layer.filing.id.clone()))
                    .or_default()
                    .push(here.clone());
            }
        }
    }

    let mut leaves = BTreeMap::new();
    for f in &composed(HOLDING).fusion {
        walk(HOLDING, &f.name, &mut leaves, "holding");
    }

    assert!(
        !leaves.is_empty(),
        "the walk reached no leaf at all, so it checked nothing"
    );
    for ((notation, id), paths) in &leaves {
        assert_eq!(
            paths.len(),
            1,
            "{notation}#{id} is consolidated through {} paths ({paths:?}). Each path counts \
             it once, so the holding's figures include it twice",
            paths.len()
        );
    }
}

/// ⭐⭐⭐ A COUPLING SURVIVES A FUSION AND ATTENUATES.
///
/// The group observed `labour` moving with `shift-line`. The holding fuses `labour` into
/// `staff` and keeps `shift-line`, so the dependence still holds — but relief applied to
/// `staff` may land on the rota instead of on delivery, so it CANNOT hold as strongly. The
/// bound is `labour`'s share of `staff`'s nameplate.
///
/// ⛔ An inherited coupling re-filed at the lower level's own number is either lucky or
/// unexamined, and that is what this test refuses.
#[test]
fn an_inherited_coupling_is_weaker_than_the_one_it_came_from() {
    let (g, h) = (composition(), composed(HOLDING));

    let find = |doc: &ProcessModulusElementType, from: &str, to: &str| -> Triple {
        couplings(&doc.stack)
            .into_iter()
            .find(|c| c.from == from && c.to == to)
            .and_then(|c| c.strength.as_ref())
            .and_then(triple)
            .unwrap_or_else(|| panic!("no coupling `{from}` -> `{to}` with a stated strength"))
    };

    let lower = find(&g.process_modulus, "labour", "shift-line");
    let upper = find(&h.process_modulus, "staff", "shift-line");

    // `labour` is 10 of `staff`'s 12 nameplate.
    let share = nameplate(layer(&g.process_modulus, "labour")).1
        / nameplate(layer(&h.process_modulus, "staff")).1;
    assert!(
        share < 1.0,
        "the fused layer must be strictly larger than the part"
    );

    for (u, l, which) in [
        (upper.0, lower.0, "low"),
        (upper.1, lower.1, "mostLikely"),
        (upper.2, lower.2, "high"),
    ] {
        assert!(
            u < l,
            "the inherited coupling's {which} bound is {u}, not below the group's {l}. \
             A dependence cannot survive a fusion undiminished: relief applied to the \
             larger layer does not all reach the part that carried it"
        );
        assert!(
            u <= l * share + TOLERANCE,
            "the inherited coupling's {which} bound is {u}, above the attenuation bound \
             {} ({l} x {share}). The upper strength is capped by the part's share of the \
             layer it was fused into",
            l * share
        );
    }
}

/// ⛔⛔⛔ A FUSED SLACK IS BOUNDED BY THE SUM OF ITS PARTS', AND "STRICTEST WINS" WAS AN
/// ARTEFACT OF THE BOOLEAN.
///
/// While these were booleans the rule looked principled: `labour` admits delay, `on-call`
/// does not, a layer that admits delay for only part of its demand does not admit delay,
/// so the fused `staff` files `false`. ⛔ That rule cannot survive the retype, and it was
/// never really about strictness — taking the minimum UNDERSTATES a fused slack. Most of
/// `staff`'s demand is delivery work that does sit in a queue; only the escalations perish
/// on contact. Filing zero would assert the whole fused layer perishes.
///
/// ⭐ A slack is a quantity, so the fused figure is bounded ABOVE by the sum of its parts'
/// — you cannot get more give than the parts have — and below by nothing useful. One
/// unsized part makes that sum unsized, exactly as an unsized elimination makes a
/// reconciliation uncomputable rather than satisfied.
///
/// ⛔ AND THE FUSION STILL SAYS SO RATHER THAN LETTING THE ABSENCE LOOK LIKE AGREEMENT:
/// two parts disagreeing on a slack is the strongest argument against fusing them, and it
/// is left in `observed` where a reader will find it.
#[test]
fn a_fused_slack_is_bounded_by_the_sum_of_its_parts() {
    let (g, h) = (composition(), composed(HOLDING));

    let slack = |l: &LayerType| match &l.time_slack {
        StatedClaimType::Claim(c) => Some((c.low, c.most_likely, c.high)),
        StatedClaimType::Absent(a) => match a.reason {
            // ⛔ `none` IS ZERO AND `unmeasured` IS NOT. Collapsing them is the defect
            // `Absence` exists to prevent, reintroduced by the checker.
            AbsenceReasonType::None => Some((0.0, 0.0, 0.0)),
            _ => None,
        },
    };

    let parts = [
        slack(layer(&g.process_modulus, "labour")),
        slack(layer(&g.process_modulus, "on-call")),
    ];
    assert!(
        parts.contains(&None) && parts.contains(&Some((0.0, 0.0, 0.0))),
        "the parts must still disagree — one unsized, one a measured zero — or this test \
         is checking nothing"
    );

    // One unsized part makes the bound unsized, so the fused layer cannot state a figure.
    assert_eq!(
        slack(layer(&h.process_modulus, "staff")),
        None,
        "`staff` inherits an unsized bound and must not file a number, and must not file \
         the minimum either: taking `on-call`'s zero would assert that delivery work \
         perishes on contact, which is false about the larger part of this layer"
    );

    // Where BOTH parts are a measured zero the sum really is zero, and the fused layer
    // says so — the bound is a bound, not an excuse to leave everything unmeasured.
    let compute = fusion(&h, "compute");
    let both_zero = compute
        .part
        .iter()
        .all(|p| slack(layer(&g.process_modulus, &p.layer.filing.id)) == Some((0.0, 0.0, 0.0)));
    assert!(
        both_zero,
        "both compute parts file a measured zero time slack"
    );
    assert_eq!(
        slack(layer(&h.process_modulus, "compute")),
        Some((0.0, 0.0, 0.0)),
        "zero plus zero is zero, and an inference request that waits is still not served \
         two consolidations up"
    );

    let observed = &fusion(&h, "staff").observed;
    assert!(
        observed.contains("timeSlack"),
        "a fusion overruling a filed observation owes the reader the argument against \
         itself, not only the argument for"
    );
}

/// ⛔⛔ A FUSION THAT ABSORBS A COUPLING DESTROYS A FILED OBSERVATION.
///
/// The group filed `labour` <-> `on-call` and kept them as two layers. The holding fuses
/// them, so above this document there is one layer and no coupling to file. That is not an
/// omission and it is not evidence for the fusion either — coupling and fungibility are
/// independent axes. It is an observation the upper level chose to absorb, and `observed`
/// is where it says so.
///
/// ⭐ THIS CHECKS EVERY ABSORBING FUSION RATHER THAN A NAMED ONE, AND THE DIFFERENCE IS NOT
/// COSMETIC. Written against `staff` alone it passed while `compute` — added later, fusing
/// two layers the group had also filed as coupled — said nothing about the observation it
/// swallowed. A rule that only holds where somebody remembered to look is not a rule.
#[test]
fn a_fusion_that_absorbs_a_coupling_says_it_did() {
    let (g, h) = (composition(), composed(HOLDING));

    let absorbed: Vec<(&str, &str, &str)> = couplings(&g.process_modulus.stack)
        .into_iter()
        .filter_map(|c| {
            h.fusion
                .iter()
                .find(|f| {
                    let ids: Vec<&str> =
                        f.part.iter().map(|p| p.layer.filing.id.as_str()).collect();
                    ids.contains(&c.from.as_str()) && ids.contains(&c.to.as_str())
                })
                .map(|f| (c.from.as_str(), c.to.as_str(), f.name.as_str()))
        })
        .collect();

    assert_eq!(
        absorbed,
        vec![
            ("labour", "on-call", "staff"),
            ("compute-us", "compute-pt", "compute"),
        ],
        "these pairs are the whole point of the second level; if one stops being absorbed \
         the example has stopped exercising the case"
    );

    for (from, to, name) in &absorbed {
        let f = fusion(&h, name);
        assert!(
            f.observed.contains("COUPLING"),
            "`{name}` swallows the coupling the group filed between `{from}` and `{to}`, and \
             must name it. A composition that silently fuses two layers a filing below it \
             reported as coupled has overruled that filing without arguing with it"
        );
    }

    // And the absorbed coupling has no counterpart above: there is one layer now.
    assert!(
        !couplings(&h.process_modulus.stack)
            .iter()
            .any(|c| c.from == "staff" && c.to == "staff"),
        "an absorbed coupling does not reappear as a layer coupled to itself"
    );
}

/// ⭐⭐⭐ THE FUSION THE GROUP COULD NOT PERFORM, AND WHAT MADE IT POSSIBLE.
///
/// `compute-us` is metered per reserved card and `compute-pt` by the month. The group
/// filed them as two one-part fusions under two names — correct, and as far as it could
/// go, because `4.4 GPU + 545 GPU-hour` is not a sum and no amount of prose makes it one.
/// The holding carries a `Part/factor` and the arithmetic closes.
///
/// ⛔ THE THREE QUANTITIES CONVERT AND THE ELIMINATION DOES NOT. A part arrives in
/// whatever unit its filer used; the sum it is removed from is already in the composed
/// unit. Stating the cross-charge in GPU would be unaddable to a total in GPU-hour, and
/// there is no second factor to rescue it — a factor converts a PART, and an elimination
/// is not one.
#[test]
fn a_fusion_converts_its_parts_before_adding_them() {
    let h = composed(HOLDING);
    let compute = fusion(&h, "compute");
    let composed_layer = layer(&h.process_modulus, "compute");

    // The parts genuinely disagree about the unit — that is the whole premise.
    let g = composition();
    let units: BTreeSet<&str> = compute
        .part
        .iter()
        .map(|p| unit(layer(&g.process_modulus, &p.layer.filing.id)))
        .collect();
    assert_eq!(
        units.len(),
        2,
        "if the parts ever agree on a unit this stops being a conversion and the factor \
         below is decoration"
    );
    assert!(
        !units.contains(unit(composed_layer)) || units.len() > 1,
        "the composed unit must be reachable from at least one part by conversion"
    );

    // Exactly one part carries a factor: the other is already in the composed unit.
    assert_eq!(
        compute.part.iter().filter(|p| p.factor.is_some()).count(),
        1,
        "a ceremonial factor of 1 on the already-converted part would assert that a \
         conversion was performed and came to unity, which is a different claim"
    );

    for (against, of, what) in [
        (
            EliminationAgainstType::Demand,
            demand as fn(&LayerType) -> Triple,
            "demand",
        ),
        (EliminationAgainstType::Nameplate, nameplate, "nameplate"),
        (EliminationAgainstType::Draw, draw, "draw"),
    ] {
        let computed = expected(compute, against, of)
            .expect("every factor and every elimination on this fusion is sized");
        assert!(
            close(of(composed_layer), computed),
            "converted {what}: composed {:?} against parts-converted-less-eliminations \
             {computed:?}",
            of(composed_layer)
        );
    }
}

/// ⛔⛔⛔ CONVERTING WIDENS A POINT NAMEPLATE, AND S-14 SAID THE CORPUS HAD NEVER FORCED IT.
///
/// Every nameplate in every other document is a point. Eight cards is exact; eight cards
/// FOR A MONTH is not, because a month is `[672, 720, 744]` hours. The composed nameplate
/// is the first genuinely uncertain one here, and it arrived as a consequence of the
/// conversion rather than by being invented for the test.
///
/// ⭐ AND `r ≡ nameplate − demand` SURVIVES IT, which is the point S-14 got wrong. The
/// decomposition's floors cancel algebraically, so an interval nameplate costs the identity
/// nothing. What an interval nameplate does cost is the SPLIT into a decision and a
/// residue, and this layer cannot even attempt that: its quantum is absent.
#[test]
fn converting_a_point_nameplate_produces_an_uncertain_one() {
    let h = composed(HOLDING);
    let compute = layer(&h.process_modulus, "compute");

    let (lo, _, hi) = nameplate(compute);
    assert!(
        hi - lo > 0.0,
        "the composed nameplate is the corpus's only uncertain one; if it collapses to a \
         point, S-14's case is unexercised again"
    );

    let g = composition();
    for name in ["compute-us", "compute-pt"] {
        let (plo, _, phi) = nameplate(layer(&g.process_modulus, name));
        assert_eq!(
            plo, phi,
            "`{name}` files a POINT nameplate; the width above is manufactured entirely by \
             the conversion, and that is what makes it worth asserting"
        );
    }
}

/// ⛔⛔⛔ CONVERT-THEN-DIFFERENCE IS NOT DIFFERENCE-THEN-CONVERT, AND THE GAP IS FILED.
///
/// One factor multiplies BOTH the US part's nameplate and its demand, so the two converted
/// intervals are correlated. Subtracting them with the bound reversal that INDEPENDENT
/// quantities require pairs a 28-day nameplate against a 31-day demand — a month that did
/// not happen — and counts the factor's own spread twice.
///
/// ⭐ It is the same correlated-components question `Elimination` had to answer for
/// subtraction, arriving in a second place with the same answer: convert the remainder
/// itself, never re-derive it. This test asserts BOTH figures, because a reader who only
/// sees the right one has no way to tell how much the wrong one costs.
#[test]
fn a_converted_remainder_is_converted_and_never_re_derived() {
    let (g, h) = (composition(), composed(HOLDING));
    let compute = fusion(&h, "compute");
    let composed_layer = layer(&h.process_modulus, "compute");

    // What the composer filed.
    let stated = triple(&remainder(composed_layer).quantity)
        .expect("with the quantum absent this remainder cannot be `derived` and must be stated");

    // Right: each part's own remainder, converted, plus the demand the elimination removed
    // — capacity that was counted as consumed twice and is therefore spare.
    let mut correct = (0.0, 0.0, 0.0);
    for p in &compute.part {
        let part_layer = layer(&g.process_modulus, &p.layer.filing.id);
        correct = add(correct, convert(magnitude(part_layer), p).expect("sized"));
    }
    for e in eliminations(compute)
        .into_iter()
        .filter(|e| e.against == EliminationAgainstType::Demand)
    {
        if let StatedClaimType::Claim(c) = &e.quantity {
            correct = add(correct, (c.low, c.most_likely, c.high));
        }
    }
    assert!(
        close(stated, correct),
        "the filed remainder {stated:?} is the sum of converted part remainders {correct:?}"
    );

    // Wrong: re-derived from the converted nameplate and demand, with bound reversal.
    let (nl, nm, nh) = nameplate(composed_layer);
    let (dl, dm, dh) = demand(composed_layer);
    let naive = (nl - dh, nm - dm, nh - dl);

    assert!(
        (naive.1 - correct.1).abs() < TOLERANCE,
        "the two readings must agree at `mostLikely`, where both use the same month"
    );
    assert!(
        !close(naive, correct),
        "if these ever coincide the example has stopped demonstrating the hazard: \
         re-derived {naive:?} against converted {correct:?}"
    );
    assert!(
        naive.0 < correct.0 && naive.2 > correct.2,
        "the re-derived interval must be strictly WIDER on both sides — that is the \
         factor's spread being counted twice, not a rounding difference"
    );
}

/// ⭐⭐⭐ DID THE COMPOSER LOOK FOR DOUBLE COUNTING? Three of this corpus's eight fusions
/// file no elimination at all, and until `Fusion/eliminations` became a `StatedEliminations`
/// there was no way to ask — an empty list said "we checked and the parts are disjoint" and
/// "nobody checked" in the same bytes.
///
/// ⛔⛔ AND THE TWO ANSWERS OWE DIFFERENT ARITHMETIC, WHICH IS WHAT MAKES THIS A RULE RATHER
/// THAN A VOCABULARY. Under `none` or `notApplicable` the composed figure MUST equal the sum
/// of its converted parts exactly, and this test performs that sum. Under `unmeasured` no
/// equality is owed at all and `expected` returns `None`. The old empty list quietly bought
/// the first reading for documents that had earned the second.
#[test]
fn a_fusion_says_whether_anybody_looked_for_double_counting() {
    let mut exact = 0;
    for (name, c) in [("group", composition()), ("holding", composed(HOLDING))] {
        for f in &c.fusion {
            let Some(a) = elimination_absence(f) else {
                assert!(
                    !eliminations(f).is_empty(),
                    "{name} `{}`: a fusion files eliminations or a typed reason it has none, \
                     never an empty list",
                    f.name
                );
                continue;
            };

            // ⭐ Every empty one in this corpus is a ONE-PART fusion, and `notApplicable` is
            // the exact reason: double counting needs two parts to run between, so between a
            // set of one the question has no population rather than a zero answer.
            assert_eq!(
                a.reason,
                AbsenceReasonType::NotApplicable,
                "{name} `{}`: {} parts and no eliminations",
                f.name,
                f.part.len()
            );
            assert_eq!(
                f.part.len(),
                1,
                "{name} `{}` calls the question malformed while fusing {} parts, which is a \
                 claim that two or more supplies cannot double count",
                f.name,
                f.part.len()
            );

            // ⛔ AND THE ARITHMETIC IS NOW OWED. Nothing was removed, so the composed figure
            // is the converted part exactly, and a difference is a finding rather than a
            // shrug about eliminations somebody might not have filed.
            for (what, of) in [
                ("demand", demand as fn(&LayerType) -> Triple),
                ("nameplate", nameplate),
            ] {
                let against = if what == "demand" {
                    EliminationAgainstType::Demand
                } else {
                    EliminationAgainstType::Nameplate
                };
                let Some(computed) = expected(f, against, of) else {
                    panic!("{name} `{}`: nothing suspends this sum", f.name)
                };
                let stated = of(layer(&c.process_modulus, &f.name));
                assert!(
                    close(stated, computed),
                    "{name} `{}` {what}: composed {stated:?} against its one part {computed:?}. \
                     With `eliminations` absent for cause there is nothing to remove, so these \
                     must agree exactly",
                    f.name
                );
                exact += 1;
            }
        }
    }

    // ⚠️ A rule that ran on nothing would pass loudest. Three fusions, two quantities each.
    assert!(
        exact >= 6,
        "only {exact} exact sums were reachable; the one-part branch is the only place this \
         rule bites and it has to be exercised"
    );
}

/// The window a layer files, and the typed reason it files none — one or the other, never
/// both, because `Divisibility/window` is a `StatedLumpyQuantum`.
fn duty(l: &LayerType) -> Result<Triple, AbsenceReasonType> {
    let pm::StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return Err(AbsenceReasonType::NotApplicable);
    };
    for c in &d.content {
        match c {
            pm::DivisibilityTypeContent::Window(pm::StatedLumpyQuantumType::Quantum(w)) => {
                return triple(&w.size).ok_or(AbsenceReasonType::Unmeasured)
            }
            pm::DivisibilityTypeContent::Window(pm::StatedLumpyQuantumType::Absent(a)) => {
                return Err(a.reason.clone())
            }
            _ => {}
        }
    }
    Err(AbsenceReasonType::NotApplicable)
}

/// ⭐⭐⭐ A WINDOW IS CARRIED THROUGH A FUSION AND NEVER SUMMED, AND UNTIL THE ELEMENT BECAME
/// REQUIRED NEITHER HALF OF THAT RULE COULD BE CHECKED.
///
/// `Divisibility/window` states it plainly: "Two members naming one machine file one calendar
/// between them; summing gives ten days a week. It is a property rather than a quantity, which
/// is why `EliminationAgainst` has three members and no fourth — there is nothing to
/// eliminate." A real rule, unenforceable for two reasons at once.
///
/// ⛔⛔ THE FIRST IS WHY THIS CLEANUP FOUND A LIVE DEFECT RATHER THAN A TIDINESS. Dropping a
/// carried window produced a document byte-identical to a line that runs seven days a week, so
/// the holding level had in fact dropped one and nothing said so. The composed layer had a
/// nameplate quoted per week and no calendar behind it, which overstates what the line
/// delivers by two sevenths and reads as a filing choice.
///
/// ⭐ THE SECOND IS THE SUM. Two five-day parts must compose to FIVE. The arithmetic every
/// other quantity in this model owes — add the parts, subtract the eliminations — is exactly
/// wrong here, and this is the one place that says so in a number.
#[test]
fn a_window_is_carried_through_a_fusion_and_never_summed() {
    let mut checked = 0;

    for (name, c) in [("group", composition()), ("holding", composed(HOLDING))] {
        for f in &c.fusion {
            let parts: Vec<Triple> = f
                .part
                .iter()
                .filter_map(|p| {
                    let doc = filing(resolve(&p.layer.filing.notation));
                    duty(layer(&doc, &p.layer.filing.id)).ok()
                })
                .collect();
            if parts.is_empty() {
                continue;
            }

            let composed = duty(layer(&c.process_modulus, &f.name)).unwrap_or_else(|r| {
                panic!(
                    "{name} `{}`: {} of its parts file a duty cycle and the composed layer \
                     files `{r:?}`. A window is a property of the machine, so fusing layers \
                     that name one machine cannot lose its calendar — and the loss is \
                     invisible in the figures, because the nameplate still reads per week",
                    f.name,
                    parts.len()
                )
            });

            for p in &parts {
                assert!(
                    close(composed, *p),
                    "{name} `{}`: composed window {composed:?} against a part's {p:?}. A window \
                     is carried, never summed — two members naming one machine file one \
                     calendar between them, and adding them gives a line running ten days a \
                     week",
                    f.name
                );
                checked += 1;
            }
        }
    }

    assert!(
        checked >= 3,
        "only {checked} part windows reached this rule; it is the one place the model forbids \
         the addition it performs everywhere else, and it has to run on more than one document"
    );
}
