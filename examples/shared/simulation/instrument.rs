//! Two instruments over one history, and what each of them is able to say.
//!
//! An instrument turns a history into a reading, and two different histories can give the same
//! reading. [`Instrument::Whole`] sees every field of every event. [`Instrument::StockAndFlow`]
//! sees what a stock-and-flow event log records, which is less: a refusal without its magnitude,
//! and no way to tell a demand that was turned away from one that waited and left. Many histories
//! give the same stock-and-flow reading, so that reading names a set of histories rather than one.
//!
//! That set is why the answer is a range. Nothing recovers the history from the log, and picking
//! one history to stand for the set would be a choice rather than a reconstruction, so the true
//! report is how far the set reaches. `pm:Narrowing/kind = instrument` is this case, and it is told
//! apart from `intervention` for this reason: running again never narrows it, because the width
//! comes from what the log records and not from the world.
//!
//! The two losses are of different kinds. Dropping a magnitude widens a bound and keeps the truth
//! inside it. Merging two `pm:HolderKind`s into one row fixes their sum and leaves the split
//! between them free, which is not a wider range at all. The first is filed as a number; the
//! second has to be filed as an absence.

use std::time::Duration;

use super::event::{Event, Record};
use super::layer::Settings;
use super::window::Run;

// ---------------------------------------------------------------------------------------------
// What a reading is allowed to be.
// ---------------------------------------------------------------------------------------------

/// A magnitude as an instrument is able to report it.
///
/// `Unmeasured` is not a wide range. `pm:absent/reason = unmeasured` says nobody looked or nobody
/// could; a range says somebody looked, and this is how well. Merging the two would let an
/// unbounded guess pass for a measurement.
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Bounded {
    Range { low: f64, high: f64 },
    Unmeasured,
}

use Bounded::{Range, Unmeasured};

impl Bounded {
    pub fn point(x: f64) -> Self {
        Range { low: x, high: x }
    }

    /// How wide the range is: how far apart the histories behind this reading lie in this field.
    /// `None` where nothing was measured.
    pub fn width(&self) -> Option<f64> {
        match self {
            Range { low, high } => Some(high - low),
            Unmeasured => None,
        }
    }

    /// The lossy reading must contain the true one, and that is the whole claim, in one direction
    /// only. Equality is neither available nor wanted: an instrument that returned the truth
    /// exactly would have lost nothing, and this one does lose.
    pub fn admits(&self, truth: &Bounded) -> bool {
        match (self, truth) {
            // Nothing was claimed, so nothing is contradicted.
            (Unmeasured, _) => true,
            // Something was claimed about a quantity the truth does not fix. It never happens
            // here, because the whole instrument never returns `Unmeasured`.
            (Range { .. }, Unmeasured) => true,
            (Range { low, high }, Range { low: l, high: h }) => *low - 1e-6 <= *l && *h <= *high + 1e-6,
        }
    }

    fn add(self, other: Bounded) -> Bounded {
        match (self, other) {
            (Range { low: a, high: b }, Range { low: c, high: d }) => Range {
                low: a + c,
                high: b + d,
            },
            _ => Unmeasured,
        }
    }

    /// The bounds swap: the low end of a difference takes the other side's high end, and the high
    /// end takes its low end. Pairing low with low gives a range that looks right, is narrower
    /// than the truth, and fails to contain it only on the runs where it matters.
    fn sub(self, other: Bounded) -> Bounded {
        match (self, other) {
            (Range { low: a, high: b }, Range { low: c, high: d }) => Range {
                low: a - d,
                high: b - c,
            },
            _ => Unmeasured,
        }
    }
}

impl std::fmt::Display for Bounded {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Unmeasured => write!(f, "{:>19}", "unmeasured"),
            Range { low, high } if (high - low).abs() < 1e-9 => write!(f, "{low:>19.2}"),
            Range { low, high } => write!(f, "{:>8.2} .. {:<8.2}", low, high),
        }
    }
}

// ---------------------------------------------------------------------------------------------
// The reading.
// ---------------------------------------------------------------------------------------------

