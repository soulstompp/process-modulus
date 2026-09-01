//! ⭐⭐⭐ EVERY STATE THE SCHEMA ADMITS, WITH A DECLARED VERDICT THE BUILD ENFORCES.
//!
//! `pm:AbsenceReason` is a closed set of four applied at eleven wrapper types, so the two
//! schemas admit roughly fifty (site, state) pairs. Asking which of them any document has ever
//! filed produced the finding that started this file: **eight of nine wrappers had dark
//! states, and it predated the Pattern 1 cleanup entirely.** `StatedFit` was the worst —
//! twenty-one values and not one absence, in the wrapper whose annotation spends four
//! paragraphs defending its own existence.
//!
//! ⛔⛔ A DARK STATE IS NOT AUTOMATICALLY A DEFECT, WHICH IS WHY THIS IS A TABLE AND NOT A
//! COVERAGE PERCENTAGE. Three things a cell can be, and conflating them is how a coverage
//! number comes to mean nothing:
//!
//!   Exercised   some document files it, and a rule handles it
//!   Incoherent  the schema PERMITS it and it means nothing here. ⛔ Must never appear, and
//!               the reason belongs in the table rather than in a reviewer's memory
//!   Open        permitted, coherent, and nobody has filed one. Recorded on purpose
//!
//! ⭐⭐ THE `Incoherent` ROWS ARE THE PART WORTH ARGUING WITH. `pm:AbsenceReason` is closed at
//! four "DELIBERATELY NOT SIX" and restricting it per site would fork a set the schema borrows
//! from itself. So the constraint lives here and in `conformance/README.md` as a rule, exactly
//! like the other forty-four things XSD 1.0 cannot reach. Every one of them is a claim a
//! reader is entitled to disagree with.

use std::collections::BTreeMap;
use std::fs;

