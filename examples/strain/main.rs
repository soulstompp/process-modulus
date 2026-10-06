// This program's header is `README.md` beside it, and there is one copy of it. GitHub renders a
// directory's README and no `//!` block, so a header kept only in the source cannot be read where
// the repository is published. `include_str!` makes the same file rustdoc's page, so the two
// renderings cannot disagree, and a missing header is a compile error rather than a blank row.
//
// Both languages are included, as in the schemas: an `xs:annotation` holds an `xml:lang="en"`
// block and an `xml:lang="pt"` block, and the generated Rust carries both in one doc comment.
// These two files are the same arrangement for a program, so the Portuguese page is rendered
// wherever the English one is, as `tests/translation.rs` requires.
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/strain/README.md")]

use std::time::Duration;

// The bench is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which is
// exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/simulation/mod.rs"]
mod simulation;

use simulation::event::{Event, Record};
use simulation::instrument::Instrument;
use simulation::quantum::{Fillable, gcd};
use simulation::layer::Settings;
use simulation::window::{Run, batch_settings, lotted_settings, run, tight_settings};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    two_quanta()?;
    reversed_quantization()?;
    windows_do_not_compose()?;
    the_window_that_is_not_whole_cycles()?;
    both_sides_of_one_transaction()?;
    a_field_that_never_heard_of_this()?;
    Ok(())
}

// =============================================================================================
// Probe 6. The five holders against a field that measures them under other names.
// =============================================================================================

