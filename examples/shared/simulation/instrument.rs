//! Two instruments over one history, and what each of them is able to say.
//!
//! ⭐⭐⭐ AN INSTRUMENT IS A FUNCTION FROM HISTORIES TO READINGS, AND IT IS NOT INJECTIVE.
//! [`Instrument::Whole`] sees every field of every event. [`Instrument::StockAndFlow`] sees what a
//! stock-and-flow event log records, which is less: a refusal without its magnitude, and no way to
//! tell a demand that was turned away from one that waited and left. Many histories give the same
//! stock-and-flow reading, so that reading names a **set of histories** rather than one.
//!
//! ⛔⛔ THE SET IS WHY THE ANSWER IS A RANGE. There is no inverse to recover the history from the
//! log, and a right inverse would be a **choice** rather than a reconstruction, so the honest
//! report of the pre-image is its extent. `pm:Narrowing/kind = instrument` is exactly this case and
//! is distinguished from `intervention` for exactly this reason: re-running never narrows it,
//! because the width was made by the projection and not by the world.
//!
//! ⭐⭐ AND THE TWO LOSSES ARE DIFFERENT SPECIES. Dropping a magnitude WIDENS a bound and keeps the
//! truth inside it. Collapsing two `pm:HolderKind`s into one row pins their SUM and leaves the
//! split free, which is not a wider interval at all: it is a face of the holder simplex. Only the
//! first is a number; the second has to be filed as an absence.

use std::time::Duration;

use super::event::{Event, Record};
use super::layer::Settings;
use super::window::Run;

// ---------------------------------------------------------------------------------------------
// What a reading is allowed to be.
// ---------------------------------------------------------------------------------------------

