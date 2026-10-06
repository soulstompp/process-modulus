//! The stipulations, and the negative controls. `assets/fixtures/README.md` says why these
//! documents are not in `assets/corpus/` and are never cited as evidence about a business.
//!
//! Two different kinds of check live here, and they are not interchangeable:
//!
//!   a fixture       shows a state is reachable: it validates, round-trips, and a rule
//!                   handles it. It cannot show the rule would catch anything
//!   a negative      shows the checker bites: the same rule, run against a document
//!   control         mutated in memory to be wrong, must reject it
//!
//! Of a fixture's three verbs, the first is a validator's job and the second is
//! `tests/roundtrip.rs`, which walks this directory alongside the corpus so that a state the
//! schema admits is also a state the generated crate can write back out. Only the third is
//! here.
//!
//! A repository with only fixtures reports green for rules that examine nothing, which is the
//! trap this codebase names as *"a bound with nothing to bound passes loudest."* A repository
//! with only negative controls never learns that a state exists.
//!
//! The mutation is in memory, and the files on disk are never touched. The generated types
//! derive `Clone`, so a parsed fusion can be copied, broken, and fed back to the same function
//! the passing test uses, and the check runs on every build.
//!
//! Most of what is broken here is a composition, because the sum rule is the one rule in the
//! model with exact arithmetic to violate. `tests/composition.rs` is the positive half and
//! reads the corpus; this file stipulates the states that corpus has no business filing.

use std::fs;

use process_modulus::asrt::{
    CompositionType, EliminationAgainstType, FusionType, StatedEliminationsTypeContent,
};
use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, AbsenceType, IdentityType, LayerType, ProcessModulusElementType,
    StatedEliminatedQuantityType, StatedSummedQuantityType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

type Triple = (f64, f64, f64);

fn read(rel: &str) -> String {
    let path = format!("{}/assets/{rel}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

fn members() -> ProcessModulusElementType {
    let xml = read("fixtures/every-absence.xml");
    let mut rd = SliceReader::new(&xml);
    ProcessModulusElementType::deserialize(&mut rd).expect("every-absence.xml parses")
}

fn composition() -> CompositionType {
    let xml = read("fixtures/every-elimination.xml");
    let mut rd = SliceReader::new(&xml);
    CompositionType::deserialize(&mut rd).expect("every-elimination.xml parses")
}

fn local() -> CompositionType {
    let xml = read("fixtures/every-local-part.xml");
    let mut rd = SliceReader::new(&xml);
    CompositionType::deserialize(&mut rd).expect("every-local-part.xml parses")
}

fn partial() -> CompositionType {
    let xml = read("fixtures/every-partial-elimination.xml");
    let mut rd = SliceReader::new(&xml);
    CompositionType::deserialize(&mut rd).expect("every-partial-elimination.xml parses")
}

fn inverting() -> CompositionType {
    let xml = read("fixtures/every-inverting-elimination.xml");
    let mut rd = SliceReader::new(&xml);
    CompositionType::deserialize(&mut rd).expect("every-inverting-elimination.xml parses")
}

fn derived_elimination() -> CompositionType {
    let xml = read("fixtures/every-derived-elimination.xml");
    let mut rd = SliceReader::new(&xml);
    CompositionType::deserialize(&mut rd).expect("every-derived-elimination.xml parses")
}

/// The URN a filing gives for itself, which is all local composition rests on.
fn notation(doc: &ProcessModulusElementType) -> Option<&str> {
    match &doc.notation {
        pm::StatedNotationType::Uri(u) => Some(u.as_str()),
        pm::StatedNotationType::Absent(_) => None,
    }
}

fn layer<'a>(doc: &'a ProcessModulusElementType, name: &str) -> &'a LayerType {
    doc.stack
        .layer
        .iter()
        .find(|l| l.name == name)
        .unwrap_or_else(|| panic!("no layer `{name}`"))
}

fn fusion<'a>(c: &'a CompositionType, name: &str) -> &'a FusionType {
    c.fusion
        .iter()
        .find(|f| f.name == name)
        .unwrap_or_else(|| panic!("no fusion `{name}`"))
}

/// A summed quantity's filed figure, or `None` where it is computed or typed absent.
fn triple(s: &StatedSummedQuantityType) -> Option<Triple> {
    match s {
        StatedSummedQuantityType::Claim(c) => Some((c.low, c.most_likely, c.high)),
        StatedSummedQuantityType::Derivation(_) | StatedSummedQuantityType::Absent(_) => None,
    }
}

