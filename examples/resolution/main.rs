//! What does a lossy instrument cost, in the units the schema files?
//!
//! The other examples ask whether the arithmetic agrees with itself, whether it may be performed,
//! what the corpus says, and whether the queries compute what they claim. This one asks a question
//! none of them can: **how much of the answer does the recording throw away**, and is what is left
//! still true?
//!
//! ⭐⭐⭐ IT IS ANSWERABLE HERE AND NOWHERE ELSE. In the wild you hold a log and the history that
//! produced it is gone, so the width of what the log fails to pin is a thing to be argued about. In
//! a bench you hold both at once. Running the same history through two instruments and comparing
//! their readings turns that width into a number, once, under conditions somebody can reproduce.
//!
//! ⛔⛔ THE TEST IS CONTAINMENT, NOT AGREEMENT. The lossy reading must **admit** the true one. It
//! must not equal it: an instrument that returned the truth exactly would not have lost anything,
//! and this one demonstrably has. Asserting equality here would be asserting the loss away.
//!
//! ⭐⭐ AND THE TWO LOSSES ARE NOT THE SAME SPECIES, WHICH IS THE FINDING THIS PRINTS. Dropping the
//! magnitude of a refusal widens a bound and keeps the truth inside it, so the field is still
//! filed, as a range, with `pm:Narrowing/kind = instrument`. Losing the ability to tell one unserved
//! holder from another pins their SUM and leaves the split free, which no range can express: it is
//! a face of the holder simplex and it has to be filed as `unmeasured` on both halves.

use std::time::Duration;

// The bench is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which is
// exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/simulation/mod.rs"]
mod simulation;

use simulation::instrument::{Bounded, DeclaredAskSize, Instrument, buffers, census, relabelled};
use simulation::window::{Run, queued_settings, run, short_settings, slack_settings};

/// ⭐ THE BOUND IS A STIPULATION AND IT HAS AN AUTHOR. Nothing in a stock-and-flow log says how
/// big an unrecorded ask was. Somebody has to be willing to say "no order here is smaller than one
/// or larger than six", which in the schema is a `pm:Claim` whose `pm:provenance` carries a
/// name. Withhold it and the field is not a wide range, it is absent.
const DECLARED: DeclaredAskSize = DeclaredAskSize {
    low: 1.0,
    high: 6.0,
};

fn main() {
    let window = Duration::from_secs(6 * 60 * 60);
    let mut failures = 0usize;

    for (name, settings) in [
        ("slack", slack_settings()),
        ("short, turned away", short_settings()),
        ("short, kept waiting", queued_settings()),
    ] {
        for seed in [1u64, 7, 42] {
            let outcome = run(settings.clone(), seed, window).expect("the bench runs");
            failures += report(name, &outcome);
        }
    }

    failures += exhibit_the_fibre();

    println!();
    if failures == 0 {
        println!("Every lossy reading admitted the true one, and the pre-image is not a point.");
    } else {
        println!("{failures} checks failed.");
        std::process::exit(1);
    }
}

/// Two histories, one log.
///
/// ⭐⭐⭐ EVERYTHING ABOVE MEASURES THE LOSS. THIS SHOWS THERE IS NO WAY BACK. Take a run, rewrite
/// every ask that was turned away as one that waited and left, and the other way round. The
/// magnitudes are the same, the times are the same, the holder split is exactly reversed, and the
/// stock-and-flow reading is identical. A map with two things in one pre-image has no inverse, so
/// there is nothing left to argue about: the log names a set of histories and the width of that
/// set is what the rows above priced.
fn exhibit_the_fibre() -> usize {
    let window = Duration::from_secs(6 * 60 * 60);
    let outcome = run(queued_settings(), 1, window).expect("the bench runs");
    let sibling = relabelled(&outcome);

    let seen = Instrument::StockAndFlow.read(&outcome, Some(DECLARED));
    let seen_again = Instrument::StockAndFlow.read(&sibling, Some(DECLARED));
    let truth = Instrument::Whole.read(&outcome, None);
    let other_truth = Instrument::Whole.read(&sibling, None);

    println!();
    println!("── two histories, one log ──────────────────────────────────────────────");
    println!(
        "   held by customer      {}   and   {}",
        truth.customer, other_truth.customer
    );
    println!(
        "   held by unrealised    {}   and   {}",
        truth.unrealised, other_truth.unrealised
    );
    println!(
        "   their sum             {}   and   {}",
        truth.unserved, other_truth.unserved
    );
    println!();

    let mut failed = 0usize;

    let indistinguishable = seen == seen_again;
    println!(
        "   the log reads the same for both        {}",
        yes_no(indistinguishable)
    );
    if !indistinguishable {
        failed += 1;
    }

    // ⛔ The negative control. If the two histories had the same split, the exhibition would be
    // of nothing at all and this example would pass while proving no such thing.
    let genuinely_two = truth.customer != other_truth.customer;
    println!(
        "   the two histories file differently     {}",
        yes_no(genuinely_two)
    );
    if !genuinely_two {
        failed += 1;
    }

    // ⭐ What DID survive, which is the other half of the finding. The sum is pinned by the log
    // even though neither part is, so the loss is a face of the holder simplex and not a hole.
    let sum_survives = truth.unserved == other_truth.unserved;
    println!(
        "   their sum is the same in both          {}",
        yes_no(sum_survives)
    );
    if !sum_survives {
        failed += 1;
    }

    failed
}

