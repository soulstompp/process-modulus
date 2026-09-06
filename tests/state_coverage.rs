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

use std::collections::{BTreeMap, BTreeSet};
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
    /// ⭐⭐ THE BUDGET IS TWO, ENFORCED BELOW, AND THAT IS WHAT MAKES THIS ARM HONEST RATHER
    /// THAN A PARKING SPACE. Every other state either has a document filing it or has an
    /// argument here for why it means nothing. Removing this arm would leave the next dark
    /// state nowhere to be recorded except a reviewer's memory, which is where the eight of
    /// them found by this pass had been living — but leaving it UNCAPPED would let the next
    /// one be recorded and never settled, which is the same failure wearing a label.
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
        // ⛔⛔⛔ THERE IS NO `window` / `RNone` CELL, AND ITS DELETION IS THE POINT.
        // `absent reason="none"` here meant "the duty fraction is one", which is a VALUE and
        // not a nothing: it has a size and, in `LumpyQuantum/origin`, an author who could
        // change it. A line that cannot be stopped and a line somebody staffed round the
        // clock filed identically and neither said which it was. `window` is a
        // `StatedLumpyQuantum` whose absent arm is now a `ClaimAbsence`, so the state is not
        // spellable, and a whole duty cycle is filed as one whole period instead.
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
        // ⭐⭐⭐ AND THIS CELL IS NEW, BECAUSE UNTIL `support-cover` NO DOCUMENT HAD EVER
        // DECLINED AN ABSORBER. `Remainder` argues for it in as many words: "a remainder may
        // genuinely have been absorbed by NOTHING. A shop at capacity that turns people away
        // with no waiting list has a real remainder ... and nothing queued, stretched or
        // waited." ⛔ AND IT IS THE `none` THAT SURVIVES THE SWEEP THAT DELETED TWO OTHERS.
        // The test is whether the value arm has a NAMED STATE for the degenerate case:
        // `Fit` names the zero remainder (`clearance`), and a window of one whole period
        // names the duty fraction of one, so `none` was a second door at both. An absorber
        // names WHICH of three buffers took it, and choosing none of three is a genuine empty
        // selection with no size and no origin to lose.
        ("absorber", RNone, Exercised),
        // ---- the wrappers that were already here, and were never measured ----
        // ⛔ NO `RNone` CELL HERE EITHER, FOR THE SAME REASON ONE LEVEL UP. "There is no
        // remainder" reads either "nothing to subtract from" or "the remainder is zero", and
        // a remainder of zero is a CLEARANCE FIT carrying [0, 0, 0] and a sign, which `Fit`
        // settles in prose. Two spellings of one fact, and the absence arm is the one that
        // throws the sign away.
        ("StatedRemainder", Unmeasured, Open(
            "the schema's own annotation calls it \"the honest and commonest answer on a labour \
             layer\" — nobody has looked at whether this layer has a remainder. Coherent and \
             permitted; no document in this corpus needs it, because every layer here either \
             files a remainder or has none to file",
        )),
        // ⭐⭐⭐ AND THIS CELL USED TO SAY `Incoherent`, WITH AN ARGUMENT THAT INVITED ITS
        // OWN REFUTATION IN ITS LAST LINE: "a layer where the question is genuinely malformed
        // would refute this argument, and none has been filed." One had been. The old
        // reasoning ran "'does this layer have a remainder?' presupposes only that it is a
        // layer, and it has an answer: no" — but the remainder is `r = n - d`, and
        // `unstated/margin-ratio` states no nameplate at all. There is no `n`, so there is no
        // subtraction to have an answer, which is what `notApplicable` says. That document
        // numbers seven malformed questions about a ratio and this is the eighth.
        ("StatedRemainder", NotApplicable, Exercised),
        ("StatedRemainder", Derived, Incoherent(
            "⛔ IT WOULD DENY THREE THINGS TO CLAIM ONE. `derived` says the answer is stated \
             elsewhere and repeating it here would be a restatement — true of the remainder's \
             QUANTITY, which is why `Remainder/quantity` files `derived` and this corpus uses \
             it. But declining the whole wrapper also declines the absorber and the holders, \
             and neither is derivable from anything: an absorber is a borrowed term somebody \
             CHOSE, and a holder is an observation somebody MADE. No arrangement of figures \
             implies either",
        )),
        // ⭐⭐⭐ THE CELL IS GONE AND THE ARGUMENT IT CARRIED IS WHY. It said `none` was doing
        // the missing third member's job: a demand of [3,4,5] against a nameplate of 4 is a
        // TRANSITION fit, which the value arm names, so the absence was a second door to a
        // filed answer. That argument was right and lived only here and in the annotation
        // while the grammar admitted the state for revisions. `StatedFit` takes a
        // `pm:ClaimAbsence` now, so there is no cell because there is no state.
        // ⛔ FOUND BY A BIT MASK, not by reading. Fold `epistemics/absences.sqlc` to one row
        // per site and the reasons become a four-bit word; every site that admits `none`
        // showed `n` except two, and this was one of them: admitted, refused in prose, filed
        // zero times in twenty documents.
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
        // ---- ⭐⭐⭐ THE FOUR WRAPPERS THAT WERE NEVER IN FRAME ----
        //
        // Every cell below is `Exercised` and not one of them is a judgement call: each is a
        // state some document in `assets/` actually files, counted by a walker that until now
        // read what was INSIDE a claim and never the claim's own absence. The pass that built
        // this table audited the wrappers that had ARGUMENTS to audit, and `StatedClaim`,
        // `StatedHolder` and `StatedBasis` carry no annotation at all -- three bare
        // `xs:choice` types with nothing to read. That is why the most reused wrapper in the
        // schema had no row here.
        ("amount", NotApplicable, Exercised),
        ("amount", Unmeasured, Exercised),
        ("patience", Unmeasured, Exercised),
        ("timeSlack", Unmeasured, Exercised),
        ("timeSlack", NotApplicable, Exercised),
        ("timeSlack", Derived, Exercised),
        ("capacitySlack", Unmeasured, Exercised),
        ("capacitySlack", NotApplicable, Exercised),
        ("inventorySlack", Unmeasured, Exercised),
        ("inventorySlack", NotApplicable, Exercised),
        ("draw", Unmeasured, Exercised),
        ("draw", NotApplicable, Exercised),
        ("operation draw", Unmeasured, Exercised),
        ("share", Unmeasured, Exercised),
        ("remainder quantity", Unmeasured, Exercised),
        ("remainder quantity", Derived, Exercised),
        ("premium", Unmeasured, Exercised),
        // `StatedBasis` and `StatedBorrowedTerm`: the two that reach neither the database nor,
        // until now, this table. `measurementBasis` is `notApplicable` 35 times because the
        // quantity is physical -- a deliberate state `enterprise-contract` argues in its header.
        ("measurementBasis", NotApplicable, Exercised),
        ("standing", Unmeasured, Exercised),
        ("framework", RNone, Exercised),
        ("framework", Unmeasured, Exercised),
        ("chart", Unmeasured, Exercised),
        // ---- what sits under the line in a claim's unit ----
        ("StatedDenominator", NotApplicable, Exercised),
        ("StatedDenominator", Unmeasured, Exercised),
        ("StatedDenominator", RNone, Incoherent(
            "⛔ \"somebody looked and there is no denominator\" is precisely what \
             `notApplicable` says at this site. Two spellings of one state is the collapse the \
             wrapper exists to prevent, and the corpus files 91 of them",
        )),
        ("StatedDenominator", Derived, Incoherent(
            "⛔ deriving the denominator from the unit STRING is the `LIKE '% per %'` this \
             element replaced. Admitting the reason would license that read in the schema's own \
             voice, and a unit is an `xs:token` nothing may look inside",
        )),
        // ---- what a document says about being evidence at all ----
        ("StatedEvidence", Unmeasured, Exercised),
        ("StatedEvidence", RNone, Incoherent(
            "⛔ \"somebody looked and there is nothing to report\" does not parse. A document \
             that exists was written by somebody who knew whether they were observing or \
             stipulating, and unlike a `notation` that knowledge is not external, there is no \
             registry to be waiting on",
        )),
        ("StatedEvidence", NotApplicable, Incoherent(
            "⛔ there is no document the question fails to reach. Every document either reports \
             something somebody saw, or it does not, and a document claiming the question is \
             malformed is claiming to be outside the only distinction that decides whether it \
             may be quoted",
        )),
        ("StatedEvidence", Derived, Incoherent(
            "⛔ nothing in the model implies a document's standing. Admitting it would invite a \
             receiver to infer evidence FROM CONTENT, which is the one inference this element \
             exists to stop",
        )),
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
        // ⭐⭐⭐ AND THIS CELL SAID `Incoherent` UNTIL 2026-09-06, on the argument that "what
        // would tighten a range is a claim about instruments and interventions that do not
        // exist yet. There is nothing in the document to derive it from." There is, whenever a
        // claim is COMPUTED from its siblings. A `booked` share under a clearance is
        // `nameplate − demand`, so what would tighten it is the demand's own narrowing, one
        // element over and already filed. ⛔ Five claims were saying exactly that in prose and
        // typing themselves `instrument` — a width made of IGNORANCE that a better instrument
        // reveals — when no instrument is involved and nothing is unmeasured.
        //
        // ⚠️ SECOND CELL IN THIS TABLE REFUTED BY A FILING THIS WEEK, after
        // `StatedRemainder / NotApplicable`. The `Incoherent` arm is where this model's blind
        // spots are written down, which is the whole reason it carries an argument rather than
        // a flag.
        ("StatedNarrowing", Derived, Exercised),
        // ⭐⭐ NEW ON 2026-09-06, AND THE STATE EXISTED ALL ALONG WITH NOTHING IN IT.
        // `Coupling/strength` was an OPTIONAL `pm:StatedClaim`, which is two ways to say
        // nothing: the corpus omitted the element twice and filed this typed absence never.
        // The element is required now and the wrapper carries the absence, so a coupling
        // whose direction is on the routing logs and whose magnitude is on nobody's says so
        // in the one word that means it.
        ("strength", Unmeasured, Exercised),
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
    "fixtures/every-partial-elimination.xml",
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

