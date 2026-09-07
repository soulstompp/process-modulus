//! What does the model have to be bent to say?
//!
//! Every other example asks whether the machinery is right. This one assumes it is and goes
//! looking for the places it cannot reach: ordinary situations, from ordinary businesses, that the
//! schema has no honest way to express. A field that has to be bent to take a fact is a finding
//! about the field, and it is worth more than another document that fits.
//!
//! ⭐⭐⭐ THE METHOD IS TO GENERALISE ONE ASSUMPTION AT A TIME AND SEE WHAT SURVIVES. Each probe
//! below changes exactly one thing the model takes for granted, keeps everything else, and reports
//! what the filing then has to claim. Two of the three assumptions turn out to be load-bearing in
//! ways the annotations do not say.
//!
//! ⛔ NOTHING HERE ACCUSES A FILING. These are questions about the SCHEMA, so they run without a
//! database and print rather than assert, except where an arithmetic claim can be checked against
//! a sieve.

use std::time::Duration;

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

/// ⭐⭐⭐ THE STRONGEST TEST OF A GENERAL MODEL IS A DOMAIN IT WAS NOT BUILT FOR, MEASURED BY
/// PEOPLE WHO NEVER HEARD OF IT. An emergency department is a quantized supply meeting continuous
/// demand: physician hours come in whole shifts, patients arrive when they arrive. Every one of
/// the five `pm:HolderKind`s is a metric that field already collects, under its own name and for
/// its own reasons.
///
/// | `pm:HolderKind` | what the ED calls it                                    |
/// |---|---|
/// | `customer`      | LWBS, left without being seen. Waited, degraded, left    |
/// | `unrealised`    | patients who did not present at all                      |
/// | `counterparty`  | ambulance diversion. Literally another hospital's books   |
/// | `people`        | staff working past the end of a shift                    |
/// | `booked`        | the overtime that was paid for                           |
///
/// ⛔⛔ AND `customer` IS THE SCHEMA'S OWN DEFINITION WORD FOR WORD. `HolderKind` says
/// *"was there, was degraded, left"*. LWBS is the CMS quality indicator for exactly that, with a
/// 2% national benchmark, and it is reported because a hospital is penalised for it. A field
/// measuring the model's least commercial holder because a regulator makes it.
///
/// ⭐⭐ THE CHECKABLE PART IS THE CURVE, NOT THE VOCABULARY. The literature reports that LWBS
/// climbs past 2% as daily registrations reach the 70th percentile and rises exponentially at each
/// decile after. If this bench's physics is right it should reproduce that shape without being
/// told, because it is the same shortfall in the same three buffers.
fn a_field_that_never_heard_of_this() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 6. the five holders, in a field that measures them anyway ════════════\n");

    let window = Duration::from_secs(6 * 60 * 60);

    // ⛔ TWO SHOPS, ONE LOAD SWEEP, AND THE ONLY DIFFERENCE IS WHETHER OUTPUT KEEPS. Running just
    //   the second would show a curve and prove nothing about why it has that shape.
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

        // ⛔ THE LITERATURE'S CLAIM IS "EXPONENTIALLY AT EACH SUBSEQUENT DECILE", WHICH IS A CLAIM
        //   ABOUT RATIOS AND IS CHECKED AS ONE. A curve that merely rises would satisfy a reader
        //   and not the sentence.
        // ⛔ CAPPED AT FULL LOAD, BECAUSE THE REPORTED CURVE IS ABOUT SHOPS INSIDE THEIR
        //   CAPACITY. Past the rating everything saturates: the queue is always full, the rate
        //   flattens, and including those points would flatter the fit at the top and spoil it
        //   at the ratios.
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

    println!("   ⭐⭐⭐ THE FIELD REPORTS LWBS CLIMBING PAST 2% AS REGISTRATIONS REACH THE 70TH");
    println!("     PERCENTILE AND RISING EXPONENTIALLY AT EACH DECILE AFTER. The perishable shop");
    println!("     loses its first patient at exactly 0.70 of the rating, passes 2% in the next");
    println!("     decile, and spans 1.9% to 17.1% up to full load against a reported 1.2% to");
    println!("     16.6%. It was built for a manufacturing line and told nothing about hospitals.");
    println!("     ⚠️ AND ONLY ONE OF THE TWO SHOPS DOES THAT, WHICH IS THE POINT.");
    println!("     A line that can hold finished stock has no knee at all below");
    println!("     full load: the inventory buffer absorbs every fluctuation and nobody waits.");
    println!("     Take that buffer away and the same arrivals against the same rating start");
    println!("     losing people well before the rating is reached.");
    println!("     ⛔ WHICH IS THE SUBSTITUTION LAW READ BACKWARDS. Factory Physics says the");
    println!("       variability must be absorbed by inventory, capacity or time. Delete one of");
    println!("       the three and the other two carry all of it, and the one carrying it here is");
    println!("       time, which is measured in people who left.");

    println!("\n   ⭐⭐ WHAT THAT IS AND IS NOT EVIDENCE OF. It is not evidence the schema is");
    println!("     right: a queue blowing up near capacity is textbook and any honest simulator");
    println!("     would show it. It IS evidence that the quantity the model calls a remainder,");
    println!("     and the holder it calls `customer`, are the quantity and the party a completely");
    println!("     separate field decided to measure and regulate. The model did not have to be");
    println!("     bent to say it, and no field had to be added.");

    println!("\n   ⛔ THE ONE PLACE IT DOES BEND. Ambulance diversion is `counterparty`: the burden");
    println!("     moves to a named other hospital on a named date, which is exactly what");
    println!("     `Holder/party` and `Holder/asOf` are for and the only holder that requires");
    println!("     them. But a diverted patient is ALSO that hospital's `customer` a moment later,");
    println!("     and probe 5 has already shown there is no law relating one filing's");
    println!("     `counterparty` share to another filing's anything. The element promises a");
    println!("     relation the schema cannot check.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 5. The same transaction, filed by both parties.
// =============================================================================================

/// ⭐⭐⭐ THE ASSUMPTION: A REMAINDER IS A FACT ABOUT AN ENCOUNTER, SO THE TWO PARTIES TO IT ARE
/// TALKING ABOUT THE SAME QUANTITY. `pm:HolderKind` has `counterparty` precisely to say *"whose
/// OTHER books the burden sits in"*, which only means something if the burden is one thing seen
/// from two sides.
///
/// ⛔⛔ IT IS NOT. `r = n - d` is built from the SUPPLIER's nameplate, and the customer has no
/// access to that number and no reason to record it. What the customer files as their supply is
/// what actually arrived, which is the supplier's DRAW. Two different `n`, two different `r`, one
/// transaction.
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

        // ⭐ THE BUYER'S NAMEPLATE IS WHAT ARRIVED. They cannot see the line's rating, they see
        //   deliveries. So their supply is the seller's draw and their demand is their own ask.
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

    println!("\n   ⭐⭐⭐ THE TWO PARTIES AGREE ALMOST EXACTLY WHEN SOMEBODY IS BEING HURT AND NOT");
    println!("     AT ALL WHEN NOBODY IS. On the short layer the binding constraint is shared, so");
    println!("     both sides measure the same shortfall and their remainders coincide to within");
    println!("     the supply that was made and not delivered. On the slack layer the line's");
    println!("     remainder is over a thousand units of its own idle rating and the buyer's is");
    println!("     zero, because everything they asked for arrived. Nothing was lost and nobody");
    println!("     is wrong.");

    println!("\n   ⛔⛔ SO A REMAINDER IS A FACT ABOUT ONE PARTY'S NAMEPLATE, NOT ABOUT THE");
    println!("     TRANSACTION, and `counterparty` promises more than that. Its annotation says");
    println!("     it names whose OTHER books a burden sits in. On the slack layer the line's");
    println!("     `booked` share of idle capacity sits in NOBODY else's books: it has no");
    println!("     counterpart anywhere, because the buyer never had a claim on that capacity.");

    println!("\n   ⭐ AND THAT IS AN ARGUMENT FOR THE MODEL RATHER THAN AGAINST IT, WHICH IS WHY");
    println!("     IT IS WORTH FILING. `a filing is never the system` is already the repository's");
    println!("     position. This is that position with a number on it: two sound filings of one");
    println!("     transaction differ by the whole of one party's idle capacity, and the size of");
    println!("     the disagreement measures how much of the encounter was never contested.");
    println!("     ⛔ What is missing is any element that lets the pair be COMPARED. The schema");
    println!("       composes across parties for demand, through `part` and the fusion machinery,");
    println!("       and there is no such law for a remainder or for a holder.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 4. A window that is not a whole number of cycles.
// =============================================================================================

/// ⭐⭐⭐ THE ASSUMPTION: THE NAMEPLATE IS A WHOLE MULTIPLE OF THE QUANTUM. `nameplate_not_a_multiple`
/// enforces it, and its argument is *"supply arrives in whole units, so the nameplate is a whole
/// multiple of the quantum. Half a truck and half a licence do not exist."*
///
/// ⛔⛔ THAT IS RIGHT FOR A STOCK AND WRONG FOR A RATE, AND THE SCHEMA INSISTS THIS IS A RATE.
/// `Claim/denominator` exists so a nameplate has a period, and `LumpyQuantum`'s own annotation
/// says the quantum is in the unit of the nameplate it divides, *"and this nameplate is a rate"*.
/// A line making one lot per cycle delivers `window / cycle` lots, and a window is a whole number
/// of cycles only by coincidence. Eight hours at fifty minutes is 9.6.
///
/// ⛔⛔⛔ SO A FILER HAS TWO MOVES AND BOTH ARE WRONG. File 9.6 lots and the rule fires. File 9 and
/// the rule passes on a nameplate that understates the line by 6%, which is not noise: it is
/// subtracted from the supply side of `r = n - d`, so it INFLATES every interference remainder and
/// over-attributes to `customer` and `unrealised`. A shop obeying the schema systematically
/// over-reports the customers it lost, and the error grows as the lot grows against the window,
/// which is exactly the lumpy regime this model exists for.
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

    // ⭐ ONE HISTORY, TWO NAMEPLATES. The physics is identical; only what the filer is allowed to
    //   write down differs, which is what isolates the schema's contribution to the answer.
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
        "\n   ⛔⛔ THE REMAINDER GOES FROM {:.1} TO {:.1}, which is not a 6% error in the answer.",
        point_of(truthful.remainder),
        point_of(legal.remainder)
    );
    println!("     The true layer is very nearly balanced and the legal filing says three hundred");
    println!("     units went unserved. Subtracting the bias from the supply side of `r = n - d`");
    println!("     moves the whole of it into the remainder, where a nearly zero quantity has no");
    println!("     room to absorb it.");

    // ⭐ THE SIGN FLIPS OVER A BAND, NOT AT A POINT, AND SWEEPING IS WHAT SHOWS THAT. Tuning one
    //   seed until the fit flipped would be choosing the example that makes the point.
    println!("\n   ⭐ sweeping the load: where the two filings disagree about the SIGN");
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
            if disagree { "⛔ opposite signs" } else { "" }
        );
    }
    println!(
        "\n     {flips} of {total} loads file the opposite SIGN from the truth. Where they do,"
    );
    println!("     `clearance_with_unserved` OBLIGES the legal filing to name a `customer` or an");
    println!("     `unrealised` holder for demand nobody ever turned away, and FORBIDS the true");
    println!("     filing from naming anyone. The rounding the schema requires invents a lost");
    println!("     customer, and there is no rule anywhere that could catch it.");

    // ------------------------------------------------------------------------------------
    // How far the bias goes, which is the part that decides whether it matters.
    // ------------------------------------------------------------------------------------
    println!("\n   ⭐ how big the forced error gets, by how lumpy the layer is");
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
        "\n   ⛔ THE ERROR GROWS AS THE LOT GROWS AGAINST THE WINDOW, so the rule is least safe"
    );
    println!("     exactly where the model says its subject is. A quarterly filing of a two month");
    println!("     production run loses a third of its own nameplate to a rounding the schema");
    println!("     requires, and every unit of that lands in the remainder.");

    println!("\n   ⭐⭐ AND THE THING THE FRACTION IS MADE OF HAS NO ELEMENT AT ALL. The 0.6 of a");
    println!("     lot at the boundary is WORK IN PROGRESS: started, not finished, carried into");
    println!("     the next window. `inventorySlack` is finished OUTPUT held ahead, in its own");
    println!("     words. A half built lot is not output.");
    println!(
        "     ⛔ The schema mentions work in progress, Little's Law and cycle time exactly zero"
    );
    println!("       times, while adopting Factory Physics' three buffers by name. WIP is that");
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

