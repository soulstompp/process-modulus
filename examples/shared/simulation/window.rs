//! Assembling the bench and taking the history off it.
//!
//! The window is the filing's period and the simulation's at once. `pm:Layer` totals are always
//! over a stated period, and here that period ends where the simulation stops, so nothing that
//! adds up the history has to guess what the window was.

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
    /// The whole history, which exists here and nowhere after an instrument has read it.
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
/// The load is tuned. One lot of 10 a minute is 3600 over a six hour window; asks averaging 3.5
/// every 30 seconds come to about 2500. Far slacker than this, the line spills most of what it
/// makes and no buffer is ever under pressure, which exercises nothing.
pub fn slack_settings() -> Settings {
    Settings {
        lot: 10.0,
        cycle: Duration::from_secs(60),
        stock_cap: 100.0,
        queue_cap: 8,
        // No overtime on the slack line, which makes `capacitySlack` a typed absence rather than
        // a zero on the filing it produces.
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
/// An ask every 15 seconds is about 5000 against a nameplate of 3600. The excess has to go
/// somewhere and the three buffers are the only places, so this is the setting where one buffer
/// standing in for another is seen rather than assumed.
pub fn short_settings() -> Settings {
    Settings {
        mean_gap: Duration::from_secs(15),
        ..slack_settings()
    }
}

/// Short in the same degree, but with a deep queue and little patience, so the shortfall lands on
/// a different holder.
///
/// The same shortfall, borne by a different party. `short_settings` turns demand away at the
/// door, which nobody experiences, so it is `unrealised`. This one lets it in, makes it wait and
/// loses it, which somebody did experience, so it is `customer`. The physics of the line is the
/// same: the lot, the cycle and the load are identical. Only the time buffer is arranged
/// differently, and the holder changes.
///
/// A stock-and-flow framework cannot reach this setting at all. Giving up requires patience, and
/// a resource that waits for ever never gives up, so there the `customer` share is not just
/// unmeasured but cannot arise.
pub fn queued_settings() -> Settings {
    Settings {
        queue_cap: 40,
        patience: Duration::from_secs(90),
        ..short_settings()
    }
}

/// Short in the same degree again, and this time the line is allowed to run above its rating.
///
/// The setting `share_exceeds_slack` in `assets/sql/checks/` is written for. A line with overtime
/// files a sized `capacitySlack`, names `capacity` as the absorber, and puts a `people` share on
/// an interference layer, to be held against that slack.
///
/// Thirty lots on a rating of three hundred and sixty is under a tenth, which is what an overtime
/// allowance looks like. Sized generously, it would swallow the whole shortfall and the unserved
/// holders would be empty, which exercises something else.
pub fn overtime_settings() -> Settings {
    Settings {
        overtime_lots: 30,
        ..short_settings()
    }
}

/// A line whose output perishes the instant it is made, which is what a service is.
///
/// An emergency department has no inventory buffer and cannot have one: nobody can treat patients
/// in advance and stockpile the treatment. Factory Physics says the variability has to go
/// somewhere, so with one of the three buffers absent it all lands on time and capacity, and the
/// time buffer is a waiting room with a patience on it.
pub fn perishable_settings() -> Settings {
    Settings {
        stock_cap: 0.0,
        queue_cap: 40,
        patience: Duration::from_secs(300),
        ..slack_settings()
    }
}

/// A batch line whose window is not a whole number of cycles, which is most real windows.
///
/// A lot of five hundred every fifty minutes over an eight hour shift is 9.6 cycles. The line can
/// deliver nine whole lots in the shift and carries most of a tenth across the boundary as work in
/// progress. The schema has no element for that carried part: `inventorySlack` is finished output
/// held ahead, and a half built lot is not output.
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

/// A line running close enough to its rating that the answer depends on how long you look.
///
/// Ninety-five per cent loaded is the ordinary case, not an edge: shops are run near capacity on
/// purpose, and that is where a six hour figure and a fifteen minute figure stop agreeing about
/// whether anybody was turned away.
pub fn tight_settings() -> Settings {
    Settings {
        mean_gap: Duration::from_secs(22),
        ..slack_settings()
    }
}

/// Whole-unit asks over a wide range, for a supply that must be filled in whole lots.
///
/// The range reaches past the largest ask the lots cannot fill, on purpose. With lots of five and
/// twelve that ask is forty-three, so a run whose asks stopped at forty would never see an ask
/// past it and could conclude the remainder never stops.
pub fn lotted_settings() -> Settings {
    Settings {
        size_low: 1.0,
        size_high: 60.0,
        integral_asks: true,
        mean_gap: Duration::from_secs(20),
        ..slack_settings()
    }
}

/// The same load again with all three buffers at zero, which is the case `exposure_unaccounted`
/// ranges over.
///
/// Running it shows why real filings do not reach that case. With nothing held, nobody waiting and
/// no room above the rating, an ask can be met only if it arrives at the very instant a lot is
/// made, which practically never happens. So a layer with every buffer sized and empty delivers
/// essentially nothing: the rule's population is empty in a real corpus because such a business
/// does not run, not because the rule is wrong.
///
/// The filing it produces is an extreme case, on purpose. A rating of 3600 that delivers nothing
/// is not a shop anybody runs; it is the corner the rule is written for, and a rule whose corner
/// nothing reaches can never be seen to fail.
pub fn starved_settings() -> Settings {
    Settings {
        stock_cap: 0.0,
        queue_cap: 0,
        patience: Duration::ZERO,
        overtime_lots: 0,
        ..short_settings()
    }
}
