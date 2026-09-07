//! Assembling the bench and taking the history off it.
//!
//! ⭐⭐ THE WINDOW IS THE FILING'S UNIT AND THE SIMULATION'S UNIT AT ONCE. `pm:Layer` totals are
//! always over a stated period, and here that period is literally where the simulation was
//! stopped. Nothing about the fold has to guess what a window was.

use std::time::Duration;

use nexosim::ports::{EventSinkReader, SinkState, event_queue};
use nexosim::simulation::{Mailbox, SimInit, SimulationError};
use nexosim::time::MonotonicTime;

use super::event::Record;
use super::layer::{Arrivals, Line, Settings};

/// One run, and everything needed to say what it was.
pub struct Run {
    pub settings: Settings,
    pub seed: u64,
    pub window: Duration,
    /// ⭐ THE WHOLE TRUTH, which exists here and nowhere downstream of an instrument.
    pub history: Vec<Record>,
}

/// Runs one layer for one window and returns everything that happened.
pub fn run(settings: Settings, seed: u64, window: Duration) -> Result<Run, SimulationError> {
    let mut arrivals = Arrivals::new(settings.clone(), seed);
    let mut line = Line::new(settings.clone());

    let arrivals_mbox = Mailbox::new();
    let line_mbox = Mailbox::new();

    arrivals.ask.connect(Line::ask, &line_mbox);

    let (sink, mut log) = event_queue(SinkState::Enabled);
    line.log.connect_sink(sink);

    let mut simu = SimInit::new()
        .add_model(arrivals, arrivals_mbox, "arrivals")
        .add_model(line, line_mbox, "line")
        .init(MonotonicTime::EPOCH)?;

    simu.step_until(window)?;

    let mut history = Vec::new();
    while let Some(record) = log.try_read() {
        history.push(record);
    }

    Ok(Run {
        settings,
        seed,
        window,
        history,
    })
}

/// A layer able to meet its demand with room to spare, so nothing goes unserved.
///
/// ⭐ THE LOAD IS TUNED, NOT ARBITRARY. One lot of 10 a minute is 3600 over a six hour window;
/// asks average 3.5 every 30 seconds is about 2500. Left far slacker than this the line spills
/// most of what it makes and no buffer is ever under pressure, which exercises nothing.
pub fn slack_settings() -> Settings {
    Settings {
        lot: 10.0,
        cycle: Duration::from_secs(60),
        stock_cap: 100.0,
        queue_cap: 8,
        // ⛔ NO OVERTIME ON THE SLACK LINE, and that is what makes `capacitySlack` a typed
        //   absence rather than a zero on the filing it produces.
        overtime_lots: 0,
        patience: Duration::from_secs(300),
        mean_gap: Duration::from_secs(30),
        size_low: 1.0,
        size_high: 6.0,
        integral_asks: false,
        floor_nameplate: true,
    }
}

/// The same layer asked for more than it can make, which is the population the model exists for.
///
/// ⛔ AN ASK EVERY 15 SECONDS IS ABOUT 5000 AGAINST A NAMEPLATE OF 3600. The excess has to go
/// somewhere and the three buffers are the only places, so this is the setting where the
/// substitution is visible rather than assumed.
pub fn short_settings() -> Settings {
    Settings {
        mean_gap: Duration::from_secs(15),
        ..slack_settings()
    }
}

/// Short in the same degree, but with a deep queue and little patience, so the shortfall lands on
/// a different holder.
///
/// ⭐⭐⭐ THE SAME SHORTFALL, A DIFFERENT PARTY BEARING IT. `short_settings` turns demand away at
/// the door, which nobody experiences, so it is `unrealised`. This one lets it in, makes it wait
/// and loses it, which somebody did experience, so it is `customer`. Nothing about the physics of
/// the line differs: the lot, the cycle and the load are identical. Only the time buffer is
/// arranged differently, and the holder changes.
///
/// ⛔ THIS IS THE SETTING A STOCK-AND-FLOW FRAMEWORK CANNOT REACH AT ALL. Reneging requires
/// patience, and a resource that waits for ever never gives up, so the `customer` column of the
/// holder matrix is not merely unmeasured there, it is unreachable.
pub fn queued_settings() -> Settings {
    Settings {
        queue_cap: 40,
        patience: Duration::from_secs(90),
        ..short_settings()
    }
}