/// One layer, one window, as one instrument is able to report it.
///
/// The field names are the schema's: `demand`, `nameplate` and `remainder` are the filed demand,
/// nameplate and remainder, and `unrealised` and `customer` are two of the five `pm:HolderKind`s.
/// Nothing is renamed on the way in, so a disagreement between two instruments is a disagreement
/// about a filed field.
#[derive(Clone, Debug, PartialEq)]
pub struct Reading {
    pub demand: Bounded,
    /// What the line actually made, which is at most the nameplate and is less whenever it idled.
    pub made: Bounded,
    pub nameplate: Bounded,
    pub remainder: Bounded,
    pub served: Bounded,
    pub unserved: Bounded,
    /// Never became anybody's experience.
    pub unrealised: Bounded,
    /// Was there, was degraded, left.
    pub customer: Bounded,
    /// Supply made with nowhere to hold it: the magnitude on the interference side.
    pub spilled: Bounded,
    /// The two terms at the edge of the window, which exist only because a filing covers a
    /// period. `pending` is demand that had arrived and was still waiting when the window closed,
    /// so it is neither served nor unserved and no holder bears it yet. `undelivered` is rating
    /// that never became anything a customer could take. Both come out of the remainder's
    /// arithmetic and neither has a `pm:HolderKind`, so they are reported here rather than
    /// silently added to one of the five.
    pub pending: Bounded,
    pub undelivered: Bounded,
    /// Which buffer did the absorbing, a separate question from who bore it. Of what was served,
    /// how much came straight out of stock and how much only after a wait. A stock-and-flow log
    /// records no wait against a demand, so it knows neither, and `Remainder/absorber` has to be
    /// filed absent rather than guessed.
    pub from_stock: Bounded,
    pub after_waiting: Bounded,
    /// How much was made above the rating, which is the capacity buffer doing its work.
    pub ran_hot: Bounded,
}


// ---------------------------------------------------------------------------------------------
// The instruments.
// ---------------------------------------------------------------------------------------------

/// How much of the history reaches the reading.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Instrument {
    /// Everything. Only available inside the bench, where the history has not been thrown away.
    Whole,
    /// What a stock-and-flow event log carries: successes with their totals, failures with a
    /// reason and no magnitude, and no event at all for a demand that gave up waiting.
    StockAndFlow,
}

/// What a filer is willing to declare about the size of an ask nobody recorded.
///
/// This is the only place a bound can come from, and it is not in the log. A `pm:Claim` carries a
/// `pm:provenance` for this reason: a range over unrecorded magnitudes is somebody's stipulation,
/// and if nobody will make it, the field is `unmeasured` rather than zero.
#[derive(Clone, Copy, Debug)]
pub struct DeclaredAskSize {
    pub low: f64,
    pub high: f64,
}

impl Instrument {
    /// Adds a run up into a reading.
    pub fn read(&self, run: &Run, declared: Option<DeclaredAskSize>) -> Reading {
        match self {
            Instrument::Whole => whole(run),
            Instrument::StockAndFlow => stock_and_flow(run, declared),
        }
    }
}

/// The truth, which is a single value in every field.
fn whole(run: &Run) -> Reading {
    let mut asked = 0.0;
    let mut made = 0.0;
    let mut served = 0.0;
    let mut refused = 0.0;
    let mut reneged = 0.0;
    let mut spilled = 0.0;
    let mut from_stock = 0.0;
    let mut after_waiting = 0.0;
    let mut ran_hot = 0.0;

    for Record { what, .. } in &run.history {
        match what {
            Event::Asked { size, .. } => asked += size,
            Event::Produced { lot } => made += lot,
            Event::Served { size, waited, .. } => {
                served += size;
                if waited.is_zero() {
                    from_stock += size;
                } else {
                    after_waiting += size;
                }
            }
            Event::Refused { size, .. } => refused += size,
            Event::Reneged { size, .. } => reneged += size,
            Event::RanHot { lot } => {
                made += lot;
                ran_hot += lot;
            }
            Event::Idled { .. } => {}
            Event::Spilled { amount } => spilled += amount,
        }
    }

    // The rating, not the run. `nameplate` is what the line is able to make, fixed by the lot and
    // the cycle before anything happens. What it actually made is `made`, and it is smaller
    // whenever the line idled. Summing the lots here would make the nameplate depend on the
    // demand it met, which erases the clearance the model exists to name.
    let nameplate = run.settings.nameplate_over(run.window);

    Reading {
        demand: Bounded::point(asked),
        made: Bounded::point(made),
        nameplate: Bounded::point(nameplate),
        remainder: Bounded::point(nameplate - asked),
        served: Bounded::point(served),
        unserved: Bounded::point(refused + reneged),
        unrealised: Bounded::point(refused),
        customer: Bounded::point(reneged),
        spilled: Bounded::point(spilled),
        pending: Bounded::point(asked - served - refused - reneged),
        undelivered: Bounded::point(nameplate - served),
        from_stock: Bounded::point(from_stock),
        after_waiting: Bounded::point(after_waiting),
        ran_hot: Bounded::point(ran_hot),
    }
}