fn reason(a: &pm::AbsenceType) -> String {
    format!("{:?}", a.reason)
}

/// The same, for the narrowed absence a `StatedClaim` takes. `ClaimAbsenceReason` is
/// `AbsenceReason` without `none`, so the two are different Rust enums with overlapping
/// spellings, and the counter keys on the spelling.
fn claim_reason(a: &pm::ClaimAbsenceType) -> String {
    format!("{:?}", a.reason)
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
        let mut bump = |site: &'static str, r: String| *m.entry((site, r)).or_default() += 1;

        // ⭐⭐⭐ EVERY `StatedClaim` POSITION IS COLLECTED RATHER THAN HANDLED WHERE IT SITS, AND
        // THAT IS THE REPAIR. The first version of this walker checked what was INSIDE each
        // claim -- `narrowsWhen`, `boundOrigin` -- at every position, and never once checked
        // the claim wrapper's OWN absence. So 259 typed absences across nine sites were counted
        // nowhere, in the file whose whole job is counting them.
        //
        // ⛔⛔ IT IS THE SAME BUG THIS FILE ALREADY FIXED ONCE, FOUR MORE TIMES. The note below
        // on `StatedRemainder` reads "only the `Remainder` arm was ever walked, so the arm
        // carrying the disagreement was counted nowhere" -- and that was equally true of
        // `StatedClaim`, `StatedHolder`, `StatedBasis` and `StatedBorrowedTerm`. Scattering the
        // positions is what let it happen twice; one list is what stops it happening again.
        let mut claims: Vec<(&'static str, &StatedClaimType)> = Vec::new();

        if let pm::StatedNotationType::Absent(a) = &doc.notation {
            bump("StatedNotation", reason(a));
        }
        if let pm::StatedEvidenceType::Absent(a) = &doc.evidence {
            bump("StatedEvidence", reason(a));
        }
        if let pm::StatedScopeType::Absent(a) = &doc.stack.scope {
            bump("StatedScope", reason(a));
        }

        // ⚠️ THE REGIME WAS NOT WALKED AT ALL. `StatedBorrowedTerm` exists, in its own words,
        // "for the two places a borrowed term is the FRAME a document is read under".
        for rg in &doc.regime {
            if let pm::StatedBorrowedTermType::Absent(a) = &rg.framework {
                bump("framework", reason(a));
            }
            if let pm::StatedBorrowedTermType::Absent(a) = &rg.chart {
                bump("chart", reason(a));
            }
        }

        for c in &doc.stack.couplings.content {
            match c {
                pm::StatedCouplingsTypeContent::Absent(a) => bump("StatedCouplings", reason(a)),
                // ⭐ REQUIRED SINCE 2026-09-06, so there is no `Option` to unwrap and no way
                //   to reach this site without a verdict. `strength` was optional AND a
                //   `StatedClaim`, which is two ways to say nothing: the corpus omitted the
                //   element twice and filed the typed absence never.
                pm::StatedCouplingsTypeContent::Coupling(k) => {
                    claims.push(("strength", &k.strength));
                }
            }
        }

        // ⚠️ NOR WERE THE OPERATIONS. A draw and an induced commitment are both `StatedClaim`.
        for op in &doc.operation {
            for c in &op.content {
                match c {
                    pm::OperationTypeContent::Draw(d) => claims.push(("operation draw", &d.quantity)),
                    pm::OperationTypeContent::Induces(i) => claims.push(("commitment", &i.commitment)),
                    _ => {}
                }
            }
        }

        for l in &doc.stack.layer {
            claims.push(("demand", &l.demand.amount));
            claims.push(("patience", &l.demand.patience));
            claims.push(("timeSlack", &l.time_slack));
            claims.push(("amount", &l.supply.nameplate.amount));
            claims.push(("capacitySlack", &l.supply.nameplate.capacity_slack));
            claims.push(("inventorySlack", &l.supply.nameplate.inventory_slack));
            claims.push(("draw", &l.supply.jagged.draw));

            if let pm::StatedBasisType::Absent(a) = &l.supply.jagged.measurement_basis {
                bump("measurementBasis", reason(a));
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
                            ) => bump("window", claim_reason(a)),
                            pm::DivisibilityTypeContent::Lumpy(q) => claims.push(("size", &q.size)),
                            pm::DivisibilityTypeContent::Continuous(c) => {
                                claims.push(("premium", &c.premium))
                            }
                            _ => {}
                        }
                    }
                }
            }

            // ⭐⭐⭐ THE WRAPPER ITSELF, WHICH THIS FILE MISSED FOR TWO REVISIONS. `Layer`
            // requires a `StatedRemainder` so that a sender who disagrees with "every layer
            // has a remainder" must SAY SO; only the `Remainder` arm was ever walked, so the
            // arm carrying the disagreement was counted nowhere. `assets/ddl/schema.ddl` was
            // dropping it at the same time and for the same reason.
            match &l.remainder {
                pm::StatedRemainderType::Absent(a) => bump("StatedRemainder", claim_reason(a)),
                pm::StatedRemainderType::Remainder(r) => {
                    if let StatedFitType::Absent(a) = &r.sign {
                        bump("StatedFit", claim_reason(a));
                    }
                    if let pm::StatedBorrowedTermType::Absent(a) = &r.absorber {
                        bump("absorber", reason(a));
                    }
                    claims.push(("remainder quantity", &r.quantity));
                    for h in &r.holder {
                        match h {
                            pm::StatedHolderType::Absent(a) => bump("holder", reason(a)),
                            pm::StatedHolderType::Holder(h) => claims.push(("share", &h.share)),
                        }
                    }
                }
            }
        }

        // ⛔⛔ THE WRAPPER AND WHAT IS INSIDE IT ARE TWO QUESTIONS, AND ONLY THE SECOND WAS EVER
        // ASKED. `absent reason="unmeasured"` on a `capacitySlack` says nobody measured the
        // headroom; a `boundOrigin` absence INSIDE a stated one says nobody owns its edge.
        // Reading only the second answers a question about edges on a corpus that never filed
        // the quantity.
        for (site, c) in claims {
            match c {
                StatedClaimType::Absent(a) => bump(site, claim_reason(a)),
                StatedClaimType::Claim(k) => {
                    if let StatedNarrowingType::Absent(a) = &k.narrows_when {
                        bump("StatedNarrowing", reason(a));
                    }
                    if let StatedConstraintOriginType::Absent(a) = &k.bound_origin {
                        bump("boundOrigin", reason(a));
                    }
                    if let pm::StatedDenominatorType::Absent(a) = &k.denominator {
                        bump("StatedDenominator", reason(a));
                    }
                    if let Some(pv) = &k.provenance {
                        if let pm::StatedBorrowedTermType::Absent(a) = pv.standing.as_ref() {
                            bump("standing", reason(a));
                        }
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
                *m.entry(("StatedEliminations", reason(a)))
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
                        *m.entry(("boundOrigin", reason(a)))
                            .or_default() += 1;
                    }
                    if let StatedNarrowingType::Absent(a) = &c.narrows_when {
                        *m.entry(("StatedNarrowing", reason(a)))
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
        exercised >= 48,
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

// ---------------------------------------------------------------------------
// ⛔⛔⛔ THE LOOP THIS FILE COULD NOT CLOSE, AND THE ONE IT EXISTS TO CLOSE FOR EVERYTHING ELSE.
//
// The table above asserts, in prose, that "adding a wrapper to either schema and not adding it
// here leaves its states unmeasured". Nothing enforced it. The site list was a Rust literal
// checked only against the tally it produced itself, so a wrapper that was never in frame was
// indistinguishable from one with no dark states, and FOUR of the sixteen never were.
//
// ⭐⭐ THE PATTERN IS ALREADY IN THIS DIRECTORY, TWICE. `tests/translation.rs` reads the schemas
// and asserts its declared list is what is on disk, in BOTH directions.
// `assets/sql/reports/integrity.sql` does the same for all three rosters, conformance, arithmetic and algebra: "declared,
// but no check produces it" and "produced, but not on the roster". This file measured every
// other instrument's coverage and had none of its own.
//
// ⚠️ WHY IT IS A SITE→TYPE MAP AND NOT A SET OF TYPES. One wrapper sits at several positions
// and an absence MEANS different things at each, that is the whole argument for the table
// above being keyed by site. `StatedConstraintOrigin` is `amountOrigin` and `boundOrigin`, and
// `derived` is coherent at one and not the other. So the schema is read for TYPES, the table
// declares SITES, and this map is the join nobody had written down.
// ---------------------------------------------------------------------------

/// How this file measures one wrapper.
#[derive(Debug)]
enum Measured {
    /// The site names the table above keys on for this wrapper.
    At(&'static [&'static str]),
    /// ⛔ NO VERDICT DECLARED AT ANY OF ITS SITES, with the count of absences the corpus
    /// actually files there and the reason it was missed. This arm exists so a gap is a ROW
    /// rather than a silence, the same bargain `Verdict::Open` strikes one level down, and
    /// the count below caps it at what was found, so it can only shrink.
    NotYet(&'static str),
}
use Measured::{At, NotYet};

/// Every wrapper in either schema that admits an absence, and where its states are counted.
///
/// ⚠️ `StatedLumpyQuantum` and `StatedRemainder` take a `pm:ClaimAbsence` rather than a
/// `pm:Absence`, so `none` is not among their states. They are listed here because the site is
/// still measured; the missing cell in the table above is the whole record of the narrowing.
const MEASURED_AT: [(&str, Measured); 16] = [
    ("StatedConstraintOrigin", At(&["amountOrigin", "boundOrigin"])),
    ("StatedLumpyQuantum", At(&["window"])),
    ("StatedCouplings", At(&["StatedCouplings"])),
    ("StatedDenominator", At(&["StatedDenominator"])),
    ("StatedDivisibility", At(&["StatedDivisibility"])),
    ("StatedEliminations", At(&["StatedEliminations"])),
    ("StatedEvidence", At(&["StatedEvidence"])),
    ("StatedFit", At(&["StatedFit"])),
    ("StatedNarrowing", At(&["StatedNarrowing"])),
    ("StatedNotation", At(&["StatedNotation"])),
    ("StatedRemainder", At(&["StatedRemainder"])),
    ("StatedScope", At(&["StatedScope"])),
    // ---- the four that were never in frame ----
    ("StatedClaim", At(&["amount", "patience", "timeSlack", "capacitySlack", "inventorySlack",
        "draw", "operation draw", "share", "remainder quantity", "premium", "strength"])),
    ("StatedBorrowedTerm", At(&["standing", "framework", "chart", "absorber"])),
    ("StatedBasis", At(&["measurementBasis"])),
    ("StatedHolder", NotYet(
        "no document files one. That may be a real dark state worth an `Open` argument or an \
         `Incoherent` one, a remainder nobody can name a holder for is a strong claim, but \
         it has never been decided, which is the difference between an unfiled state and an \
         unexamined one",
    )),
];

/// The two schemas, read as text. ⚠️ Not `read()` above: that one is rooted at `assets/`.
fn schema(name: &str) -> String {
    let path = format!("{}/schema/{name}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// The `name="X"` of every complexType containing an `absent` arm.
///
/// ⚠️ Walks back to the enclosing `<xs:complexType name=`, which works because every named type
/// in both schemas is top level. The one anonymous complexType, `processModulus`'s, carries
/// no `absent` and so is never the answer to this walk.
fn wrappers_in(src: &str) -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    for (i, _) in src.match_indices(r#"<xs:element name="absent""#) {
        let head = &src[..i];
        if let Some(d) = head.rfind(r#"<xs:complexType name=""#) {
            let rest = &head[d + 22..];
            if let Some(end) = rest.find('"') {
                found.insert(rest[..end].to_string());
            }
        }
    }
    found
}

/// ⛔⛔⛔ ADDING A WRAPPER TO EITHER SCHEMA AND NOT ADDING IT HERE NOW FAILS THE BUILD.
///
/// That sentence was the table's claim about itself from the day it was written, and this is
/// the first thing that holds it to it.
#[test]
fn every_wrapper_that_admits_an_absence_is_accounted_for() {
    let mut on_disk = BTreeSet::new();
    for file in ["process-modulus.xsd", "assertion.xsd"] {
        on_disk.extend(wrappers_in(&schema(file)));
    }
    let accounted: BTreeSet<String> = MEASURED_AT.iter().map(|(t, _)| t.to_string()).collect();
    assert_eq!(
        on_disk, accounted,
        "the wrappers on disk and the wrappers this file accounts for disagree. A new one \
         needs either a site in the table above or a `NotYet` saying why not, silence is the \
         one thing that must stop being available"
    );
}

/// ⛔ AND IN THE OTHER DIRECTION: no site is keyed in the table that belongs to no wrapper.
///
/// ⚠️ A typo'd site name is the failure this catches, and it is invisible without it: a
/// misspelled key declares verdicts nothing ever bumps, so its states read as `Exercised`
/// against a tally of zero, which the assertion above would report as a dark state at a site
/// that does not exist.
#[test]
fn every_site_in_the_table_belongs_to_a_declared_wrapper() {
    let mapped: BTreeSet<&str> = MEASURED_AT
        .iter()
        .filter_map(|(_, m)| match m {
            At(sites) => Some(sites.iter().copied()),
            NotYet(_) => None,
        })
        .flatten()
        .collect();
    let keyed: BTreeSet<&str> = declared().iter().map(|(site, _, _)| *site).collect();
    assert_eq!(
        keyed, mapped,
        "the sites the verdict table keys on and the sites MEASURED_AT maps are not the same set"
    );
}

/// ⭐⭐ THE UNMEASURED SET MAY SHRINK AND MAY NOT GROW, which is what makes `NotYet` a record
/// rather than a parking space, the same bargain, and the same danger, as `Verdict::Open`.
///
/// It began at four. `StatedClaim`, `StatedBorrowedTerm` and `StatedBasis` are measured now;
/// `StatedHolder` is the one left, and it is left on purpose. No document has ever filed an
/// absence at `Remainder/holder`, so there is nothing to declare `Exercised`, and deciding
/// whether "somebody looked and nobody bears this remainder" contradicts the conservation
/// claim, or is the sharpest counter-example the model admits, is a judgement about the model
/// rather than a fact about the corpus. The wrapper carries no annotation to read it off.
#[test]
fn statedholder_is_the_only_wrapper_still_unmeasured() {
    let not_yet: Vec<&str> = MEASURED_AT
        .iter()
        .filter(|(_, m)| matches!(m, NotYet(_)))
        .map(|(t, _)| *t)
        .collect();
    assert_eq!(
        not_yet,
        ["StatedHolder"],
        "declaring verdicts for one of these means removing it from here; adding a fifth means \
         a wrapper went unmeasured after this test existed to stop that"
    );
}