/// An eliminated quantity's filed figure, or `None` where it is computed or typed absent.
fn eliminated(s: &StatedEliminatedQuantityType) -> Option<Triple> {
    match s {
        StatedEliminatedQuantityType::Claim(c) => Some((c.low, c.most_likely, c.high)),
        StatedEliminatedQuantityType::Derivation(_) | StatedEliminatedQuantityType::Absent(_) => None,
    }
}

fn demand(l: &LayerType) -> Triple {
    triple(&l.demand.amount).expect("every fixture layer states its demand")
}

fn nameplate(l: &LayerType) -> Triple {
    triple(&l.supply.nameplate.amount).expect("this fixture layer states its nameplate")
}

fn close(a: Triple, b: Triple) -> bool {
    (a.0 - b.0).abs() < 1e-9 && (a.1 - b.1).abs() < 1e-9 && (a.2 - b.2).abs() < 1e-9
}

fn elimination_absence(f: &FusionType) -> Option<&AbsenceType> {
    f.eliminations.content.iter().find_map(|e| match e {
        StatedEliminationsTypeContent::Absent(a) => Some(a),
        StatedEliminationsTypeContent::Elimination(_) => None,
    })
}

/// What a fusion's parts sum to, or `None` where no sum is owed.
///
/// This is `tests/composition.rs`'s `expected` reduced to the fixture's shape, and the branch that
/// matters is the first one. A composer who never looked for double counting owes no equation
/// at all, so the honest answer is neither a pass nor a failure but unchecked: a third outcome,
/// and one an empty `elimination` list could not give, because it would be byte-identical to a
/// clean search.
///
/// `against` is not decoration, and without it this function is wrong in a way no fixture sees
/// until one files an elimination. Subtract every elimination from whichever quantity is being
/// computed and a corpus filing none agrees exactly, while the first document that files one is
/// off by every elimination filed against the other quantity. `EliminationAgainst`'s own
/// annotation says why: an elimination that does not name which quantity it hits is an
/// adjustment applied to whichever number the reader happened to be holding. The reader here is
/// this function.
///
/// The elimination is subtracted bound by bound unless that inverts, and then the crossed pairing
/// is the sum: point parts with an elimination of width have no spread for the overlap to move
/// with. `assets/fixtures/every-inverting-elimination.xml` files it.
fn expected(
    c: &ProcessModulusElementType,
    f: &FusionType,
    against: EliminationAgainstType,
    of: fn(&LayerType) -> Triple,
) -> Option<Triple> {
    if let Some(a) = elimination_absence(f) {
        if a.reason == AbsenceReasonType::Unmeasured {
            return None;
        }
    }
    let mut total = (0.0, 0.0, 0.0);
    for p in &f.part {
        let l = of(layer(c, &p.layer.filing.id));
        total = (total.0 + l.0, total.1 + l.1, total.2 + l.2);
    }
    let mut removed = (0.0, 0.0, 0.0);
    for e in &f.eliminations.content {
        if let StatedEliminationsTypeContent::Elimination(e) = e {
            if e.against != against {
                continue;
            }
            match &e.quantity {
                StatedEliminatedQuantityType::Claim(q) => {
                    removed = (removed.0 + q.low, removed.1 + q.most_likely, removed.2 + q.high)
                }
                // A zero elimination is `[0, 0, 0]` and lands in the arm above. There is no
                // `none` spelling for it: `ClaimAbsenceReason` does not carry one. A computed
                // elimination suspends the sum as `eliminations/unsized.sqlc` does, because
                // nothing here computes it.
                StatedEliminatedQuantityType::Derivation(_) | StatedEliminatedQuantityType::Absent(_) => {
                    return None
                }
            }
        }
    }
    let bound_by_bound = (total.0 - removed.0, total.1 - removed.1, total.2 - removed.2);
    if bound_by_bound.0 <= bound_by_bound.1 && bound_by_bound.1 <= bound_by_bound.2 {
        Some(bound_by_bound)
    } else {
        Some((total.0 - removed.2, total.1 - removed.1, total.2 - removed.0))
    }
}