/// What a stock-and-flow log keeps. Three things in it lose information, and each is a finding
/// somebody can check against a real stock-and-flow framework.
///
/// 1. A refusal is logged with a reason and no magnitude, because the quantity is never sampled
///    on the branch that fails.
/// 2. A demand that gives up waiting has no event, because nothing in the framework has patience.
///    It is still unserved, so it arrives here as another failure, indistinguishable from the
///    first kind.
/// 3. Nothing distinguishes the two, so the split between the two unserved holders is gone while
///    their sum survives.
fn stock_and_flow(run: &Run, declared: Option<DeclaredAskSize>) -> Reading {
    let mut made = 0.0;
    let mut served = 0.0;
    let mut spilled = 0.0;
    let mut failures = 0usize;

    for Record { what, .. } in &run.history {
        match what {
            // The ask itself is not a logged event. Only its outcome is.
            Event::Asked { .. } => {}
            Event::Produced { lot } => made += lot,
            Event::Served { size, .. } => served += size,
            // Both of these are one row: `ProcessFailure { reason }`, and `reason` is a string.
            Event::Refused { .. } | Event::Reneged { .. } => failures += 1,
            // A lot made above the rating is an ordinary success in the log, and that is the
            // finding: the log records that the lot was made and carries nothing to say it was
            // made in overtime. The total is right and the buffer is invisible.
            Event::RanHot { lot } => made += lot,
            // A cycle that did not fire leaves no event, which costs nothing: the rating is a
            // property of the line, not a count of what came off it.
            Event::Idled { .. } => {}
            Event::Spilled { amount } => spilled += amount,
        }
    }

    // What the count of failures is worth depends entirely on whether anybody will bound an ask.
    let unserved = match declared {
        Some(DeclaredAskSize { low, high }) => Range {
            low: failures as f64 * low,
            high: failures as f64 * high,
        },
        None => Unmeasured,
    };

    let served = Bounded::point(served);
    // The rating comes through the log intact, so both instruments agree on it exactly. A
    // stock-and-flow log carries `max_capacity` and the cycle, and neither depends on what the
    // run happened to do.
    let nameplate = Bounded::point(run.settings.nameplate_over(run.window));
    let demand = served.add(unserved);

    Reading {
        demand,
        made: Bounded::point(made),
        nameplate,
        remainder: nameplate.sub(demand),
        served,
        unserved,
        // An absence, not a wide range. The sum above is bounded and the split is not observed
        // at all, so filing either half as a number would be inventing evidence. This is
        // `pm:Holder/share` with `absence_reason = unmeasured` on both halves: it says what kind
        // of loss this is rather than how large.
        unrealised: Unmeasured,
        customer: Unmeasured,
        spilled: Bounded::point(spilled),
        // Nothing in the log says an ask is still waiting, because nothing in the log says an
        // ask arrived.
        pending: Unmeasured,
        undelivered: nameplate.sub(served),
        // No wait is recorded against a demand, so nothing here tells an ask met out of stock
        // from one that queued first, and `absorber` cannot be answered.
        from_stock: Unmeasured,
        after_waiting: Unmeasured,
        // Here the log loses nothing, which is worth knowing as much as where it loses
        // everything. A stock-and-flow log has no notion of overtime: a lot made past the rating
        // is an ordinary success. But it carries every success total, and the rating belongs to
        // the line, so what was made less the nameplate recovers the overtime exactly. Saying
        // which fields come through exact is half of what comparing instruments is for.
        ran_hot: Bounded::point((made - run.settings.nameplate_over(run.window)).max(0.0)),
    }
}