/// The strongest test of a general model is a domain it was not built for, measured by people who
/// never heard of it. An emergency department is a supply in whole units meeting continuous
/// demand: physician hours come in whole shifts, patients arrive when they arrive. Each of the five
/// `pm:HolderKind`s is a metric that field already collects, under its own name and for its own
/// reasons.
///
/// | `pm:HolderKind` | what the ED calls it                                    |
/// |---|---|
/// | `customer`      | LWBS, left without being seen. Waited, degraded, left    |
/// | `unrealised`    | patients who did not present at all                      |
/// | `counterparty`  | ambulance diversion. Literally another hospital's books   |
/// | `people`        | staff working past the end of a shift                    |
/// | `booked`        | the overtime that was paid for                           |
///
/// `customer` is the schema's own definition: demand that was there and got a worse service. LWBS
/// is the CMS quality indicator for exactly that, with a 2% national benchmark, and it is reported
/// because a hospital is penalised for it: a field measuring the model's least commercial holder
/// because a regulator makes it.
///
/// The part that can be checked is the curve, not the vocabulary. The literature reports that LWBS
/// climbs past 2% as daily registrations reach the 70th percentile, and rises exponentially at
/// each decile after. If this bench's physics is right, it should reproduce that shape without
/// being told, because it is the same shortfall in the same three buffers.
fn a_field_that_never_heard_of_this() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 6. the five holders, in a field that measures them anyway ════════════\n");

    let window = Duration::from_secs(6 * 60 * 60);

    // Two shops, one sweep of the load, and the only difference is whether output keeps. Running
    // only the second would show a curve and say nothing about why it has that shape.
    for (name, base) in [
        ("a line that can hold finished stock", simulation::window::queued_settings()),
        ("a service, where output perishes", simulation::window::perishable_settings()),
    ] {
        let rating = base.lot / base.cycle.as_secs_f64();
        println!("   ── {name} ──");
        println!(
            "   {:<8} {:>8} {:>12} {:>12} {:>12}",
            "load", "asks", "LWBS", "unserved", "longest wait"
        );

        let mut curve = Vec::new();
        for gap in [52u64, 42, 35, 30, 26, 23, 21, 19] {
            let settings = Settings {
                mean_gap: Duration::from_secs(gap),
                ..base.clone()
            };
            let mean_size = (settings.size_low + settings.size_high) / 2.0;
            let load = (mean_size / gap as f64) / rating;

            let outcome = run(settings, 11, window)?;
            let reading = Instrument::Whole.read(&outcome, None);
            let c = simulation::instrument::census(&outcome);

            let demand = point_of(reading.demand);
            let lwbs = 100.0 * point_of(reading.customer) / demand;
            let unserved = 100.0 * point_of(reading.unserved) / demand;
            curve.push((load, lwbs));
            println!(
                "   {load:<8.2} {:>8} {lwbs:>11.2}% {unserved:>11.2}% {:>11}s",
                c.asked,
                c.longest_wait.as_secs()
            );
        }

        let first_loss = curve.iter().find(|(_, r)| *r > 1e-9).map(|(l, _)| *l);
        let crosses = curve.iter().find(|(_, r)| *r >= 2.0).map(|(l, _)| *l);
        match (first_loss, crosses) {
            (Some(a), Some(b)) => println!(
                "   the first patient is lost at {a:.2} of the rating and 2% is passed by {b:.2}"
            ),
            _ => println!("   nobody is lost at any load below 1.1 of the rating"),
        }

        // The literature's claim is "exponentially at each subsequent decile", a claim about
        // ratios, and it is checked as one. A curve that merely rises would satisfy a reader and
        // not the sentence.
        //
        // Capped at full load, because the reported curve is about shops inside their capacity.
        // Past the rating everything saturates: the queue is always full, the rate flattens, and
        // including those points would flatter the fit at the top and spoil it at the ratios.
        let past: Vec<f64> = curve
            .iter()
            .filter(|(l, r)| *l >= 0.7 && *l <= 1.005 && *r > 1e-9)
            .map(|(_, r)| *r)
            .collect();
        if past.len() >= 3 {
            let ratios: Vec<String> = past
                .windows(2)
                .map(|w| format!("{:.1}x", w[1] / w[0]))
                .collect();
            println!(
                "   decile on decile from the knee: {}   {}",
                ratios.join(", "),
                agree(past.windows(2).all(|w| w[1] / w[0] > 1.4))
            );
            println!(
                "   the range this bench spans: {:.1}% to {:.1}%, against 1.2% to 16.6% reported",
                past.first().copied().unwrap_or(0.0),
                past.last().copied().unwrap_or(0.0)
            );
        }
        println!();
    }

    println!("   The field reports LWBS climbing past 2% as registrations reach the 70th");
    println!("     percentile, and rising exponentially at each decile after, over a reported");
    println!("     range of 1.2% to 16.6%. Read the perishable shop's figures above against");
    println!("     that: where it loses its first patient, where it passes 2%, and the range it");
    println!("     spans. It was built for a manufacturing line and told nothing about hospitals.");
    println!("     Only one of the two shops shows that curve, and that is the point.");
    println!("     A line that can hold finished stock has no knee at all below");
    println!("     full load: the inventory buffer absorbs every fluctuation and nobody waits.");
    println!("     Take that buffer away and the same arrivals against the same rating start");
    println!("     losing people well before the rating is reached.");
    println!("     That is one buffer standing in for another, backwards. Factory Physics says");
    println!("       variability must be absorbed by inventory, capacity or time. Delete one of");
    println!("       the three and the other two carry all of it, and the one carrying it here is");
    println!("       time, which is measured in people who left.");

    println!("\n   What that is and is not evidence of. It is not evidence the schema is");
    println!("     right: a queue blowing up near capacity is textbook and any honest simulator");
    println!("     would show it. It is evidence that the quantity the model calls a remainder,");
    println!("     and the holder it calls `customer`, are the quantity and the party a completely");
    println!("     separate field decided to measure and regulate. The model did not have to be");
    println!("     bent to say it, and no field had to be added.");

    println!("\n   The one place it does bend. Ambulance diversion is `counterparty`: the burden");
    println!("     moves to a named other hospital on a named date, which is exactly what");
    println!("     `Holder/party` and `Holder/asOf` are for and the only holder that requires");
    println!("     them. But a diverted patient is also that hospital's `customer` a moment later,");
    println!("     and probe 5 has already shown there is no law relating one filing's");
    println!("     `counterparty` share to another filing's anything. The element promises a");
    println!("     relation the schema cannot check.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 5. The same transaction, filed by both parties.
// =============================================================================================

/// The assumption: a remainder is a fact about an encounter, so the two parties to it talk about
/// the same quantity. `pm:HolderKind` has `counterparty` to say *"whose other books the burden sits
/// in"*, which only means something if the burden is one thing seen from two sides.
///
/// It is not. The remainder is built from the supplier's nameplate, and the customer has no
/// access to that number and no reason to record it. What the customer files as their supply is
/// what arrived, which is the supplier's draw. Two different nameplates, two different
/// remainders, one transaction.
fn both_sides_of_one_transaction() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 5. one transaction, filed from both sides ════════════════════════════\n");

    let window = Duration::from_secs(6 * 60 * 60);
    println!(
        "   {:<14} {:>26} {:>26}",
        "", "the line files", "the buyer files"
    );

    for (name, settings) in [
        ("slack", simulation::window::slack_settings()),
        ("short", simulation::window::short_settings()),
    ] {
        let outcome = run(settings, 1, window)?;
        let seller = Instrument::Whole.read(&outcome, None);

        // The buyer's nameplate is what arrived. They cannot see the line's rating; they see
        // deliveries. So their supply is the seller's draw, and their demand is their own ask.
        let buyer_nameplate = point_of(seller.served);
        let buyer_demand = point_of(seller.demand);
        let buyer_remainder = buyer_nameplate - buyer_demand;
        let buyer_fit = if buyer_nameplate >= buyer_demand {
            "clearance"
        } else {
            "interference"
        };

        println!("\n   ── {name} ──");
        println!(
            "   {:<14} {:>26.1} {:>26.1}",
            "nameplate",
            point_of(seller.nameplate),
            buyer_nameplate
        );
        println!(
            "   {:<14} {:>26.1} {:>26.1}",
            "demand",
            point_of(seller.demand),
            buyer_demand
        );
        println!(
            "   {:<14} {:>26.1} {:>26.1}",
            "remainder",
            point_of(seller.remainder),
            buyer_remainder
        );
        println!(
            "   {:<14} {:>26} {:>26}",
            "fit",
            fit_of(&seller),
            buyer_fit
        );
        let gap = (point_of(seller.remainder) - buyer_remainder).abs();
        println!(
            "   {:<14} {:>54.1}",
            "they differ by", gap
        );
    }

    println!("\n   The two parties agree almost exactly when somebody is being hurt, and not");
    println!("     at all when nobody is. On the short layer the binding constraint is shared, so");
    println!("     both sides measure the same shortfall and their remainders coincide to within");
    println!("     the supply that was made and not delivered. On the slack layer the line's");
    println!("     remainder is its own idle rating, as the table shows, and the buyer's is");
    println!("     zero, because everything they asked for arrived. Nothing was lost and nobody");
    println!("     is wrong.");

    println!("\n   So a remainder is a fact about one party's nameplate, not about the");
    println!("     transaction, and `counterparty` promises more than that. Its annotation says");
    println!("     it names whose other books a burden sits in. On the slack layer the line's");
    println!("     `booked` share of idle capacity sits in nobody else's books: it has no");
    println!("     counterpart anywhere, because the buyer never had a claim on that capacity.");

    println!("\n   That is an argument for the model rather than against it, which is why");
    println!("     it is worth filing. `a filing is never the system` is the repository's");
    println!("     position. This is that position with a number on it: two sound filings of one");
    println!("     transaction differ by the whole of one party's idle capacity, and the size of");
    println!("     the disagreement measures how much of the encounter was never contested.");
    println!("     What is missing is any element that lets the pair be compared. The schema");
    println!("       composes across parties for demand, through `part` and the fusion machinery,");
    println!("       and there is no such law for a remainder or for a holder.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 4. A window that is not a whole number of cycles.
// =============================================================================================

/// The assumption: the nameplate is a whole multiple of the quantum. `nameplate_not_a_multiple`
/// enforces it, and its argument is *"supply arrives in whole units, so the nameplate is a whole
/// multiple of the quantum. Half a truck and half a licence do not exist."*
///
/// That is right for a stock and wrong for a rate, and the schema says this is a rate.
/// `Claim/denominator` exists so a nameplate has a period, and `LumpyQuantum`'s own annotation says
/// the quantum's unit is the nameplate's, a rate where the nameplate is one. A line making one lot
/// per cycle delivers as many lots as the window holds cycles, and a window is a whole number of
/// cycles only by coincidence. Eight hours at fifty minutes is 9.6.
///
/// So a filer has two moves, and both are wrong. File 9.6 lots, and the rule fires. File 9, and
/// the rule passes on a nameplate that understates the line by 6%, which is not noise: it comes
/// off the supply side of the remainder, so it inflates every interference remainder and
/// over-attributes to `customer` and `unrealised`. A shop obeying the schema over-reports the
/// customers it lost, and the error grows as the lot grows against the window, which is the
/// lumpy case this model exists for.
fn the_window_that_is_not_whole_cycles() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 4. a window that is not a whole number of cycles ═════════════════════\n");

    let window = Duration::from_secs(8 * 60 * 60);
    let base = batch_settings();
    let cycles = window.as_secs_f64() / base.cycle.as_secs_f64();
    println!(
        "   a lot of {lot} every {mins} minutes over {hours} hours is {cycles} cycles",
        lot = base.lot,
        mins = base.cycle.as_secs() / 60,
        hours = window.as_secs() / 3600
    );

    // One history, two nameplates. The physics is identical; only what the filer may write down
    // differs, which isolates the schema's part in the answer.
    let honest = Settings {
        floor_nameplate: false,
        ..base.clone()
    };
    let outcome = run(base.clone(), 4, window)?;
    let legal = Instrument::Whole.read(&outcome, None);
    let truthful = Instrument::Whole.read(
        &Run {
            settings: honest,
            ..clone_run(&outcome)
        },
        None,
    );

    println!(
        "\n   {:<22} {:>12} {:>12}",
        "", "filed (9 lots)", "true (9.6 lots)"
    );
    for (name, a, b) in [
        ("nameplate", point_of(legal.nameplate), point_of(truthful.nameplate)),
        ("demand", point_of(legal.demand), point_of(truthful.demand)),
        ("remainder", point_of(legal.remainder), point_of(truthful.remainder)),
    ] {
        println!("   {name:<22} {a:>12.1} {b:>12.1}");
    }
    println!("   {:<22} {:>12} {:>12}", "fit", fit_of(&legal), fit_of(&truthful));

    let understated = point_of(truthful.nameplate) - point_of(legal.nameplate);
    println!(
        "\n   the rule costs {understated:.0} units of nameplate, {:.1}% of the line",
        100.0 * understated / point_of(truthful.nameplate)
    );

    println!(
        "\n   The remainder goes from {:.1} to {:.1}, a far larger error than the nameplate's.",
        point_of(truthful.remainder),
        point_of(legal.remainder)
    );
    println!("     The true layer is very nearly balanced, and the legal filing says that the");
    println!("     difference went unserved. Taking the bias off the supply side of the remainder");
    println!("     moves the whole of it into the remainder, where a nearly zero quantity has no");
    println!("     room to absorb it.");

    // The sign flips over a band, not at a point, and sweeping the load shows that. Tuning one
    // seed until the fit flipped would be choosing the example that makes the point.
    println!("\n   sweeping the load: where the two filings disagree about the sign");
    println!(
        "     {:<10} {:>10} {:>14} {:>14}",
        "mean gap", "demand", "filed", "true"
    );
    let mut flips = 0;
    let mut total = 0;
    for gap in [17u64, 19, 21, 22, 23, 24, 26, 30] {
        let settings = Settings {
            mean_gap: Duration::from_secs(gap),
            ..batch_settings()
        };
        let piece = run(settings.clone(), 4, window)?;
        let filed = Instrument::Whole.read(&piece, None);
        let real = Instrument::Whole.read(
            &Run {
                settings: Settings {
                    floor_nameplate: false,
                    ..settings
                },
                ..clone_run(&piece)
            },
            None,
        );
        total += 1;
        let disagree = fit_of(&filed) != fit_of(&real);
        if disagree {
            flips += 1;
        }
        println!(
            "     {gap:<10} {:>10.0} {:>14} {:>14}  {}",
            point_of(filed.demand),
            fit_of(&filed),
            fit_of(&real),
            if disagree { "opposite signs" } else { "" }
        );
    }
    println!(
        "\n     {flips} of {total} loads file the opposite sign from the truth. Where they do,"
    );
    println!("     `clearance_with_unserved` obliges the legal filing to name a `customer` or an");
    println!("     `unrealised` holder for demand nobody ever turned away, and forbids the true");
    println!("     filing from naming anyone. The rounding the schema requires invents a lost");
    println!("     customer, and there is no rule anywhere that could catch it.");

    // ------------------------------------------------------------------------------------
    // How far the bias goes, which is the part that decides whether it matters.
    // ------------------------------------------------------------------------------------
    println!("\n   how big the forced error gets, by how lumpy the layer is");
    println!(
        "     {:<26} {:>10} {:>10} {:>12}",
        "window against one lot", "true lots", "filable", "understated"
    );
    for (label, cycles) in [
        ("a shift, 50 minute lot", 9.6_f64),
        ("a week, 3 day batch", 7.0 / 3.0),
        ("a month, 3 week batch", 4.33),
        ("a quarter, 2 month run", 1.5),
    ] {
        let filable = cycles.floor();
        println!(
            "     {label:<26} {cycles:>10.2} {filable:>10.0} {:>11.1}%",
            100.0 * (cycles - filable) / cycles
        );
    }
    println!(
        "\n   The error grows as the lot grows against the window, so the rule is least safe"
    );
    println!("     exactly where the model says its subject is. A quarterly filing of a two month");
    println!("     production run loses a third of its own nameplate to a rounding the schema");
    println!("     requires, and every unit of that lands in the remainder.");

    println!("\n   And what the fraction is made of has no element at all. The 0.6 of a");
    println!("     lot at the boundary is work in progress: started, not finished, carried into");
    println!("     the next window. `inventorySlack` is finished output held ahead, in its own");
    println!("     words. A half built lot is not output.");
    println!(
        "     The schema mentions work in progress, Little's Law and cycle time not once,"
    );
    println!("       while adopting Factory Physics' three buffers by name. WIP is that");
    println!("       book's central state variable, and leaving it out is a position rather than");
    println!("       an oversight, but it is not a stated one.");
    println!();
    Ok(())
}

fn clone_run(r: &Run) -> Run {
    Run {
        settings: r.settings.clone(),
        seed: r.seed,
        window: r.window,
        history: r.history.clone(),
    }
}

// =============================================================================================
// Probe 1. A supply with two lot sizes.
// =============================================================================================

/// The assumption: one layer has one quantum. `pm:Divisibility` carries a single
/// `pm:LumpyQuantum`, and `pm:Remainder`'s annotation builds on it: with one lot size, the residue
/// is fixed by the demand and that size, every time.
///
/// The wider case is ordinary and everywhere. A shop ships in cases of five and pallets of twelve.
/// A team is staffed in half shifts and whole shifts. A cloud bill is quoted per instance hour on
/// two instance sizes. None of that is exotic, and all of it is one supply with two lot sizes.
///
/// A composed quantum exists: the largest unit both lot sizes are whole numbers of, where both are
/// in one unit. `composition/composed_quantum.sqlc` is where the model computes it. Not every whole
/// number of that unit can be made, because lots come whole: with lots of 3 and 5 the composed
/// unit is 1, while 1, 2, 4 and 7 cannot be made at all. The model uses only the first fact, and
/// the sieve below shows the second rather than asserting it. The composed quantum also needs the
/// two lot sizes in one unit, a live condition because they are real numbers.
///
/// Within a single layer, asking for a best quantum is the wrong question: there the quantum is
/// observed, and choosing the largest unit that divides the nameplate would infer the physics from
/// the number.
///
/// So an elimination must itself be a whole number of composed quanta: you cannot eliminate half a
/// machine. `arithmetic/whole_multiple.sqlc` is the site, and `every-local-part/both-views`
/// eliminates 2160 against a quantum of 12, which is 180 whole ovens.
///
/// Across units there is no composed quantum at all. It is a same-unit notion:
/// `merge-holding-composition/compute` fuses `720 GPU-hour` with `8 GPU`, and no number divides
/// both. That is not awkward data; it is the same wall a conversion factor crosses, and a
/// conversion factor multiplies a quantum too. A composed unit of 1 is the other extreme, where the
/// lumps dissolve and the composed supply is effectively continuous.
fn two_quanta() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 1. a supply with two lot sizes ═══════════════════════════════════════\n");

    let lots = vec![5u64, 12u64];
    let fill = Fillable::new(lots.clone(), 200);

    // Both numbers are computed twice, not quoted. `sylvester` gives them for two lot sizes with
    // no common factor, and the sieve in `Fillable::new` finds them independently, so neither
    // rests on a single source.
    let gaps = fill.gaps();
    let (f_formula, g_formula) = fill.sylvester().expect("two lot sizes with no common factor");
    let f_sieved = fill.frobenius().expect("an ask the lots cannot fill");
    println!(
        "   lots of {a} and {b}, whose largest common unit is {g}",
        a = lots[0],
        b = lots[1],
        g = gcd(lots[0], lots[1])
    );
    println!(
        "   largest ask no combination of lots can fill exactly   sieve {f_sieved}, \
         formula {f_formula}   {}",
        agree(f_sieved == f_formula)
    );
    println!(
        "   how many asks below it cannot be filled exactly       sieve {}, formula \
         {g_formula}   {}",
        gaps.len(),
        agree(gaps.len() as u64 == g_formula)
    );
    println!("   the unfillable asks: {gaps:?}");

    // ------------------------------------------------------------------------------------
    // What a real run of asks does against that supply.
    // ------------------------------------------------------------------------------------
    let outcome = run(lotted_settings(), 3, Duration::from_secs(6 * 60 * 60))?;
    let asks: Vec<u64> = outcome
        .history
        .iter()
        .filter_map(|Record { what, .. }| match what {
            Event::Asked { size, .. } => Some(*size as u64),
            _ => None,
        })
        .collect();

    let mut short_of_frobenius = (0u64, 0u64);
    let mut past_frobenius = (0u64, 0u64);
    let mut overshoot_total = 0u64;
    for ask in &asks {
        let over = fill.overshoot(*ask);
        overshoot_total += over;
        let bucket = if *ask <= f_sieved {
            &mut short_of_frobenius
        } else {
            &mut past_frobenius
        };
        bucket.0 += 1;
        if over > 0 {
            bucket.1 += 1;
        }
    }

    println!("\n   {} asks off a NeXosim run, filled in whole lots:", asks.len());
    println!(
        "     at or below {f_sieved}   {} asks, {} of them left a remainder",
        short_of_frobenius.0, short_of_frobenius.1
    );
    println!(
        "     above {f_sieved}          {} asks, {} of them left a remainder",
        past_frobenius.0, past_frobenius.1
    );
    println!("     total overshoot: {overshoot_total} units nobody asked for");

    // The finding: the schema's annotation and the lots disagree about whether the residue stops,
    // which is more than a missing field.
    println!("\n   what the schema's annotation and the lots each say about this supply");
    let modulus = gcd(lots[0], lots[1]);
    println!(
        "     the annotation            the residue repeats every {modulus}, which says nothing: \
         with these"
    );
    println!(
        "                               lot sizes every amount leaves some residue, so the rule is \
         true and empty"
    );
    println!(
        "     the lots                  the remainder is positive on exactly {} asks and \
         zero on every ask",
        gaps.len()
    );
    println!(
        "                               above {f_sieved}. With one lot size it never stops"
    );

    println!("\n   and what can actually be filed");
    println!("     pm:LumpyQuantum carries one size. The options are all false:");
    println!("       quantum 5    denies that a pallet of twelve exists");
    println!("       quantum 12   denies that a case of five exists");
    println!(
        "       quantum {modulus}    says the supply is divisible to the unit, which is the \
         one thing"
    );
    println!("                    it is not, and it is what the shared unit forces");
    println!(
        "     `nameplate_not_a_multiple` passes on the third, because every nameplate is a \
         whole"
    );
    println!("       multiple of one. A rule satisfied by the only lie the schema permits.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 2. The lumpiness on the other side.
// =============================================================================================

/// The assumption: supply comes in whole units and demand is continuous. It is the README's
/// opening sentence, and `pm:Divisibility` sits under `pm:Nameplate`, so there is nowhere else to
/// put it.
///
/// The reverse is just as common, and the arithmetic is the same. A grid supplies continuously and
/// a smelter draws in whole pot lines. A utility supplies water continuously and a farm irrigates
/// in whole field blocks. A payroll runs continuously and a hire is one person. With demand in
/// whole blocks and a continuous supply, the residue is what of the supply fits no whole block: the
/// same residue, read off the other side.
fn reversed_quantization() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 2. the lumpiness on the demand side ══════════════════════════════════\n");

    // Not a multiple, on purpose. A rating the block divides exactly leaves nothing over, and the
    // whole probe would read as though the question does not arise.
    let block = 13.0_f64; // one pot line
    let supply = 3600.0_f64; // a continuous rating over the window
    let blocks = (supply / block).floor();
    let residue = supply - blocks * block;

    println!("   a continuous supply of {supply} against demand in whole blocks of {block}");
    println!("     blocks the supply covers       {blocks}");
    println!("     supply that fits no block      {residue}");
    println!(
        "     left over after whole blocks   {residue} of {supply} in blocks of {block}   {}",
        agree((supply % block - residue).abs() < 1e-9)
    );

    println!("\n   the arithmetic is the same either way, and the schema is not");
    println!("     pm:Divisibility is a child of pm:Nameplate. pm:Demand has amount and patience");
    println!("     and no divisibility of any kind, so a filer with a lumpy demand has three");
    println!("     moves and all three lose something:");
    println!("       file the supply as lumpy at {block}   asserts a fact about the wrong operand");
    println!("       file nothing                     loses the whole structure, and the");
    println!("                                        remainder then looks like measurement noise");
    println!("       swap the roles                   files the smelter as the supply, which");
    println!("                                        inverts every holder on the layer");

    println!("\n   The third is the one to look at, because it nearly works. Swapping puts");
    println!("     the quantum where the schema wants it, and the remainder right but for sign.");
    println!("     What it cannot keep is who holds it: unserved demand under one reading is idle");
    println!("     capacity under the other, and `customer` and `booked` are not interchangeable.");
    println!(
        "     The remainder survives the swap and the contribution does not, which is the model"
    );
    println!("     saying its two halves are independent in the sharpest possible way.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 3. Two windows over one history.
// =============================================================================================

/// The assumption: a layer has one period, and the answer does not depend on it. Every `pm:Layer`
/// figure is over a stated window, and nothing says what happens when the same business is filed
/// twice at two window lengths. The schema composes across parties, at length: `part`, fusion,
/// elimination, coupling attenuation. It composes across periods nowhere.
///
/// And `pm:Fit` does not add up across windows, which turns that gap into a contradiction rather
/// than an omission. A run whose nameplate clears its demand over six hours can contain half hours
/// where it did not. `clearance_with_unserved` forbids a clearance layer from naming `customer` or
/// `unrealised`, and those same customers must be named on the shorter filings. So the two
/// documents are each sound, they describe one shop, and one of them cannot mention the people the
/// other has to.
fn windows_do_not_compose() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 3. one shop, two window lengths ══════════════════════════════════════\n");

    let whole_window = Duration::from_secs(6 * 60 * 60);
    let slices = 24u32;
    let slice_len = whole_window / slices;

    println!(
        "   a line at about 95% of its rating, six hours, cut into {slices} quarter hours\n"
    );
    println!(
        "   {:<6} {:>10} {:>12} {:>12} {:>10} {:>10}",
        "seed", "fit", "demand", "nameplate", "tipped", "unserved"
    );

    // Every seed is reported, not the one that makes the point. Hunting for a run that splits and
    // showing only that one would manufacture the finding. The question is how often an ordinary
    // shop files two documents it cannot reconcile.
    let mut split = 0u32;
    let mut runs = 0u32;
    for seed in [1u64, 2, 3, 5, 8, 13, 21, 34] {
        let outcome = run(tight_settings(), seed, whole_window)?;
        let one = Instrument::Whole.read(&outcome, None);

        let mut tipped = 0u32;
        let mut unserved_in_slices = 0.0;
        for index in 0..slices {
            let from = slice_len * index;
            let to = slice_len * (index + 1);
            let last = index == slices - 1;
            let piece = Run {
                settings: outcome.settings.clone(),
                seed: outcome.seed,
                window: slice_len,
                history: outcome
                    .history
                    .iter()
                    .filter(|r| r.at >= from && (r.at < to || (last && r.at <= to)))
                    .cloned()
                    .collect(),
            };
            let reading = Instrument::Whole.read(&piece, None);
            unserved_in_slices += point_of(reading.unserved);
            if fit_of(&reading) != "clearance" {
                tipped += 1;
            }
        }

        let whole_fit = fit_of(&one);
        let contradicts = whole_fit == "clearance" && tipped > 0;
        runs += 1;
        if contradicts {
            split += 1;
        }
        println!(
            "   {seed:<6} {whole_fit:>10} {:>12.1} {:>12.1} {:>10} {:>10.1}  {}",
            point_of(one.demand),
            point_of(one.nameplate),
            tipped,
            unserved_in_slices,
            if contradicts { "cannot be reconciled" } else { "" }
        );
    }

    println!("\n   The fit changes with the window, in {split} of {runs} runs.");
    println!("     Six hours of the same history is a `clearance`: the rating cleared the demand");
    println!("     with room to spare. The quarter hours counted as tipped above are");
    println!("     an `interference`: inside them the rating did not. Both readings are correct");
    println!("     arithmetic on the same events, and `pm:Fit` is the sign of the remainder, so");
    println!("     the sign of a business depends on how long you look at it.");

    println!("\n   And the absorber moves with it: one buffer standing in for another as the");
    println!("     measurement window changes. Over six hours the line idled, so the");
    println!("     remainder is absorbed by `capacity` and held `booked`. Over a quarter hour it");
    println!("     did not idle and drew on finished stock instead, so the same remainder is");
    println!("     absorbed by `inventory` and held `booked`. Nobody changed anything. Shortening");
    println!("     the window converted a capacity story into an inventory story, which is a fair");
    println!("     description of what a buffer is: the thing that makes a longer window's answer");
    println!("     differ from a shorter one's.");

    println!("\n   The hard case is rarer, and it is the one that cannot be reconciled.");
    println!("     Where a quarter hour turns demand away for real, that demand is `customer` or");
    println!("     `unrealised` and the quarter hour filing must name it.");
    println!("     `clearance_with_unserved` forbids the six hour filing from naming either.");
    println!("     So the longer filing cannot mention people the shorter");
    println!("       ones are obliged to, and every rule passes on both documents.");
    println!("     The seeds with unserved demand above are that case: unnameable at six hours.");

    println!("\n   And nothing in the schema can notice. `pm:Coupling` relates two layers of");
    println!("     one filing. `part`, fusion and elimination relate two parties, at length and");
    println!("     with their own rules. There is an elaborate composition law across parties and");
    println!("     none across periods, so no rule ranges over the pair.");
    println!("\n   `Claim/denominator` already carries the period, so the schema can say which");
    println!("     window a figure is of. What is missing is any element that says one figure is");
    println!("     a shorter period inside a longer one, which is what a reconciliation would");
    println!("     need to range over.");
    println!(
        "\n   `pm:Divisibility/window` looks like the answer and is not: it is the supply's"
    );
    println!("     duty cycle inside one period, never a period inside a longer period.");
    println!();
    Ok(())
}

/// The three way comparison exactly as `layers/remainder.sqlc` computes it.
fn fit_of(r: &simulation::instrument::Reading) -> &'static str {
    let (n, d) = (r.nameplate, r.demand);
    match (n, d) {
        (
            simulation::instrument::Bounded::Range { low: nl, high: nh },
            simulation::instrument::Bounded::Range { low: dl, high: dh },
        ) => {
            if nl - dh >= 0.0 {
                "clearance"
            } else if nh - dl <= 0.0 {
                "interference"
            } else {
                "transition"
            }
        }
        _ => "unmeasured",
    }
}

fn point_of(b: simulation::instrument::Bounded) -> f64 {
    match b {
        simulation::instrument::Bounded::Range { low, .. } => low,
        simulation::instrument::Bounded::Unmeasured => 0.0,
    }
}

fn agree(b: bool) -> &'static str {
    if b { "agree" } else { "disagree" }
}
