// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT.
// GitHub renders a directory's README and renders no `//!` block at all, so an argument
// kept only in the source is unreadable from the one place this repository is published.
// `include_str!` makes that same file rustdoc's page, so the two renderings cannot disagree
// and a missing header is a compile error rather than a blank row on the front page.
//
// ⭐⭐ BOTH LANGUAGES ARE INCLUDED, WHICH IS WHAT THE SCHEMAS ALREADY DO. An `xs:annotation`
// holds an `xml:lang="en"` block and an `xml:lang="pt"` block and the generator concatenates
// them into one Rust doc comment; these two files are the same arrangement one directory over.
// A Portuguese page rendered nowhere would be a translation nobody reads, which is the
// second-class citizenship `tests/translation.rs` exists to refuse.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

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