// ---------------------------------------------------------------------------------------------
// Two histories behind one log.
// ---------------------------------------------------------------------------------------------

/// The same history with every turned-away ask rewritten as one that waited and left, and the
/// other way round.
///
/// The result is a second history with the same magnitudes at the same times, a completely
/// different holder split, and the same stock-and-flow log, byte for byte. Two histories behind
/// one log show that the log cannot be traced back to the history, without assuming anything
/// further about the framework.
///
/// Both ends occur in a real line. `window::short_settings` reaches the all-unrealised end and
/// `window::queued_settings` the all-customer end, at the same load and the same seed, so both
/// splits are things a line does. The rewrite only puts them behind the same log.
pub fn relabelled(run: &Run) -> Run {
    let history = run
        .history
        .iter()
        .map(|record| {
            let what = match &record.what {
                Event::Refused { order, size } => Event::Reneged {
                    order: *order,
                    size: *size,
                    // A waited time has to be invented here, and it cannot be observed: the
                    // stock-and-flow log carries no wait on a failure, so nothing downstream can
                    // read it, and nothing downstream may.
                    waited: Duration::ZERO,
                },
                Event::Reneged { order, size, .. } => Event::Refused {
                    order: *order,
                    size: *size,
                },
                other => other.clone(),
            };
            Record { at: record.at, what }
        })
        .collect();

    Run {
        settings: run.settings.clone(),
        seed: run.seed,
        window: run.window,
        history,
    }
}

// ---------------------------------------------------------------------------------------------
// What the history says that no reading does.
// ---------------------------------------------------------------------------------------------

/// Counts of each outcome, for saying how much of the run exercised which branch.
#[derive(Clone, Copy, Debug, Default)]
pub struct Census {
    pub asked: usize,
    pub served: usize,
    pub refused: usize,
    pub reneged: usize,
    pub produced: usize,
    pub ran_hot: usize,
    pub idled: usize,
    pub spilled: usize,
    pub longest_wait: Duration,
}

pub fn census(run: &Run) -> Census {
    let mut c = Census::default();
    for Record { what, .. } in &run.history {
        match what {
            Event::Asked { .. } => c.asked += 1,
            Event::Served { waited, .. } => {
                c.served += 1;
                c.longest_wait = c.longest_wait.max(*waited);
            }
            Event::Refused { .. } => c.refused += 1,
            Event::Reneged { .. } => c.reneged += 1,
            Event::Produced { .. } => c.produced += 1,
            Event::RanHot { .. } => c.ran_hot += 1,
            Event::Idled { .. } => c.idled += 1,
            Event::Spilled { .. } => c.spilled += 1,
        }
    }
    c
}

/// The three buffers as the schema files them, read off the history.
///
/// `capacity` is `notApplicable` rather than zero where the line has no overtime allowance,
/// because then it cannot run hot: no branch in `layer.rs` makes a lot early. That is not a
/// measurement of zero slack but the absence of the buffer. `layers/absorption.sqlc` treats the
/// two the same way only because both mean "no room here", while `unmeasured` means nobody knows.
pub struct Buffers {
    pub inventory_high: f64,
    pub capacity: Option<f64>,
    pub time_high: Duration,
}

impl Buffers {
    /// `None` is `notApplicable`, and zero is a measurement. A line with no overtime allowance
    /// has no room above its rating at all, which is the absence of the buffer rather than an
    /// empty one.
    pub fn from(settings: &Settings) -> Option<f64> {
        if settings.overtime_lots == 0 {
            None
        } else {
            Some(settings.capacity_slack())
        }
    }
}

pub fn buffers(run: &Run, settings: &Settings) -> Buffers {
    let census = census(run);
    Buffers {
        inventory_high: settings.stock_cap,
        capacity: Buffers::from(settings),
        time_high: if settings.patience.is_zero() {
            Duration::ZERO
        } else {
            census.longest_wait
        },
    }
}