/// The two states `assets/corpus/` cannot reach, and they owe different arithmetic.
///
/// Every empty fusion in the corpus is a one-part fusion filing `notApplicable`, so without this
/// fixture the two branches that decide the sum rule would never run. Filed eliminations make
/// the rule exact rather than a warning for a fusion that files one; this holds the two ways of
/// filing none.
#[test]
fn a_checked_search_owes_an_exact_sum_and_an_unchecked_one_owes_nothing() {
    let (m, c) = (members(), composition());

    // `baking`: somebody looked and found no double counting, so the composed figure is the
    // sum and a checker owes that equality to the digit.
    let baking = fusion(&c, "baking");
    assert_eq!(
        elimination_absence(baking).map(|a| a.reason.clone()),
        Some(AbsenceReasonType::None)
    );
    for (what, of) in [
        ("demand", demand as fn(&LayerType) -> Triple),
        ("nameplate", nameplate),
    ] {
        let against = if what == "demand" {
            EliminationAgainstType::Demand
        } else {
            EliminationAgainstType::Nameplate
        };
        let computed = expected(&m, baking, against, of).expect("a checked search owes a sum");
        let stated = of(layer(&c.process_modulus, "baking"));
        assert!(
            close(stated, computed),
            "`baking` {what}: composed {stated:?} against the parts' sum {computed:?}. With the \
             search filed as `none` there is nothing to remove, so these must agree exactly"
        );
    }

    // `mixing`: nobody looked, and the filed figure does not reconcile, on purpose.
    let mixing = fusion(&c, "mixing");
    assert_eq!(
        elimination_absence(mixing).map(|a| a.reason.clone()),
        Some(AbsenceReasonType::Unmeasured)
    );
    assert_eq!(
        expected(&m, mixing, EliminationAgainstType::Demand, demand),
        None,
        "an unchecked search suspends the sum rule. A checker that returned a number here \
         would be asserting an equality the composer explicitly did not claim"
    );

    // And the discrepancy is real, which is what makes the suspension worth something. If the
    // fixture happened to reconcile, `unmeasured` and `none` would have the same consequences,
    // and this test would pass while showing nothing.
    let parts: Triple = mixing.part.iter().fold((0.0, 0.0, 0.0), |a, p| {
        let l = demand(layer(&m, &p.layer.filing.id));
        (a.0 + l.0, a.1 + l.1, a.2 + l.2)
    });
    let stated = demand(layer(&c.process_modulus, "mixing"));
    assert!(
        !close(stated, parts),
        "`mixing` reconciles at {stated:?}, so the suspended branch has nothing to suspend. \
         The fixture must file a figure that differs from the parts' sum {parts:?}, or a checker \
         that ignored the search entirely would pass this test"
    );
}

/// The negative control. Everything above is a rule reporting that a document is fine. This is
/// the same rule, on the same code path, reporting that a broken one is not, and the document
/// is broken in memory, so nothing on disk changes and nothing has to be restored.
///
/// It replaces a ritual. Showing a rule able to fail otherwise means somebody copies a corpus
/// file to a scratchpad, edits it, runs the suite, reads the failure and copies the file back.
/// That is a real check, and it runs once, in one person's terminal, and leaves behind a
/// sentence in a note. This runs on every build.
#[test]
fn the_sum_rule_rejects_a_fusion_that_does_not_reconcile() {
    let (m, c) = (members(), composition());
    let baking = fusion(&c, "baking");

    // The control: unbroken, it agrees.
    let good = expected(&m, baking, EliminationAgainstType::Demand, demand)
        .expect("a checked search owes a sum");
    assert!(close(good, demand(layer(&c.process_modulus, "baking"))));

    // Break one part's demand by 100, and the sum must move by exactly 100 at every bound.
    let mut broken = m.clone();
    let l = broken
        .stack
        .layer
        .iter_mut()
        .find(|l| l.name == "oven")
        .expect("oven");
    if let StatedSummedQuantityType::Claim(d) = &mut l.demand.amount {
        d.low += 100.0;
        d.most_likely += 100.0;
        d.high += 100.0;
    }

    let bad = expected(&broken, baking, EliminationAgainstType::Demand, demand)
        .expect("still owed, the search is unchanged");
    assert!(
        !close(bad, demand(layer(&c.process_modulus, "baking"))),
        "a part's demand moved by 100 and the composed figure still reconciles, which means \
         this rule is not reading the parts at all"
    );
    assert!(
        (bad.1 - good.1 - 100.0).abs() < 1e-9,
        "the sum moved by {} rather than the 100 that was injected, so it is not a sum",
        bad.1 - good.1
    );
}