use process_modulus::asrt::{ClaimedType, CompositionType, CoverageType};
use process_modulus::pm::{
    self, AbsenceReasonType, ProcessModulusElementType, StatedClaimType,
    StatedConstraintOriginType, StatedDivisibilityType, StatedFitType, StatedLumpyQuantumType,
    StatedNarrowingType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

/// What a (site, state) pair is allowed to be.
#[derive(Debug, PartialEq)]
enum Verdict {
    /// Some document files it. The count must be > 0.
    Exercised,
    /// ⛔ The schema permits it and it means nothing at this site. The count must be 0, and
    /// the string is the argument, which is the part a reader can disagree with.
    Incoherent(&'static str),
    /// Permitted, coherent, unfiled. Recorded so that filing one is a deliberate act.
    ///
    /// ⭐⭐ THERE ARE CURRENTLY NONE, AND THAT IS THE RESULT RATHER THAN A REASON TO DELETE
    /// THE VARIANT. Every state either has a document filing it or has an argument here for
    /// why it means nothing. Removing this arm would leave the next dark state nowhere to be
    /// recorded except a reviewer's memory, which is where the eight of them found by this
    /// pass had been living.
    #[allow(dead_code)]
    Open(&'static str),
}
use Verdict::{Exercised, Incoherent, Open};

/// ⛔⛔⛔ THE TABLE. Adding a wrapper to either schema and not adding it here leaves its states
/// unmeasured, which is the failure this whole file exists to stop happening again.
///
/// ⭐ Read the `Incoherent` column as a list of rules. Each one is a fact about what an
/// absence reason MEANS at that position, and several were already stated in the schemas'
/// prose with nothing checking them.
fn declared() -> Vec<(&'static str, AbsenceReasonType, Verdict)> {
    use AbsenceReasonType::{Derived, None as RNone, NotApplicable, Unmeasured};
    vec![
        // ---- the five repaired in the Pattern 1 cleanup ----
        ("StatedCouplings", RNone, Exercised),
        ("StatedCouplings", Unmeasured, Exercised),
        ("StatedCouplings", NotApplicable, Exercised),
        ("StatedCouplings", Derived, Incoherent(
            "a coupling is an OBSERVATION and nothing else in the model implies one. `derived` \
             would invite a receiver to compute a dependence between layers out of their \
             figures, which is precisely the inference `Coupling/observed` exists to refuse",
        )),
        ("StatedEliminations", RNone, Exercised),
        ("StatedEliminations", Unmeasured, Exercised),
        ("StatedEliminations", NotApplicable, Exercised),
        ("StatedEliminations", Derived, Incoherent(
            "whether anybody LOOKED for double counting is a fact about the composer's \
             diligence. No arrangement of figures implies it, and a receiver that computed it \
             would be computing a claim about a person",
        )),
        ("window", RNone, Exercised),
        ("window", Unmeasured, Exercised),
        ("window", NotApplicable, Exercised),
        ("window", Derived, Incoherent(
            "`Divisibility/window` states this itself: a duty cycle is a fact about the \
             supply's calendar, and admitting `derived` would invite computing a window out of \
             a slack, which is the inference the element forbids in the other direction",
        )),
        ("boundOrigin", RNone, Exercised),
        ("boundOrigin", Unmeasured, Exercised),
        ("boundOrigin", NotApplicable, Exercised),
        ("boundOrigin", Derived, Exercised),
        // ---- the wrappers that were already here, and were never measured ----
        ("StatedFit", RNone, Incoherent(
            "⭐ THE `transition` CORRECTION, AS A RULE. `absent reason=\"none\"` was doing the \
             missing third member's job — a demand of [3,4,5] against a nameplate of 4 was \
             filed as an absence of fit when it is a transition fit. There is no such thing as \
             two ranges with no relation between them, so `none` cannot mean anything here. A \
             layer with nothing to compare against is `notApplicable`",
        )),
        ("StatedFit", Unmeasured, Exercised),
        ("StatedFit", NotApplicable, Exercised),
        ("StatedFit", Derived, Exercised),
        ("StatedDivisibility", RNone, Incoherent(
            "`continuous` IS the value that says there is no quantum, so `none` is a second \
             spelling of a member the choice already has. `StatedDivisibility`'s annotation \
             makes this argument for `notApplicable` and stops one short of it",
        )),
        ("StatedDivisibility", Unmeasured, Exercised),
        ("StatedDivisibility", NotApplicable, Exercised),
        ("StatedDivisibility", Derived, Incoherent(
            "how a supply divides is a fact about the supply. Nothing in the model implies it",
        )),
        ("amountOrigin", RNone, Incoherent(
            "⚠️ AND THIS ONE DIVERGES FROM `boundOrigin`, WHICH TAKES THE SAME TYPE. An amount \
             that was COMMITTED has an author by definition — somebody committed it — and \
             where the number is fixed by the nature of the thing, `intrinsic` is the member \
             that says so. `none` would be a second spelling of it. A BOUND is different: a \
             range read off a year of history has edges nobody chose and nothing about the \
             world fixes, which is neither `intrinsic` nor a blank",
        )),
        ("amountOrigin", Unmeasured, Exercised),
        ("amountOrigin", NotApplicable, Exercised),
        ("amountOrigin", Derived, Incoherent(
            "nothing else in the document states who could have committed a different amount. \
             `boundOrigin` can say `derived` precisely BECAUSE this element answers it",
        )),
        ("StatedNarrowing", RNone, Exercised),
        ("StatedNarrowing", Unmeasured, Exercised),
        ("StatedNarrowing", NotApplicable, Exercised),
        // ---- the two that arrived with local composition ----
        ("StatedNotation", RNone, Open(
            "a working document published under no identifier at all. Ordinary in practice, \
             and nothing in either directory is one: every document here is written to be \
             cited by another",
        )),
        ("StatedNotation", Unmeasured, Exercised),
        ("StatedNotation", NotApplicable, Incoherent(
            "⛔ a document nobody may reference cannot be composed into anything, and this \
             model exists to be composed. `none` is the state for a document with no \
             identifier; claiming the QUESTION is malformed claims the document is outside the \
             population of things that can be cited, which is a stronger thing than not having \
             a name",
        )),
        ("StatedNotation", Derived, Incoherent(
            "a filing's own identity cannot be computed from its contents. Every other \
             `derived` in this model points at a sibling element that states the fact; there \
             is no sibling here and no derivation to point at",
        )),
        ("StatedScope", RNone, Incoherent(
            "⭐ a stack has at least one layer, so \"there is no scope\" is not a state a \
             document can be in. The three extents cover the axis and `none` would be a fourth \
             spelling of `complete`",
        )),
        ("StatedScope", Unmeasured, Exercised),
        ("StatedScope", NotApplicable, Incoherent(
            "every stack has an extent. There is no filing for which the question of how much \
             of the system it holds is malformed",
        )),
        ("StatedScope", Derived, Incoherent(
            "nothing in a document implies how much of the system lies outside it. That is \
             precisely the fact no filing could state before 0.3.0",
        )),
        ("StatedNarrowing", Derived, Incoherent(
            "what would tighten a range is a claim about instruments and interventions that do \
             not exist yet. There is nothing in the document to derive it from",
        )),
    ]
}

/// The three `Claimed` values, which are not absences and so need their own line.
fn declared_claimed() -> Vec<(ClaimedType, Verdict)> {
    vec![
        (ClaimedType::Full, Exercised),
        (ClaimedType::None, Exercised),
        (ClaimedType::Partial, Exercised),
    ]
}

const CORPUS: &[&str] = &[
    "corpus/enterprise-contract.xml",
    "corpus/refutation.xml",
    "corpus/unstated.xml",
    "corpus/merge-us-member.xml",
    "corpus/merge-pt-member.xml",
];
const COMPOSITIONS: &[&str] = &[
    "corpus/merge-group-composition.xml",
    "corpus/merge-holding-composition.xml",
    "fixtures/every-elimination.xml",
];
const FIXTURES: &[&str] = &["fixtures/every-absence.xml", "fixtures/every-draft.xml"];
const COVERAGES: &[&str] = &[
    "corpus/coverage-us-gaap.xml",
    "corpus/coverage-pt-ncrf-pe.xml",
    "fixtures/every-claimed.xml",
];

fn read(rel: &str) -> String {
    let path = format!("{}/assets/{rel}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

fn reason(a: &pm::AbsenceType) -> AbsenceReasonType {
    a.reason.clone()
}

/// Count every (site, state) pair across both corpora at once.
///
/// ⚠️ BOTH, DELIBERATELY. The two directories answer different questions — see
/// `assets/fixtures/README.md` — but the question THIS file asks is "does the schema's every
/// state work", and a stipulation answers that as well as a filing does. What a fixture may
/// never do is appear in a finding about the evidence, which is why
/// `tests/corpus_parse.rs` reads only `assets/corpus/`.
fn tally() -> BTreeMap<(&'static str, String), usize> {
    let mut m: BTreeMap<(&'static str, String), usize> = BTreeMap::new();
    // ⚠️ Keyed by the reason's `Debug` string: the generated enums derive `PartialEq` but not
    // `Ord`, and a map wants an ordering. The names are the schema's own enumeration values.
    fn walk(m: &mut BTreeMap<(&'static str, String), usize>, doc: &ProcessModulusElementType) {
        let mut bump = |site: &'static str, r: AbsenceReasonType| {
            *m.entry((site, format!("{r:?}"))).or_default() += 1
        };
        if let pm::StatedNotationType::Absent(a) = &doc.notation {
            bump("StatedNotation", reason(a));
        }
        if let pm::StatedScopeType::Absent(a) = &doc.stack.scope {
            bump("StatedScope", reason(a));
        }

        // ⚠️ EVERY POSITION A `Claim` CAN SIT IN, AND THE FIRST DRAFT OF THIS WALKER MISSED
        // THREE — coupling strengths, elimination quantities and part factors. The test above
        // caught it, which is the point of asserting on a declared table rather than printing
        // a percentage: an undercount looks exactly like a dark state.
        for c in &doc.stack.couplings.content {
            match c {
                pm::StatedCouplingsTypeContent::Absent(a) => bump("StatedCouplings", reason(a)),
                pm::StatedCouplingsTypeContent::Coupling(k) => {
                    if let Some(StatedClaimType::Claim(c)) = &k.strength {
                        if let StatedConstraintOriginType::Absent(a) = &c.bound_origin {
                            bump("boundOrigin", reason(a));
                        }
                        if let StatedNarrowingType::Absent(a) = &c.narrows_when {
                            bump("StatedNarrowing", reason(a));
                        }
                    }
                }
            }
        }
        for l in &doc.stack.layer {
            for c in [
                &l.demand,
                &l.time_slack,
                &l.supply.nameplate.capacity_slack,
                &l.supply.nameplate.inventory_slack,
                &l.supply.nameplate.amount,
            ] {
                if let StatedClaimType::Claim(c) = c {
                    match &c.narrows_when {
                        StatedNarrowingType::Absent(a) => bump("StatedNarrowing", reason(a)),
                        StatedNarrowingType::Narrowing(_) => {}
                    }
                    if let StatedConstraintOriginType::Absent(a) = &c.bound_origin {
                        bump("boundOrigin", reason(a));
                    }
                }
            }
            if let StatedConstraintOriginType::Absent(a) = &l.supply.nameplate.amount_origin {
                bump("amountOrigin", reason(a));
            }
            match &l.supply.nameplate.divisibility {
                StatedDivisibilityType::Absent(a) => bump("StatedDivisibility", reason(a)),
                StatedDivisibilityType::Divisibility(d) => {
                    for c in &d.content {
                        match c {
                            pm::DivisibilityTypeContent::Window(
                                StatedLumpyQuantumType::Absent(a),
                            ) => bump("window", reason(a)),
                            pm::DivisibilityTypeContent::Lumpy(q) => {
                                if let StatedClaimType::Claim(c) = &q.size {
                                    if let StatedConstraintOriginType::Absent(a) = &c.bound_origin {
                                        bump("boundOrigin", reason(a));
                                    }
                                    if let StatedNarrowingType::Absent(a) = &c.narrows_when {
                                        bump("StatedNarrowing", reason(a));
                                    }
                                }
                            }
                            _ => {}
                        }
                    }
                }
            }
            if let pm::StatedRemainderType::Remainder(r) = &l.remainder {
                if let StatedFitType::Absent(a) = &r.sign {
                    bump("StatedFit", reason(a));
                }
                let mut claim = |c: &StatedClaimType| {
                    if let StatedClaimType::Claim(c) = c {
                        if let StatedConstraintOriginType::Absent(a) = &c.bound_origin {
                            bump("boundOrigin", reason(a));
                        }
                        if let StatedNarrowingType::Absent(a) = &c.narrows_when {
                            bump("StatedNarrowing", reason(a));
                        }
                    }
                };
                claim(&r.quantity);
                for h in &r.holder {
                    if let pm::StatedHolderType::Holder(h) = h {
                        claim(&h.share);
                    }
                }
            }
        }
    }

    for n in CORPUS.iter().chain(FIXTURES) {
        let xml = read(n);
        let mut rd = SliceReader::new(&xml);
        walk(
            &mut m,
            &ProcessModulusElementType::deserialize(&mut rd).unwrap_or_else(|e| panic!("{n}: {e}")),
        );
    }
    for n in COMPOSITIONS {
        let xml = read(n);
        let mut rd = SliceReader::new(&xml);
        let c = CompositionType::deserialize(&mut rd).unwrap_or_else(|e| panic!("{n}: {e}"));
        for f in &c.fusion {
            if let process_modulus::asrt::StatedEliminationsTypeContent::Absent(a) =
                &f.eliminations.content[0]
            {
                *m.entry(("StatedEliminations", format!("{:?}", reason(a))))
                    .or_default() += 1;
            }
            let mut claims: Vec<&StatedClaimType> = Vec::new();
            for e in &f.eliminations.content {
                if let process_modulus::asrt::StatedEliminationsTypeContent::Elimination(e) = e {
                    claims.push(&e.quantity);
                }
            }
            claims.extend(f.part.iter().filter_map(|p| p.factor.as_ref()));
            for c in claims {
                if let StatedClaimType::Claim(c) = c {
                    if let StatedConstraintOriginType::Absent(a) = &c.bound_origin {
                        *m.entry(("boundOrigin", format!("{:?}", reason(a))))
                            .or_default() += 1;
                    }
                    if let StatedNarrowingType::Absent(a) = &c.narrows_when {
                        *m.entry(("StatedNarrowing", format!("{:?}", reason(a))))
                            .or_default() += 1;
                    }
                }
            }
        }
        walk(&mut m, &c.process_modulus);
    }
    m
}

/// ⭐⭐⭐ THE TEST. Every declared cell must match its verdict, and every state that turns up
/// in a document must be declared.
#[test]
fn every_admitted_state_has_a_verdict_and_the_documents_agree_with_it() {
    let seen = tally();
    let table = declared();

    let mut exercised = 0;
    let mut open = Vec::new();
    for (site, state, verdict) in &table {
        let n = seen
            .get(&(*site, format!("{state:?}")))
            .copied()
            .unwrap_or(0);
        match verdict {
            Exercised => {
                assert!(
                    n > 0,
                    "{site} / {state:?} is declared Exercised and no document files one. Either \
                     a fixture was deleted, or this cell should be Open with the reason written \
                     down — a state nothing exercises is a state nothing checks"
                );
                exercised += 1;
            }
            Incoherent(why) => assert_eq!(
                n, 0,
                "{site} / {state:?} is filed {n} time(s) and this table says it means nothing \
                 there.\n\n  {why}\n\nEither the document is wrong or the argument is. Both are \
                 worth settling before the count moves."
            ),
            Open(why) => {
                assert_eq!(
                    n, 0,
                    "{site} / {state:?} is now filed {n} time(s) and was recorded as Open \
                     because nobody had. Move it to Exercised and check that a rule handles \
                     it.\n\n  it was open because: {why}"
                );
                open.push((site, state));
            }
        }
    }

    // ⛔ A TABLE THAT DECLARED EVERYTHING Open WOULD PASS AND PROVE NOTHING. This is the
    // guard against the guard.
    assert!(
        exercised >= 23,
        "only {exercised} cells are exercised out of {} declared; this file is supposed to be \
         the answer to 'which states has anybody ever filed', not a list of intentions",
        table.len()
    );
    assert!(
        open.len() <= 2,
        "{} cells are Open: {open:?}. Each one is a state the schema admits, a reader may send, \
         and nothing in this repository has ever seen",
        open.len()
    );

    // ⛔⛔ AND EVERY STATE A DOCUMENT ACTUALLY FILES MUST BE IN THE TABLE. Without this the
    // file decays into a list of the cells somebody remembered, which is how the corpus came
    // to have eight wrappers with dark states in the first place.
    for (site, state) in seen.keys() {
        assert!(
            table
                .iter()
                .any(|(s, st, _)| s == site && &format!("{st:?}") == state),
            "{site} / {state} is filed by a document and has no verdict here. Add it: \
             Exercised if a rule handles it, Incoherent with the argument if it means nothing"
        );
    }
}

/// The three `Claimed` values, and the one that had no encoding until `CoverageEntry/complete`
/// stopped being an `xs:boolean`.
///
/// ⚠️ `partial` is exercised ONLY by a fixture, and that is deliberate rather than a shortfall.
/// A coverage entry is a witness's own claim about what its framework does; writing `partial`
/// into `coverage-us-gaap.xml` would put words in US GAAP's mouth to light a branch, which is
/// the failure `Verdict/diverged` names — a corpus that agrees with the schema by construction
/// measures nothing. The fixture's witness is openly invented and claims nothing about anybody.
#[test]
fn every_claimed_value_is_filed_somewhere() {
    let mut seen: BTreeMap<String, usize> = BTreeMap::new();
    for n in COVERAGES {
        let xml = read(n);
        let mut rd = SliceReader::new(&xml);
        let c = CoverageType::deserialize(&mut rd).unwrap_or_else(|e| panic!("{n}: {e}"));
        for e in &c.entry {
            *seen.entry(format!("{:?}", e.claimed)).or_default() += 1;
        }
    }
    for (v, verdict) in declared_claimed() {
        let n = seen.get(&format!("{v:?}")).copied().unwrap_or(0);
        assert_eq!(
            verdict == Exercised,
            n > 0,
            "`claimed = {v:?}` is filed {n} time(s) against a verdict of {verdict:?}"
        );
    }
}