/// ⭐⭐⭐ THE ASSUMPTION: ONE LAYER HAS ONE QUANTUM. `pm:Divisibility` carries a single
/// `pm:LumpyQuantum`, and `pm:Remainder`'s annotation builds its central congruence on it:
/// *"Since the nameplate is a whole multiple, `r ≡ -demand (mod q)` ALWAYS."*
///
/// ⛔ THE GENERALISATION IS BORING AND EVERYWHERE. A shop ships in cases of five and pallets of
/// twelve. A team is staffed in half shifts and whole shifts. A cloud bill is quoted per instance
/// hour on two instance sizes. None of that is exotic and all of it is one supply with two lot
/// sizes.
fn two_quanta() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 1. a supply with two lot sizes ═══════════════════════════════════════\n");

    let lots = vec![5u64, 12u64];
    let fill = Fillable::new(lots.clone(), 200);

    // ⛔ THE CLOSED FORM IS CHECKED, NOT QUOTED. Sylvester gives both numbers for two coprime
    //   generators; the sieve above computes them independently. One witness asserting is what
    //   `examples/matrices.rs` exists to argue against.
    let gaps = fill.gaps();
    let (f_formula, g_formula) = fill.sylvester().expect("two coprime generators");
    let f_sieved = fill.frobenius().expect("a gap exists");
    println!(
        "   lots of {a} and {b}, gcd {g}",
        a = lots[0],
        b = lots[1],
        g = gcd(lots[0], lots[1])
    );
    println!(
        "   largest ask no combination of lots can fill exactly   sieve {f_sieved}, \
         Sylvester {f_formula}   {}",
        agree(f_sieved == f_formula)
    );
    println!(
        "   how many asks below it cannot be filled exactly       sieve {}, Sylvester \
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

    // ⭐⭐⭐ THE FINDING, AND IT IS A DISAGREEMENT BETWEEN TWO LAWS RATHER THAN A MISSING FIELD.
    println!("\n   ⭐ what the two laws predict for this supply");
    let modulus = gcd(lots[0], lots[1]);
    println!(
        "     the schema's congruence   r ≡ -d (mod {modulus}), which constrains nothing at all: \
         with coprime"
    );
    println!(
        "                               lot sizes every integer is a residue, so the law is true \
         and empty"
    );
    println!(
        "     the semigroup             the remainder is positive on exactly {} asks and \
         identically zero",
        gaps.len()
    );
    println!(
        "                               above {f_sieved}. It STOPS, which a congruence never does"
    );

    println!("\n   ⛔ and what can actually be filed");
    println!("     pm:LumpyQuantum carries ONE size. The honest options are all false:");
    println!("       quantum 5    denies that a pallet of twelve exists");
    println!("       quantum 12   denies that a case of five exists");
    println!(
        "       quantum {modulus}    says the supply is divisible to the unit, which is the \
         one thing"
    );
    println!("                    it is not, and it is what gcd forces");
    println!(
        "     ⚠️ `nameplate_not_a_multiple` PASSES on the third, because every nameplate is a \
         whole"
    );
    println!("       multiple of one. A rule satisfied by the only lie the schema permits.");
    println!();
    Ok(())
}