/// A magnitude as an instrument is able to report it.
///
/// ⭐ THE THIRD VARIANT IS NOT A WIDE RANGE. `pm:absent/reason = unmeasured` says nobody looked
/// or nobody could; a range says somebody looked and this is how well. Collapsing the two would
/// let an unbounded guess pass for a measurement.
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

    /// The width of the pre-image in this coordinate. `None` where nothing was measured.
    pub fn width(&self) -> Option<f64> {
        match self {
            Range { low, high } => Some(high - low),
            Unmeasured => None,
        }
    }

    /// ⛔ CONTAINMENT IS THE WHOLE CLAIM, AND IT IS ONE-DIRECTIONAL. The lossy reading must
    /// admit the true one. Equality is not available and is not wanted: an instrument that
    /// returned the truth exactly would not have lost anything, and this one did.
    pub fn admits(&self, truth: &Bounded) -> bool {
        match (self, truth) {
            // Nothing was claimed, so nothing is contradicted.
            (Unmeasured, _) => true,
            // Something was claimed about a quantity the truth does not pin. Vacuous here,
            // because the whole instrument never returns `Unmeasured`.
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

    /// ⛔ THE BOUNDS SWAP. `[a,b] − [c,d] = [a−d, b−c]`, and writing `[a−c, b−d]` produces an
    /// interval that looks right, is narrower than the truth, and fails containment only on the
    /// runs where it matters.
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
/// ⭐ THE FIELD NAMES ARE THE SCHEMA'S. `demand`, `nameplate` and `remainder` are `d`, `n` and
/// `r = n − d`; the last four are four of the five `pm:HolderKind`s. Nothing is renamed on the way
/// in, so a disagreement between two instruments is a disagreement about a filed field.
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
    /// ⭐⭐ THE TWO WINDOW-BOUNDARY TERMS, WHICH ONLY EXIST BECAUSE A FILING IS OVER A PERIOD.
    /// `pending` is demand that had arrived and was still waiting when the window closed, so it
    /// is neither served nor unserved and no holder bears it yet. `undelivered` is rating that
    /// was never converted into anything a customer could take. Both fall out of `r = n - d`
    /// arithmetic and neither has a `pm:HolderKind`, which is why they are reported here rather
    /// than folded silently into one of the five.
    pub pending: Bounded,
    pub undelivered: Bounded,
    /// ⭐⭐ WHICH BUFFER DID THE ABSORBING, WHICH IS A SEPARATE AXIS FROM WHO BORE IT. Of what was
    /// served, how much came straight out of stock and how much only after a wait. A
    /// stock-and-flow log records no wait against a demand, so it knows neither, and
    /// `Remainder/absorber` has to be filed absent rather than guessed at.
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
/// ⭐⭐ THIS IS THE ONLY PLACE A BOUND CAN COME FROM AND IT IS NOT IN THE LOG. A `pm:Claim`
/// carries a `pm:provenance` for exactly this reason: a range over unrecorded magnitudes is
/// somebody's stipulation, and if nobody will make it the field is `unmeasured` rather than zero.
#[derive(Clone, Copy, Debug)]
pub struct DeclaredAskSize {
    pub low: f64,
    pub high: f64,
}

impl Instrument {
    /// Folds a run into a reading.
    pub fn read(&self, run: &Run, declared: Option<DeclaredAskSize>) -> Reading {
        match self {
            Instrument::Whole => whole(run),
            Instrument::StockAndFlow => stock_and_flow(run, declared),
        }
    }
}

/// The truth, which is a point in every coordinate.
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

    // ⭐⭐ THE RATING, NOT THE RUN. `nameplate` is what the line is able to make, which is fixed
    //    by the lot and the cycle before anything happens. What it actually made is `made`, and
    //    it is smaller whenever the line idled. Summing the lots here would make the nameplate a
    //    function of the demand it met, which erases the clearance the model exists to name.
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

/// ⛔⛔ THE PROJECTION. Three lines of it destroy information and each one is a finding somebody
/// can go and check against a real stock-and-flow framework.
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
            // ⭐ A LOT MADE ABOVE THE RATING IS AN ORDINARY SUCCESS IN THE LOG, and that is the
            //   finding: a stock-and-flow log records that the lot was made and carries nothing
            //   to say it was made in overtime. The total is right and the buffer is invisible.
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
    // ⭐ THE RATING SURVIVES THE PROJECTION INTACT, which is why it is the one number both
    //   instruments agree on exactly. A stock-and-flow log carries `max_capacity` and the cycle,
    //   and neither depends on what the run happened to do.
    let nameplate = Bounded::point(run.settings.nameplate_over(run.window));
    let demand = served.add(unserved);

    Reading {
        demand,
        made: Bounded::point(made),
        nameplate,
        remainder: nameplate.sub(demand),
        served,
        unserved,
        // ⭐⭐⭐ NOT A WIDE RANGE, AN ABSENCE. The sum above is bounded and the split is not
        // observed at all, so filing either half as a number would be inventing evidence. This
        // is `pm:Holder/share` with `absence_reason = unmeasured` on both halves, and it is the
        // shape of the loss rather than its size.
        unrealised: Unmeasured,
        customer: Unmeasured,
        spilled: Bounded::point(spilled),
        // Nothing in the log says an ask is still waiting, because nothing in the log says an
        // ask arrived.
        pending: Unmeasured,
        undelivered: nameplate.sub(served),
        // ⛔ NO WAIT IS RECORDED AGAINST A DEMAND, so there is nothing here to tell an ask met
        //   out of stock from one that queued first, and `absorber` is not answerable.
        from_stock: Unmeasured,
        after_waiting: Unmeasured,
        // ⭐⭐⭐ AND HERE THE PROJECTION LOSES NOTHING, WHICH IS WORTH AS MUCH AS THE PLACES IT
        //    LOSES EVERYTHING. A stock-and-flow log has no concept of overtime: a lot made past
        //    the rating is an ordinary success like any other. But it carries every success
        //    total and the rating is a property of the line, so `made - nameplate` recovers the
        //    overtime exactly. A fibre can be a single point, and saying which coordinates those
        //    are is half of what the instrument comparison is for.
        ran_hot: Bounded::point((made - run.settings.nameplate_over(run.window)).max(0.0)),
    }
}

// ---------------------------------------------------------------------------------------------
// Exhibiting the fibre.
// ---------------------------------------------------------------------------------------------

/// The same history with every turned-away ask rewritten as one that waited and left, and the
/// other way round.
///
/// ⭐⭐⭐ THIS IS THE PROOF, AND IT IS AN EXHIBITION RATHER THAN AN ARGUMENT. The result is a
/// second history with the same magnitudes at the same times, a completely different holder
/// split, and a byte-identical stock-and-flow log. Two things in one pre-image is the definition
/// of a map that does not come back, so nothing further needs to be assumed about the framework:
/// the projection is not injective and here are the two points.
///
/// ⛔ AND BOTH ENDS ARE REACHABLE, WHICH IS THE OBJECTION THIS ANSWERS. A critic could say the
/// rewritten history is a fiction that no line would produce. `window::short_settings` reaches
/// the all-unrealised end and `window::queued_settings` reaches the all-customer end, at the same
/// load and the same seed, so both splits are things a line does. The rewrite only puts them at
/// the same log.
pub fn relabelled(run: &Run) -> Run {
    let history = run
        .history
        .iter()
        .map(|record| {
            let what = match &record.what {
                Event::Refused { order, size } => Event::Reneged {
                    order: *order,
                    size: *size,
                    // ⚠️ A waited time has to be invented here and it is NOT observable: the
                    // stock-and-flow log carries no wait on a failure, so nothing downstream can
                    // read this and nothing downstream may.
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
/// ⭐⭐ `capacity` IS `notApplicable` RATHER THAN ZERO, AND THE DIFFERENCE IS THE WHOLE TYPED
/// ABSENCE ARGUMENT. This line cannot run hot: there is no branch in `layer.rs` that makes a lot
/// early. That is not a measurement of zero slack, it is the absence of the buffer, and
/// `layers/absorption.sqlc` treats the two the same way only because both mean "no room here",
/// while `unmeasured` means nobody knows.
pub struct Buffers {
    pub inventory_high: f64,
    pub capacity: Option<f64>,
    pub time_high: Duration,
}

impl Buffers {
    /// ⭐ `None` IS `notApplicable` AND ZERO IS A MEASUREMENT. A line with no overtime allowance
    /// has no room above its rating at all, which is the absence of the buffer rather than an
    /// empty one, and `layers/absorption.sqlc` counts the two the same way for one reason only:
    /// both mean there is no room here. `unmeasured` would mean nobody knows.
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
