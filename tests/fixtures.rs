//! ⛔⛔⛔ THE STIPULATIONS, AND THE NEGATIVE CONTROLS. See `assets/fixtures/README.md` for why
//! these documents are not in `assets/corpus/` and may never be cited as evidence about a
//! business.
//!
//! ⭐⭐ TWO DIFFERENT KINDS OF PROOF LIVE HERE AND THEY ARE NOT INTERCHANGEABLE.
//!
//!   a fixture       proves a STATE IS REACHABLE — it validates, round-trips, and a rule
//!                   handles it. It cannot prove the rule would catch anything
//!   a negative      proves the CHECKER BITES — the same rule, run against a document
//!   control         mutated in memory to be wrong, must reject it
//!
//! ⚠️ A repository with only the first kind reports green for rules that examine nothing,
//! which is the trap this codebase names as *"a bound with nothing to bound passes loudest."*
//! A repository with only the second never learns that a state exists.
//!
//! ⭐ THE MUTATION IS IN MEMORY AND THE FILES ON DISK ARE NEVER TOUCHED. The generated types
//! derive `Clone`, so a parsed fusion can be copied, broken, and fed back to the same function
//! the passing test uses. That replaces a perturbation procedure that lived in a findings file
//! and a person's memory with one that runs on every build.
//!
//! ⚠️ MOST OF WHAT IS BROKEN HERE IS A COMPOSITION, because the sum rule is the one rule in
//! the model with an exact arithmetic to violate. `tests/composition.rs` is the positive half
//! and reads the corpus; this file stipulates the states that corpus has no business filing.

use std::fs;

use process_modulus::asrt::{
    CompositionType, EliminationAgainstType, FusionType, StatedEliminationsTypeContent,
};
use process_modulus::pm;
use process_modulus::pm::{
    AbsenceReasonType, AbsenceType, LayerType, ProcessModulusElementType, StatedClaimType,
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

/// The URN a filing gives for itself — the S-28 repair, and the whole of local composition.
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

fn triple(s: &StatedClaimType) -> Option<Triple> {
    match s {
        StatedClaimType::Claim(c) => Some((c.low, c.most_likely, c.high)),
        StatedClaimType::Absent(_) => None,
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

/// ⭐⭐⭐ WHAT A FUSION'S PARTS SUM TO, OR `None` WHERE NO SUM IS OWED.
///
/// This is `tests/composition.rs`'s `expected` reduced to the fixture's shape, and the branch that
/// matters is the FIRST one. A composer who never looked for double counting owes no equation
/// at all, so the honest answer is neither a pass nor a failure but UNCHECKED — a third
/// outcome, and one an empty `elimination` list could not produce because it was
/// byte-identical to a clean search.
///
/// ⛔⛔ `against` IS NOT DECORATION, AND WITHOUT IT THIS FUNCTION IS WRONG IN A WAY NO FIXTURE
/// SEES UNTIL ONE FILES AN ELIMINATION. Subtract EVERY elimination from whichever quantity is
/// being computed and a corpus filing none agrees exactly; the first one that files one gives a
/// demand of `-360`. `EliminationAgainst`'s own annotation says why: *"an elimination that does
/// not say which one it hits is an adjustment applied to whichever number the reader happened
/// to be holding."* The reader here was this function.
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
    for e in &f.eliminations.content {
        if let StatedEliminationsTypeContent::Elimination(e) = e {
            if e.against != against {
                continue;
            }
            match &e.quantity {
                StatedClaimType::Claim(q) => {
                    total = (total.0 - q.low, total.1 - q.most_likely, total.2 - q.high)
                }
                // A zero elimination is `[0, 0, 0]` and lands in the arm above. There is no
                // `none` spelling for it: `ClaimAbsenceReason` does not carry one.
                StatedClaimType::Absent(_) => return None,
            }
        }
    }
    Some(total)
}

/// ⭐⭐⭐ THE TWO STATES `assets/corpus/` CANNOT REACH, AND THEY OWE DIFFERENT ARITHMETIC.
///
/// All three of the corpus's empty fusions are ONE-PART fusions filing `notApplicable`, so
/// until this fixture existed the two branches that actually decide the sum rule had never
/// run. `Elimination`'s annotation argues that filed eliminations make the rule EXACT rather
/// than a warning — true for a fusion that files one, and quietly untested for the two ways of
/// filing none.
#[test]
fn a_checked_search_owes_an_exact_sum_and_an_unchecked_one_owes_nothing() {
    let (m, c) = (members(), composition());

    // `baking`: somebody looked and found no double counting, so the composed figure IS the
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
            "`baking` {what}: composed {stated:?} against Σ parts {computed:?}. With the search \
             filed as `none` there is nothing to remove, so these must agree exactly"
        );
    }

    // ⛔⛔ `mixing`: nobody looked, and the filed figure DELIBERATELY does not reconcile.
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

    // ⭐ AND THE DISCREPANCY IS REAL, WHICH IS WHAT MAKES THE SUSPENSION WORTH SOMETHING. If
    // the fixture happened to reconcile, `unmeasured` and `none` would be indistinguishable in
    // their consequences and this test would pass while proving nothing.
    let parts: Triple = mixing.part.iter().fold((0.0, 0.0, 0.0), |a, p| {
        let l = demand(layer(&m, &p.layer.filing.id));
        (a.0 + l.0, a.1 + l.1, a.2 + l.2)
    });
    let stated = demand(layer(&c.process_modulus, "mixing"));
    assert!(
        !close(stated, parts),
        "`mixing` reconciles at {stated:?}, so the suspended branch has nothing to suspend. \
         The fixture must file a figure that DIFFERS from Σ parts {parts:?}, or a checker that \
         ignored the search entirely would pass this test"
    );
}