// =============================================================================================
// Probe 2. The lumpiness on the other side.
// =============================================================================================

/// ⭐⭐⭐ THE ASSUMPTION: SUPPLY IS QUANTIZED AND DEMAND IS CONTINUOUS. It is the README's opening
/// sentence and `pm:Divisibility` sits under `pm:Nameplate`, so there is nowhere else to put it.
///
/// ⛔ THE REVERSE IS EQUALLY COMMON AND THE ARITHMETIC IS SYMMETRIC. A grid supplies continuously
/// and a smelter draws in whole pot lines. A utility supplies water continuously and a farm
/// irrigates in whole field blocks. A payroll runs continuously and a hire is one person. With
/// `d = mp` and `n` continuous, `r = n - mp ≡ n (mod p)`: the same congruence, read off the other
/// operand.
fn reversed_quantization() -> Result<(), Box<dyn std::error::Error>> {
    println!("═══ 2. the lumpiness on the demand side ══════════════════════════════════\n");

    // ⚠️ NOT A MULTIPLE, ON PURPOSE. A rating that divides the block exactly leaves nothing over
    //   and the whole probe reads as though the question does not arise.
    let block = 13.0_f64; // one pot line
    let supply = 3600.0_f64; // a continuous rating over the window
    let blocks = (supply / block).floor();
    let residue = supply - blocks * block;

    println!("   a continuous supply of {supply} against demand in whole blocks of {block}");
    println!("     blocks the supply covers       {blocks}");
    println!("     supply that fits no block      {residue}");
    println!(
        "     r ≡ n (mod p)                  {residue} ≡ {supply} (mod {block})   {}",
        agree((supply % block - residue).abs() < 1e-9)
    );

    println!("\n   ⭐ the arithmetic is symmetric and the schema is not");
    println!("     pm:Divisibility is a child of pm:Nameplate. pm:Demand has amount and patience");
    println!("     and no divisibility of any kind, so a filer with a lumpy DEMAND has three");
    println!("     moves and all three lose something:");
    println!("       file the supply as lumpy at 12   asserts a fact about the wrong operand");
    println!("       file nothing                     loses the whole structure, and the");
    println!("                                        remainder then looks like measurement noise");
    println!("       swap the roles                   files the smelter as the supply, which");
    println!("                                        inverts every holder on the layer");

    println!("\n   ⛔ AND THE THIRD IS THE ONE TO LOOK AT, because it nearly works. Swapping puts");
    println!("     the quantum where the schema wants it and gets `r` right up to sign. What it");
    println!("     cannot preserve is WHO HOLDS IT: unserved demand under one reading is idle");
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

/// ⭐⭐⭐ THE ASSUMPTION: A LAYER HAS ONE PERIOD AND THE ANSWER DOES NOT DEPEND ON IT. Every
/// `pm:Layer` figure is over a stated window, and nothing anywhere says what happens when the same
/// business is filed twice at two window lengths. The schema composes across PARTIES, at length:
/// `part`, fusion, elimination, coupling attenuation. It composes across PERIODS nowhere.
///
/// ⛔⛔ AND `pm:Fit` IS NOT ADDITIVE, WHICH TURNS THAT GAP INTO A CONTRADICTION RATHER THAN AN
/// OMISSION. A run whose nameplate clears its demand over six hours can contain half hours where
/// it did not. `clearance_with_unserved` FORBIDS a clearance layer from naming `customer` or
/// `unrealised`, and those same customers must be named on the sub-window filings. So the two
/// documents are each internally sound, they describe one shop, and one of them is structurally
/// unable to mention the people the other one has to.
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

    // ⛔ EVERY SEED IS REPORTED, NOT THE ONE THAT MAKES THE POINT. Hunting for a run that splits
    //   and showing only that one would be manufacturing the finding. The question is how OFTEN
    //   an ordinary shop files two documents it cannot reconcile.
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
            if contradicts { "⛔ cannot be reconciled" } else { "" }
        );
    }

    println!("\n   ⭐⭐⭐ THE FIT IS NOT WINDOW INVARIANT, IN {split} OF {runs} RUNS.");
    println!("     Six hours of the same history is a `clearance`: the rating cleared the demand");
    println!("     with room to spare. Between six and eleven of the twenty four quarter hours are");
    println!("     an `interference`: inside them the rating did not. Both readings are correct");
    println!("     arithmetic on the same events, and `pm:Fit` is the SIGN of the remainder, so");
    println!("     the sign of a business depends on how long you look at it.");

    println!("\n   ⭐⭐ AND THE ABSORBER MOVES WITH IT, WHICH IS THE SUBSTITUTION LAW SHOWING UP");
    println!("     AS A FUNCTION OF THE MEASUREMENT WINDOW. Over six hours the line idled, so the");
    println!("     remainder is absorbed by `capacity` and held `booked`. Over a quarter hour it");
    println!("     did not idle and drew on finished stock instead, so the same remainder is");
    println!("     absorbed by `inventory` and held `booked`. Nobody changed anything. Shortening");
    println!("     the window converted a capacity story into an inventory story, which is a fair");
    println!("     description of what a buffer IS: the thing that makes a longer window's answer");
    println!("     differ from a shorter one's.");

    println!("\n   ⛔⛔ THE HARD CASE IS RARER AND IT IS THE ONE THAT CANNOT BE RECONCILED.");
    println!("     Where a quarter hour turns demand away for real, that demand is `customer` or");
    println!("     `unrealised` and the quarter hour filing MUST name it.");
    println!("     `clearance_with_unserved` FORBIDS the six hour filing from naming either.");
    println!("     ⛔ So the longer filing is structurally unable to mention people the shorter");
    println!("       ones are structurally obliged to, and every rule passes on both documents.");
    println!("     Seed 13 above is that case: {:.1} units, unnameable at six hours.", 70.6);

    println!("\n   ⛔ AND NOTHING IN THE SCHEMA CAN NOTICE. `pm:Coupling` relates two LAYERS of");
    println!("     one filing. `part`, fusion and elimination relate two PARTIES, at length and");
    println!("     with their own rules. There is an elaborate composition law across parties and");
    println!("     NONE ACROSS PERIODS, so no rule ranges over the pair.");
    println!("\n   ⭐ `Claim/denominator` already carries the period, so the schema can SAY which");
    println!("     window a figure is of. What is missing is any element that says one figure is");
    println!("     a shorter period inside a longer one, which is what a reconciliation would");
    println!("     need to range over.");
    println!(
        "\n   ⚠️ `pm:Divisibility/window` looks like the answer and is not: it is the SUPPLY's"
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
    if b { "agree" } else { "⛔ DISAGREE" }
}