/// Short in the same degree again, and this time the line is allowed to run above its rating.
///
/// ⭐⭐⭐ THE SETTING TWO RULES IN `assets/sql/checks/` HAVE BEEN WAITING FOR. Nothing in the
/// corpus files a sized `capacitySlack`, so `share_exceeds_slack` and `exposure_unaccounted`
/// examine nothing anywhere, and the vacuum has stood as a judgement rather than a finding. A
/// line with overtime puts a `people` holder on an interference layer, which is the population
/// both rules range over.
///
/// ⛔ THIRTY LOTS ON A RATING OF THREE HUNDRED AND SIXTY is under a tenth, which is what an
/// overtime allowance looks like. Sized generously it would swallow the whole shortfall and the
/// unserved holders would empty, which exercises a different thing.
pub fn overtime_settings() -> Settings {
    Settings {
        overtime_lots: 30,
        ..short_settings()
    }
}

/// The same load again with all three buffers at zero, which is the one case `exposure_unaccounted`
/// ranges over and no document in the corpus has ever filed.
///
/// ⭐⭐⭐ AND RUNNING IT IS WHAT TURNS THAT VACUUM FROM A JUDGEMENT INTO A STRUCTURAL FACT. With
/// nothing held, nobody waiting and no room above the rating, the ONLY way an ask can be met is
/// for supply and demand to coincide exactly in time, which in continuous time is a measure-zero
/// event. So a layer with every buffer sized and empty delivers essentially nothing, and the rule's
/// population is empty in any real corpus because such a business does not run rather than because
/// the rule is wrong. That is a far stronger answer than "no filing happens to have one".
///
/// ⚠️ THE FILING IT PRODUCES IS DEGENERATE AND IT IS SUPPOSED TO BE. A rating of 3600 that delivers
/// nothing is not a shop anybody runs; it is the corner the inequality is written for, and a rule
/// with no reachable corner cannot be falsified.
/// Whole-unit asks over a wide range, for a supply that must be filled in whole lots.
///
/// ⭐ THE RANGE REACHES PAST THE FROBENIUS NUMBER ON PURPOSE. With lots of five and twelve the
/// largest unfillable ask is forty three, so a run whose asks stop at forty would see nothing but
/// gaps and conclude the remainder is permanent.
/// A line running close enough to its rating that the answer depends on how long you look.
///
/// ⭐ NINETY FIVE PER CENT LOADED IS NOT AN EDGE CASE, IT IS THE TARGET. A shop deliberately run
/// near its capacity is the ordinary case, and it is exactly where a six hour figure and a fifteen
/// minute figure stop agreeing about whether anybody was turned away.
/// A batch line whose window is not a whole number of cycles, which is most real windows.
///
/// ⭐⭐⭐ A LOT OF FIVE HUNDRED EVERY FIFTY MINUTES OVER AN EIGHT HOUR SHIFT IS 9.6 CYCLES. The
/// line can deliver nine whole lots in the shift and carries most of a tenth across the boundary
/// as work in progress. There is no element anywhere in the schema for that carried part:
/// `inventorySlack` is finished OUTPUT held ahead, and a half built lot is not output.
/// A line whose output perishes the instant it is made, which is what a service is.
///
/// ⭐⭐⭐ AN EMERGENCY DEPARTMENT HAS NO INVENTORY BUFFER AND CANNOT HAVE ONE. You cannot treat
/// patients in advance and stockpile the treatment. Factory Physics says the variability has to
/// go somewhere, so with one of the three buffers structurally absent it must all land on time and
/// capacity, and the time buffer is a waiting room with a patience on it.
pub fn perishable_settings() -> Settings {
    Settings {
        stock_cap: 0.0,
        queue_cap: 40,
        patience: Duration::from_secs(300),
        ..slack_settings()
    }
}

pub fn batch_settings() -> Settings {
    Settings {
        lot: 500.0,
        cycle: Duration::from_secs(50 * 60),
        stock_cap: 1200.0,
        queue_cap: 20,
        patience: Duration::from_secs(3600),
        mean_gap: Duration::from_secs(21),
        overtime_lots: 0,
        ..slack_settings()
    }
}

pub fn tight_settings() -> Settings {
    Settings {
        mean_gap: Duration::from_secs(22),
        ..slack_settings()
    }
}

pub fn lotted_settings() -> Settings {
    Settings {
        size_low: 1.0,
        size_high: 60.0,
        integral_asks: true,
        mean_gap: Duration::from_secs(20),
        ..slack_settings()
    }
}

pub fn starved_settings() -> Settings {
    Settings {
        stock_cap: 0.0,
        queue_cap: 0,
        patience: Duration::ZERO,
        overtime_lots: 0,
        ..short_settings()
    }
}