/// The second negative control, and the one the elimination search exists for. Swap a fusion's
/// search result and nothing else (same parts, same figures, same prose) and the arithmetic a
/// checker owes changes.
///
/// That shows the wrapper carries weight rather than vocabulary. Under a bare
/// `minOccurs="0" maxOccurs="unbounded"` these two documents would be byte-identical, so no test
/// like this could be written: one document, one verdict. The wrapper makes two of each, and
/// this test fails if a refactor collapses them back.
#[test]
fn the_same_figures_owe_different_arithmetic_under_a_different_search() {
    let (m, c) = (members(), composition());
    let mixing = fusion(&c, "mixing").clone();

    // As filed: nobody looked, so no equality is owed.
    assert_eq!(
        expected(&m, &mixing, EliminationAgainstType::Demand, demand),
        None
    );

    // Change only the search result to `none`, so that the composer claims they looked and
    // found nothing, and the very same figures become a violation.
    let mut claimed_clean = mixing.clone();
    claimed_clean.eliminations.content = vec![StatedEliminationsTypeContent::Absent(AbsenceType {
        reason: AbsenceReasonType::None,
        note: Some("mutated in memory: the composer now claims a clean search".into()),
        provenance: None,
        as_of: None,
    })];

    let owed = expected(&m, &claimed_clean, EliminationAgainstType::Demand, demand)
        .expect("a clean search owes an exact sum, which is the whole difference");
    let stated = demand(layer(&c.process_modulus, "mixing"));
    assert!(
        !close(owed, stated),
        "the same figures reconcile under a clean search, so the two states have identical \
         consequences here and the fixture shows nothing"
    );

    // And the size of the violation is the size of the double counting nobody measured.
    assert!(
        (owed.1 - stated.1 - 400.0).abs() < 1e-9,
        "expected the unstated netting to be 400 doughs at the mode, found {}",
        owed.1 - stated.1
    );
}

/// The fixtures are stipulations and say so twice: in a comment, where a reader who opens one
/// file without reading the directory's README meets it, and in `pm:evidence`, where a receiver
/// does. The comment alone would not do: matched as a substring over a whole document, it would
/// make a corpus file that only quotes the sentence a stipulation, and a Portuguese fixture
/// would have to announce itself in English.
///
/// `every-draft.xml` is the one exception, and it is the point of that file. It files
/// `absent/reason = unmeasured` on purpose, because the state a first-time adopter's document
/// is really in is "nobody has said", and `tests/state_coverage.rs` can only call that state
/// Exercised if some document is in it. The comment still announces the file, so a human is
/// never misled; the element declines to, so a machine is never made to guess.
///
/// The files are read from the directory rather than listed, so a fixture added beside the others
/// is held to this without anybody remembering to name it here.
#[test]
fn every_fixture_declares_that_it_is_a_stipulation() {
    let dir = format!("{}/assets/fixtures", env!("CARGO_MANIFEST_DIR"));
    let mut names: Vec<String> = fs::read_dir(&dir)
        .unwrap_or_else(|e| panic!("{dir}: {e}"))
        .flatten()
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .filter(|n| n.ends_with(".xml"))
        .collect();
    names.sort();
    assert!(
        names.iter().any(|n| n == "every-draft.xml"),
        "the directory read found no `every-draft.xml`, so it read the wrong directory"
    );
    for name in &names {
        let body = read(&format!("fixtures/{name}"));
        assert!(
            body.contains("A stipulation, not a filing"),
            "{name}: a fixture that does not announce itself will eventually be quoted as \
             evidence, which is the one thing this directory must not allow"
        );

        if name == "every-draft.xml" {
            assert!(
                !body.contains("<pm:attests>"),
                "{name}: this file exists to be the document that declines to say. Filing a \
                 value here leaves StatedEvidence/unmeasured with nothing exercising it"
            );
        } else {
            assert!(
                body.contains("<pm:attests>stipulation</pm:attests>"),
                "{name}: the comment announces it to a reader and nothing announces it to a \
                 receiver. That is the gap `pm:evidence` closes"
            );
        }
    }
}