fn yes_no(b: bool) -> &'static str {
    if b { "yes" } else { "⛔ no" }
}

fn report(name: &str, outcome: &Run) -> usize {
    let truth = Instrument::Whole.read(outcome, None);
    let bounded = Instrument::StockAndFlow.read(outcome, Some(DECLARED));
    let blind = Instrument::StockAndFlow.read(outcome, None);
    let c = census(outcome);

    println!();
    println!(
        "── {name}, seed {seed}, {hours}h ─────────────────────────────────────────",
        seed = outcome.seed,
        hours = outcome.window.as_secs() / 3600
    );
    println!(
        "   {asked} asks, {served} served, {refused} refused, {reneged} gave up, \
         {produced} lots made and {idled} cycles idle, longest wait {wait}s",
        asked = c.asked,
        served = c.served,
        refused = c.refused,
        reneged = c.reneged,
        produced = c.produced,
        idled = c.idled,
        wait = c.longest_wait.as_secs()
    );
    // ⭐ THE LINE NEVER EXCEEDED ITS RATING, checked rather than assumed. There is no branch in
    //    `layer.rs` that makes a lot early, so if what came off the line ever passed the
    //    nameplate the physics has drifted from the `capacitySlack = notApplicable` filed below.
    let (made, rating) = match (truth.made, truth.nameplate) {
        (Bounded::Range { low: m, .. }, Bounded::Range { low: n, .. }) => (m, n),
        _ => unreachable!("the whole history reports both as points"),
    };
    assert!(
        made <= rating + 1e-9,
        "the line made {made} against a rating of {rating}"
    );

    let b = buffers(outcome, &outcome.settings);
    println!(
        "   buffers: inventory {inv:.0}, capacity {cap}, time {t}s used of {p}s",
        inv = b.inventory_high,
        cap = match b.capacity {
            Some(c) => format!("{c:.0}"),
            // ⭐ NOT ZERO. There is no branch in the line that makes a lot early, so the buffer
            //    is absent rather than empty, which is `pm:absent/reason = notApplicable`.
            None => "notApplicable".to_string(),
        },
        t = b.time_high.as_secs(),
        p = outcome.settings.patience.as_secs()
    );
    println!();
    println!(
        "   {:<12} {:>19}   {:>19}   {:>19}",
        "", "whole history", "log + declared size", "log alone"
    );

    let mut failed = 0usize;
    let rows: Vec<(&str, Bounded, Bounded, Bounded)> = vec![
        ("demand", truth.demand, bounded.demand, blind.demand),
        ("made", truth.made, bounded.made, blind.made),
        (
            "nameplate",
            truth.nameplate,
            bounded.nameplate,
            blind.nameplate,
        ),
        (
            "remainder",
            truth.remainder,
            bounded.remainder,
            blind.remainder,
        ),
        ("served", truth.served, bounded.served, blind.served),
        ("unserved", truth.unserved, bounded.unserved, blind.unserved),
        (
            "unrealised",
            truth.unrealised,
            bounded.unrealised,
            blind.unrealised,
        ),
        ("customer", truth.customer, bounded.customer, blind.customer),
        ("spilled", truth.spilled, bounded.spilled, blind.spilled),
    ];

    for (field, t, b, u) in rows {
        let ok = b.admits(&t) && u.admits(&t);
        if !ok {
            failed += 1;
        }
        println!(
            "   {field:<12} {t}   {b}   {u}  {mark}",
            mark = if ok { "" } else { "  ⛔ DOES NOT ADMIT" }
        );
    }

    // ⭐ The width is the answer to the question. A field whose width is zero survived the
    // projection intact; a field with no width at all did not survive as a number.
    println!();
    for (field, b, t) in [
        ("demand", bounded.demand, truth.demand),
        ("remainder", bounded.remainder, truth.remainder),
        ("unserved", bounded.unserved, truth.unserved),
    ] {
        match (b.width(), t.width()) {
            (Some(w), Some(_)) if w < 1e-9 => {
                println!("   {field:<12} survives the projection exactly")
            }
            (Some(w), _) => println!("   {field:<12} costs a range {w:.2} wide"),
            (None, _) => println!("   {field:<12} does not survive as a number"),
        }
    }
    println!(
        "   {:<12} unmeasured on both halves, with their sum pinned",
        "the split"
    );

    failed
}