/// ⛔⛔⛔ THE NEGATIVE CONTROL. Everything above is a rule reporting that a document is fine.
/// This is the same rule, on the same code path, reporting that a broken one is not — and the
/// document is broken IN MEMORY, so nothing on disk changes and nothing has to be restored.
///
/// ⭐⭐ IT REPLACES A RITUAL. Until now "proved able to fail" meant somebody copied a corpus
/// file to a scratchpad, edited it, ran the suite, read the failure and copied the file back.
/// That is a real proof and it runs exactly once, in one person's terminal, and leaves behind
/// a sentence in a findings file. This runs on every build.
#[test]
fn the_sum_rule_rejects_a_fusion_that_does_not_reconcile() {
    let (m, c) = (members(), composition());
    let baking = fusion(&c, "baking");

    // The control: unbroken, it agrees.
    let good = expected(&m, baking, EliminationAgainstType::Demand, demand)
        .expect("a checked search owes a sum");
    assert!(close(good, demand(layer(&c.process_modulus, "baking"))));

    // ⛔ Break ONE part's demand by 100 and the sum must move by exactly 100 at every bound.
    let mut broken = m.clone();
    let l = broken
        .stack
        .layer
        .iter_mut()
        .find(|l| l.name == "oven")
        .expect("oven");
    if let StatedClaimType::Claim(d) = &mut l.demand.amount {
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

/// ⛔⛔ THE SECOND NEGATIVE CONTROL, AND IT IS THE ONE THE WHOLE CLEANUP TURNS ON. Swap a
/// fusion's SEARCH RESULT and nothing else — same parts, same figures, same prose — and the
/// arithmetic a checker owes changes.
///
/// ⭐⭐⭐ THAT IS THE PROOF THE WRAPPER WAS LOAD-BEARING RATHER THAN VOCABULARY. Under the old
/// `minOccurs="0" maxOccurs="unbounded"` these two documents were BYTE-IDENTICAL, so no test
/// like this could be written: there was one document and one verdict. Now there are two of
/// each, and this test fails if a future refactor collapses them back.
#[test]
fn the_same_figures_owe_different_arithmetic_under_a_different_search() {
    let (m, c) = (members(), composition());
    let mixing = fusion(&c, "mixing").clone();

    // As filed: nobody looked, so no equality is owed.
    assert_eq!(
        expected(&m, &mixing, EliminationAgainstType::Demand, demand),
        None
    );

    // ⛔ Change ONLY the search result to `none` — the composer now claims they looked and
    // found nothing — and the very same figures become a violation.
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
         consequences here and the fixture proves nothing"
    );

    // ⭐ And the size of the violation is the size of the double counting nobody measured.
    assert!(
        (owed.1 - stated.1 - 400.0).abs() < 1e-9,
        "expected the unstated netting to be 400 doughs at the mode, found {}",
        owed.1 - stated.1
    );
}

/// ⭐ The fixtures are stipulations and must say so TWICE: in a comment, where a reader who
/// opens one file without reading the directory's README will meet it, and in `pm:evidence`,
/// where a RECEIVER will. Until 0.4 only the comment existed, and `assets/sql/ingest.sql`
/// matched it as a substring over the whole document, so a corpus file that merely quoted the
/// sentence became a stipulation, and a Portuguese fixture had to announce itself in English.
///
/// ⛔⛔ `every-draft.xml` IS THE ONE EXCEPTION AND IT IS THE ENTIRE POINT OF THAT FILE. It
/// files `absent reason="unmeasured"` deliberately, because the state a first-time adopter's
/// document is really in is "nobody has said", and `tests/state_coverage.rs` can only call
/// that state Exercised if some document is in it. The comment still announces the file, so a
/// human is never misled; the element declines to, so a machine is never made to guess.
#[test]
fn every_fixture_declares_that_it_is_a_stipulation() {
    for name in [
        "every-absence.xml",
        "every-elimination.xml",
        "every-claimed.xml",
        "every-local-part.xml",
        "every-partial-elimination.xml",
        "every-draft.xml",
    ] {
        let body = read(&format!("fixtures/{name}"));
        assert!(
            body.contains("A STIPULATION, NOT A FILING"),
            "{name}: a fixture that does not announce itself will eventually be quoted as \
             evidence, which is the one thing this directory must not allow"
        );

        if name == "every-draft.xml" {
            assert!(
                !body.contains("<pm:attests>"),
                "{name}: this file exists to be the document that DECLINES to say. Filing a \
                 value here leaves StatedEvidence/unmeasured with nothing exercising it"
            );
        } else {
            assert!(
                body.contains("<pm:attests>stipulation</pm:attests>"),
                "{name}: the comment announces it to a reader and nothing announces it to a \
                 receiver. That is the gap `pm:evidence` was added to close"
            );
        }
    }
}

/// ⭐⭐⭐ THE CONSTRUCTION A THIRD PARTY PERFORMS: theirs, mine, and one made out of both —
/// with all three still separable afterwards.
///
/// ⛔⛔ ONE THING HAD TO CHANGE TO ALLOW IT AND IT WAS NOT A NEW RELATION. `Part/layer`
/// addresses a layer as `{notation, id}` where the notation is a FILING's URN, and without
/// S-28 no document can say which filing it is. A part whose notation matches its
/// own composition's is a LOCAL part — there is no second kind of part, no new element, and
/// the distinction is a string comparison against the filing's own name.
///
/// ⚠️ I proposed a new relation peer to `Fusion` for this, and two more refusals that were not
/// refusals. The whole of it was one missing self-identifier.
#[test]
fn a_composer_builds_a_layer_out_of_two_layers_they_built() {
    let c = local();
    let me = notation(&c.process_modulus).expect("this fixture names itself");

    let kind = |name: &str| -> Vec<bool> {
        c.fusion
            .iter()
            .find(|f| f.name == name)
            .unwrap_or_else(|| panic!("no fusion `{name}`"))
            .part
            .iter()
            .map(|p| p.layer.filing.notation == me)
            .collect()
    };

    // theirs: one part, and it is NOT this document's
    assert_eq!(kind("as-filed"), vec![false]);
    // both: two parts, and both ARE
    assert_eq!(kind("both-views"), vec![true, true]);

    // mine: originated, so it has no fusion at all — the schema's documented third state,
    // and NOT a marker for "proposed". It is real in this document's context, asserted by
    // this witness; a flag saying otherwise would be a document arguing with its signature.
    assert!(
        !c.fusion.iter().any(|f| f.name == "as-contracted"),
        "`as-contracted` is originated; a fusion for it would make it a restatement"
    );

    // ⭐ AND ALL THREE ARE STILL THERE. The operation is non-destructive, which is what
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

/// ⭐⭐⭐ AND THE ALTERNATION IS AN ORDINARY FUSION WITH AN ELIMINATION.
///
/// Two views of one quantity summed is that quantity **counted twice**, which is exactly what
/// `Elimination` removes — `EliminationAgainst/demand` is literally *"what was ASKED, counted
/// twice."* So the sum rule a checker owes here is the same one it owes everywhere, unrelaxed.
///
/// ⛔ THAT IS THE TEST OF WHETHER THE COMPOSITION ANSWER WAS RIGHT. If holding two readings of
/// one number had needed the rule suspended or special-cased, it would have been a new
/// relation wearing a fusion's clothes. It does not.
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
            "`both-views` {what}: composed {stated:?} against Σ parts less eliminations \
             {computed:?}"
        );

        // ⭐ The elimination is ONE WHOLE COPY, at every bound — not a point. `Elimination`
        // subtracts component-wise because it removes "a COMPONENT OF THE VERY FIGURE IT IS
        // REMOVED FROM", and for two views of one quantity that is exact: the removed copy IS
        // the figure, so it moves with it. Getting this wrong was the first mistake the
        // fixture caught, in the hand that wrote it.
        let e = both
            .eliminations
            .content
            .iter()
            .find_map(|x| match x {
                StatedEliminationsTypeContent::Elimination(e) if e.against == against => Some(e),
                _ => None,
            })
            .unwrap_or_else(|| panic!("no {what} elimination"));
        let removed = triple(&e.quantity).expect("sized");
        assert!(
            close(removed, of(layer(stack, "as-filed"))),
            "the {what} elimination is {removed:?} and one whole view is {:?}. Removing less \
             than a copy leaves the quantity partly doubled; removing more deletes real figures",
            of(layer(stack, "as-filed"))
        );
    }

    // ⛔ AND WITHOUT THE ELIMINATION IT IS WRONG BY EXACTLY ONE COPY — the negative control
    // for the claim that no new relation was needed.
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