/// The construction a third party performs: theirs, mine, and one made out of both, with all
/// three still separable afterwards.
///
/// It takes no new relation. `Part/layer` addresses a layer as `{notation, id}` where the
/// notation is a filing's URN, and a filing names itself with its own notation. A part whose
/// notation matches its own composition's is a local part: there is no second kind of part, no
/// new element, and the distinction is a string comparison against the filing's own name.
///
/// It looks as if it needs a new relation beside `Fusion`, and it does not. The whole of it is
/// one self-identifier: a filing that says which filing it is.
#[test]
fn a_composer_builds_a_layer_out_of_two_layers_they_built() {
    let c = local();
    let own = notation(&c.process_modulus).expect("this fixture names itself");

    let kind = |name: &str| -> Vec<bool> {
        c.fusion
            .iter()
            .find(|f| f.name == name)
            .unwrap_or_else(|| panic!("no fusion `{name}`"))
            .part
            .iter()
            .map(|p| p.layer.filing.notation == own)
            .collect()
    };

    // theirs: one part, and it is not this document's
    assert_eq!(kind("as-filed"), vec![false]);
    // both: two parts, and both are
    assert_eq!(kind("both-views"), vec![true, true]);

    // mine: originated, so it has no fusion at all. That is the schema's documented third
    // state, and not a marker for "proposed". It is real in this document's context, asserted
    // by this witness; a flag saying otherwise would be a document arguing with its signature.
    assert!(
        !c.fusion.iter().any(|f| f.name == "as-contracted"),
        "`as-contracted` is originated; a fusion for it would make it a restatement"
    );

    // And all three are still there. The operation is non-destructive, which is what
    // separates it from a consolidation: fusing two members' layers leaves the group with one.
    let names: Vec<&str> = c
        .process_modulus
        .stack
        .layer
        .iter()
        .map(|l| l.name.as_str())
        .collect();
    assert_eq!(names, vec!["as-filed", "as-contracted", "both-views"]);
}

/// And the alternation is an ordinary fusion with an elimination.
///
/// Two views of one quantity summed is that quantity counted twice, which is exactly what
/// `Elimination` removes: `EliminationAgainst/demand` is what was asked, counted twice. So the
/// sum rule a checker owes here is the same one it owes everywhere, unrelaxed.
///
/// That is the test of whether a fusion is the right answer here. Had holding two readings of
/// one number needed the rule suspended or special-cased, it would be a new relation wearing a
/// fusion's clothes. It does not.
#[test]
fn two_views_of_one_number_reconcile_under_the_unmodified_sum_rule() {
    let c = local();
    let both = fusion(&c, "both-views");
    let stack = &c.process_modulus;

    for (what, of) in [
        ("demand", demand as fn(&LayerType) -> Triple),
        ("nameplate", nameplate),
    ] {
        let against = if what == "demand" {
            EliminationAgainstType::Demand
        } else {
            EliminationAgainstType::Nameplate
        };
        let computed =
            expected(stack, both, against.clone(), of).expect("a filed elimination owes a sum");
        let stated = of(layer(stack, "both-views"));
        assert!(
            close(stated, computed),
            "`both-views` {what}: composed {stated:?} against the parts less their eliminations \
             {computed:?}"
        );

        // The elimination is one whole copy, at every bound, not a point. `Elimination`
        // subtracts component-wise because it removes a component of the very figure it comes
        // off, and for two views of one quantity that is exact: the removed copy is the
        // figure, so it moves with it. Subtracting a point here is the easiest way to get it
        // wrong, and this fixture catches that.
        let e = both
            .eliminations
            .content
            .iter()
            .find_map(|x| match x {
                StatedEliminationsTypeContent::Elimination(e) if e.against == against => Some(e),
                _ => None,
            })
            .unwrap_or_else(|| panic!("no {what} elimination"));
        let removed = eliminated(&e.quantity).expect("sized");
        assert!(
            close(removed, of(layer(stack, "as-filed"))),
            "the {what} elimination is {removed:?} and one whole view is {:?}. Removing less \
             than a copy leaves the quantity partly doubled; removing more deletes real figures",
            of(layer(stack, "as-filed"))
        );
    }

    // And without the elimination it is wrong by exactly one copy: the negative control for
    // the claim that no new relation is needed.
    let mut naive = both.clone();
    naive.eliminations.content.clear();
    let doubled = expected(stack, &naive, EliminationAgainstType::Demand, demand)
        .expect("no eliminations, so a sum is owed");
    let one = demand(layer(stack, "both-views"));
    assert!(
        (doubled.1 - 2.0 * one.1).abs() < 1e-9,
        "dropping the elimination gives {doubled:?}, which should be exactly twice {one:?}"
    );
}

/// A filing that cannot name itself cannot be composed, and that is the honest consequence
/// rather than a gap: a composition asserting a relationship to a filing nobody can identify
/// is asserting a relationship to nothing.
#[test]
fn a_filing_that_declines_to_name_itself_cannot_be_a_part() {
    let xml = read("fixtures/every-draft.xml");
    let mut rd = SliceReader::new(&xml);
    let draft = ProcessModulusElementType::deserialize(&mut rd).expect("every-draft.xml parses");

    assert!(
        notation(&draft).is_none(),
        "this fixture exists to be the document a first-time adopter has: unpublished"
    );

    // Nothing in either directory composes from it, and nothing could.
    for name in [
        "fixtures/every-local-part.xml",
        "fixtures/every-elimination.xml",
    ] {
        let xml = read(name);
        let mut rd = SliceReader::new(&xml);
        let c = CompositionType::deserialize(&mut rd).unwrap_or_else(|e| panic!("{name}: {e}"));
        for f in &c.fusion {
            for p in &f.part {
                assert!(
                    !p.layer.filing.notation.is_empty(),
                    "{name}: a part with an empty notation names no filing at all"
                );
            }
        }
    }
}

/// An elimination wider than the sum it corrects. Two point parts of 10 and a shared block of
/// `[2, 3, 5]`: bound by bound that is `[18, 17, 15]`, which is not a claim, and the composed
/// nameplate is filed as the crossed pairing `[15, 17, 18]`. The demand in the same fusion
/// eliminates `[0, 0, 0]` and is still bound by bound, so both branches run on one fusion.
#[test]
fn an_elimination_wider_than_its_sum_reconciles_under_the_crossed_pairing() {
    let c = inverting();
    let f = fusion(&c, "shift-capacity");
    let stack = &c.process_modulus;

    let parts = ["team-a", "team-b"].map(|p| nameplate(layer(stack, p)));
    assert!(
        parts.iter().all(|p| p.0 == p.2),
        "the inversion needs point parts, and this fixture files {parts:?}"
    );
    let sum = (parts[0].0 + parts[1].0, parts[0].1 + parts[1].1, parts[0].2 + parts[1].2);
    assert!(close(sum, (20.0, 20.0, 20.0)));
    let bound_by_bound = (sum.0 - 2.0, sum.1 - 3.0, sum.2 - 5.0);
    assert!(
        bound_by_bound.0 > bound_by_bound.2,
        "{bound_by_bound:?} must invert, or this fixture exercises nothing new"
    );

    let computed = expected(stack, f, EliminationAgainstType::Nameplate, nameplate)
        .expect("a sized elimination owes a sum");
    assert!(close(computed, (15.0, 17.0, 18.0)));
    assert!(close(nameplate(layer(stack, "shift-capacity")), computed));

    let computed = expected(stack, f, EliminationAgainstType::Demand, demand)
        .expect("a sized elimination owes a sum");
    assert!(close(demand(layer(stack, "shift-capacity")), computed));
}