/// ⭐ A filing that cannot name itself cannot be composed, and that is the honest consequence
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

/// ⭐⭐⭐ A NAMEPLATE ELIMINATION IS A MAGNITUDE, NOT A SELECTOR, AND THIS IS THE FIXTURE THAT
/// SAYS SO. Every other sized nameplate elimination in this repository removes a WHOLE part —
/// `merge-group-composition`'s `shift-line`, and `every-local-part`'s `both-views`, which
/// asserts the whole-copy property directly. Two data points at one end of a scale read like a
/// category, and the category they suggest is that a nameplate elimination discriminates a KIND
/// of fusion.
///
/// ⛔ It does not. `e` is how much supply the parts counted in common: none, some, or all of a
/// part. This fixture files SOME — 3 of a 10 — and the sum rule is the same rule, unmodified.
/// The parts are fungible here exactly as they are at both ends, and `observed` says so in the
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
            "`shift-capacity` {what}: composed {stated:?} against Σ parts less eliminations \
             {computed:?}"
        );
    }

    // ⭐⭐ THE PROPERTY THAT MAKES IT PARTIAL, ASSERTED RATHER THAN DESCRIBED: the removed
    // figure is strictly smaller than either part's nameplate and strictly greater than zero.
    // `both-views` asserts the opposite end of the same scale — removed == one whole part — and
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
    let removed = triple(&e.quantity).expect("sized");
    for part_name in ["team-a", "team-b"] {
        let p = nameplate(layer(stack, part_name));
        assert!(
            removed.1 > 0.0 && removed.1 < p.1,
            "the nameplate elimination is {removed:?}; {part_name} files {p:?}. A partial \
             elimination is strictly between nothing and a whole part, and it is the state \
             nothing else in this repository files"
        );
    }
}