/// The derivation arm of an eliminated quantity, which suspends the sum rather than sizing it.
///
/// `pm:StatedEliminatedQuantity` admits a claim, a typed absence and a derivation, and `expected`
/// above carries a branch for the derivation. This fixture files one, so that branch, the state
/// the grammar admits and the column `pm.elimination.derivation` all answer to a document.
///
/// What it costs is the point. `sharedParts` sums over the highest layers two or more of a
/// fusion's parts reach, and these two reach no common layer, so there is nothing for it to
/// compute. The nameplate sum is therefore not owed, and the composed nameplate stands on the
/// composer's word. The demand elimination in the same fusion is stated at zero, so that sum is
/// owed and is exact, and one fusion runs both outcomes at once.
#[test]
fn a_derived_elimination_suspends_its_sum_and_leaves_the_other_owed() {
    let c = derived_elimination();
    let f = fusion(&c, "crew-capacity");
    let stack = &c.process_modulus;

    let against_nameplate = f
        .eliminations
        .content
        .iter()
        .filter_map(|e| match e {
            StatedEliminationsTypeContent::Elimination(e) => Some(e),
            StatedEliminationsTypeContent::Absent(_) => None,
        })
        .find(|e| e.against == EliminationAgainstType::Nameplate)
        .expect("this fixture files a nameplate elimination");
    let derivation = match &against_nameplate.quantity {
        StatedEliminatedQuantityType::Derivation(d) => d,
        StatedEliminatedQuantityType::Claim(_) | StatedEliminatedQuantityType::Absent(_) => {
            panic!("this fixture exists to file the derivation arm; the other two are filed elsewhere")
        }
    };
    assert_eq!(
        derivation.identity,
        IdentityType::SharedParts,
        "the derivation must name the identity that would compute the overlap"
    );

    // The parts really do assert an unstated overlap: points summing to 20 against a filed 18.
    let parts = ["crew-a", "crew-b"].map(|p| nameplate(layer(stack, p)));
    assert!(parts.iter().all(|p| p.0 == p.2), "the parts are points, and this fixture needs them so");
    let sum = parts[0].0 + parts[1].0;
    let composed = nameplate(layer(stack, "crew-capacity"));
    assert!(close(composed, (15.0, 17.0, 18.0)));
    assert!(
        composed.2 < sum,
        "the composed nameplate must be less than the parts' sum, or nothing is being eliminated"
    );

    // And no rule may hold the composer to it, because the correction is not sized.
    assert!(
        expected(stack, f, EliminationAgainstType::Nameplate, nameplate).is_none(),
        "a derived elimination owes no sum: nothing here computes one, so a figure would be invented"
    );

    // The other quantity in the same fusion is owed, and it reconciles exactly.
    let owed = expected(stack, f, EliminationAgainstType::Demand, demand)
        .expect("a sized elimination owes a sum, and zero is sized");
    assert!(close(owed, (11.0, 13.0, 15.0)));
    assert!(close(demand(layer(stack, "crew-capacity")), owed));
}

/// A nameplate elimination is a magnitude, not a selector, and this is the fixture that says
/// so. `merge-group-composition`'s `shift-line` and `every-local-part`'s `both-views` each remove
/// a whole part, and `both-views` asserts the whole-copy property directly. Two data points at
/// one end of a scale read like a category, and the category they suggest is that a nameplate
/// elimination picks out a kind of fusion.
///
/// It does not. `e` is how much supply the parts counted in common: none, some, or all of a
/// part. This fixture files some, 3 of a 10, and the sum rule is the same rule, unmodified. The
/// parts are fungible here exactly as they are at both ends, and `observed` says so in the
/// document; nothing about the arithmetic decides that judgement.
#[test]
fn a_partial_nameplate_elimination_reconciles_under_the_unmodified_sum_rule() {
    let c = partial();
    let f = fusion(&c, "shift-capacity");
    let stack = &c.process_modulus;

    for (what, of, against) in [
        (
            "demand",
            demand as fn(&LayerType) -> Triple,
            EliminationAgainstType::Demand,
        ),
        ("nameplate", nameplate, EliminationAgainstType::Nameplate),
    ] {
        let computed = expected(stack, f, against, of).expect("a filed elimination owes a sum");
        let stated = of(layer(stack, "shift-capacity"));
        assert!(
            close(stated, computed),
            "`shift-capacity` {what}: composed {stated:?} against the parts less their \
             eliminations {computed:?}"
        );
    }

    // The property that makes it partial, asserted rather than described: the removed figure
    // is strictly smaller than either part's nameplate and strictly greater than zero.
    // `both-views` asserts the far end of the same scale, removed equal to one whole part, and
    // between them the two fixtures show `e` taking a value rather than selecting a case.
    let e = f
        .eliminations
        .content
        .iter()
        .find_map(|x| match x {
            StatedEliminationsTypeContent::Elimination(e)
                if e.against == EliminationAgainstType::Nameplate =>
            {
                Some(e)
            }
            _ => None,
        })
        .expect("a nameplate elimination");
    let removed = eliminated(&e.quantity).expect("sized");
    for part_name in ["team-a", "team-b"] {
        let p = nameplate(layer(stack, part_name));
        assert!(
            removed.1 > 0.0 && removed.1 < p.1,
            "the nameplate elimination is {removed:?}; {part_name} files {p:?}. A partial \
             elimination is strictly between nothing and a whole part"
        );
    }
}
