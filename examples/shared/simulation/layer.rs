//! One layer, built on NeXosim: quantized supply meeting demand that arrives when it likes.
//!
//! ⭐⭐⭐ THE THREE BUFFERS ARE THREE FIELDS AND THEY ARE SUBSTITUTES. `stock_cap` is inventory,
//! `over_rate` is capacity, `queue_cap` with `patience` is time. Factory Physics says a shortfall
//! is absorbed by one of the three or it is not absorbed at all, and here that is not a claim, it
//! is the control flow: an ask is met from stock, or met by the line running hot, or made to wait,
//! or it is unserved. There is no fifth branch to write.
//!
//! ⛔ NEXOSIM SUPPLIES THE CLOCK AND NOTHING ELSE. Every decision below about what a shortfall
//! means is made in this file, which is the point: the framework must not be able to agree with
//! this repository, because it was never asked the question.

use std::time::Duration;

use nexosim::model::{Context, Model, schedulable};
use nexosim::ports::Output;
use nexosim::simulation::EventKey;
use nexosim::time::MonotonicTime;
use serde::{Deserialize, Serialize};

use super::event::{Event, Record, Seeded};

/// One demand, as it arrives at the line.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Ask {
    pub order: u64,
    pub size: f64,
    pub patience: Duration,
}

/// Everything that makes one run different from another.
///
/// ⭐ EVERY FIELD IS A ROW, NOT A CONSTANT. `corpus-must-be-perturbable`: a parameter that no
/// gate can observe is a comment, so these are carried into the report and printed beside the
/// verdicts they produced.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Settings {
    /// The quantum. Supply only ever arrives in whole multiples of this.
    pub lot: f64,
    /// One lot per cycle, which with `lot` fixes the nameplate rate.
    pub cycle: Duration,
    /// The inventory buffer: how much finished supply may be held.
    pub stock_cap: f64,
    /// The time buffer: how many asks may wait at once.
    pub queue_cap: usize,
    /// The capacity buffer: how many lots beyond the rating the line may make in a window.
    ///
    /// ⛔ NOT SPARE CAPACITY. This is the room ABOVE the rating, which is what
    /// `Nameplate/capacitySlack` measures and what the idiom points the wrong way about. A line
    /// that idles has plenty of the first and, at zero here, none of the second.
    pub overtime_lots: usize,
    /// How long an ask will wait before leaving. Zero means no time buffer at all.
    pub patience: Duration,
    /// Mean gap between asks, exponentially distributed.
    pub mean_gap: Duration,
    /// Ask sizes are uniform on this interval.
    pub size_low: f64,
    pub size_high: f64,
    /// Whether the nameplate is cut down to a whole number of lots.
    pub floor_nameplate: bool,
    /// Whether an ask is for a whole number of units.
    ///
    /// ⭐ IT MATTERS ONLY WHERE THE SUPPLY IS FILLED IN WHOLE LOTS. A continuous stock serves
    /// 4.37 as readily as 4, and the lot size then constrains only the total. Ask for whole units
    /// against whole lots and the arithmetic stops being about totals and starts being about
    /// which numbers are reachable at all.
    pub integral_asks: bool,
}

impl Settings {
    /// The nameplate over a window: lots per unit time times the lot size.
    ///
    /// ⛔⛔⛔ THE `floor` IS NOT ROUNDING, IT IS A RULE OF THE SCHEMA SHOWING UP IN THE PHYSICS.
    /// `nameplate_not_a_multiple` requires the nameplate to be a whole multiple of the quantum,
    /// so a window that is not a whole number of cycles cannot be filed honestly. Flooring makes
    /// the filing legal and understates the line by up to one lot per window; not flooring is
    /// honest over a run of windows and is rejected. `floored` is which of the two this run files.
    pub fn nameplate_over(&self, window: Duration) -> f64 {
        let cycles = window.as_secs_f64() / self.cycle.as_secs_f64();
        let cycles = if self.floor_nameplate { cycles.floor() } else { cycles };
        cycles * self.lot
    }

    /// How far the line can run above that rating, in the same unit.
    pub fn capacity_slack(&self) -> f64 {
        self.overtime_lots as f64 * self.lot
    }
}

// ---------------------------------------------------------------------------------------------
// The demand side.
// ---------------------------------------------------------------------------------------------

/// Asks arriving on their own schedule, indifferent to whether the line can meet them.
#[derive(Serialize, Deserialize)]
pub struct Arrivals {
    settings: Settings,
    rng: Seeded,
    next_order: u64,
    /// Out to the line.
    pub ask: Output<Ask>,
}

#[Model]
impl Arrivals {
    pub fn new(settings: Settings, seed: u64) -> Self {
        Self {
            settings,
            rng: Seeded::new(seed),
            next_order: 0,
            ask: Output::default(),
        }
    }

    /// Places the first ask, after which each one schedules the next.
    #[nexosim(init)]
    async fn init(&mut self, cx: &Context<Self>) {
        self.arrive(cx).await;
    }

    /// Emits one ask and books the following one.
    #[nexosim(schedulable)]
    async fn tick(&mut self, _: (), cx: &Context<Self>) {
        self.arrive(cx).await;
    }

    async fn arrive(&mut self, cx: &Context<Self>) {
        let order = self.next_order;
        self.next_order += 1;

        let mut size = self.rng.between(self.settings.size_low, self.settings.size_high);
        if self.settings.integral_asks {
            size = size.round().max(1.0);
        }
        let ask = Ask {
            order,
            size,
            patience: self.settings.patience,
        };
        self.ask.send(ask).await;

        let gap = self.rng.after(self.settings.mean_gap);
        // ⛔ A zero gap would schedule at the current time, which NeXosim refuses. Floor it at a
        // tick so a pathological draw cannot silently stop the arrival stream.
        let gap = gap.max(Duration::from_millis(1));
        let _ = cx.schedule_event(gap, schedulable!(Self::tick), ());
    }
}

// ---------------------------------------------------------------------------------------------
// The supply side.
// ---------------------------------------------------------------------------------------------

/// An ask that is waiting, with the cancellation handle for its patience running out.
#[derive(Serialize, Deserialize)]
struct Waiting {
    order: u64,
    size: f64,
    since: MonotonicTime,
    give_up: Option<EventKey>,
}

/// The line: produces in lots, holds stock, lets asks wait, and turns the rest away.
#[derive(Serialize, Deserialize)]
pub struct Line {
    settings: Settings,
    stock: f64,
    hot_lots: usize,
    queue: Vec<Waiting>,
    /// Out to whoever is watching. ⭐ THE LINE DOES NOT KEEP ITS OWN TOTALS: everything a report
    /// wants is derived from this stream, so no fold is privileged by living inside the physics.
    pub log: Output<Record>,
}

#[Model]
impl Line {
    pub fn new(settings: Settings) -> Self {
        Self {
            settings,
            stock: 0.0,
            hot_lots: 0,
            queue: Vec::new(),
            log: Output::default(),
        }
    }

    /// Books the first lot. Production is periodic and never stops, which is what makes the
    /// nameplate a rate rather than a decision.
    #[nexosim(init)]
    async fn init(&mut self, cx: &Context<Self>) {
        let cycle = self.settings.cycle;
        let _ = cx.schedule_periodic_event(cycle, cycle, schedulable!(Self::produce), ());
    }

    /// An ask arrives.
    pub async fn ask(&mut self, ask: Ask, cx: &Context<Self>) {
        self.say(
            cx,
            Event::Asked {
                order: ask.order,
                size: ask.size,
                patience: ask.patience,
            },
        )
        .await;

        // 1. The inventory buffer.
        if self.stock + 1e-9 >= ask.size {
            self.stock -= ask.size;
            self.say(
                cx,
                Event::Served {
                    order: ask.order,
                    size: ask.size,
                    waited: Duration::ZERO,
                },
            )
            .await;
            return;
        }

        // 2. The time buffer. ⛔ Zero patience is not a queue of length zero: it is a queue that
        //    empties in the same instant, and NeXosim will not schedule at the current time. Both
        //    read as "no time buffer", so they take the same branch.
        if self.queue.len() < self.settings.queue_cap && !self.settings.patience.is_zero() {
            let give_up = cx
                .schedule_keyed_event(ask.patience, schedulable!(Self::give_up), ask.order)
                .ok();
            self.queue.push(Waiting {
                order: ask.order,
                size: ask.size,
                since: cx.time(),
                give_up,
            });
            return;
        }

        // 3. The capacity buffer. ⭐⭐ THE ORDER OF THE THREE IS A POLICY AND NOT A LAW. Factory
        //    Physics says they substitute; which one a shop reaches for first is a decision, and
        //    this line goes to overtime only once the backlog will not take another order.
        if self.hot_lots < self.settings.overtime_lots {
            self.hot_lots += 1;
            let lot = self.settings.lot;
            self.say(cx, Event::RanHot { lot }).await;
            let mut available = self.stock + lot;
            if available + 1e-9 >= ask.size {
                available -= ask.size;
                self.stock = available.min(self.settings.stock_cap);
                self.say(
                    cx,
                    Event::Served {
                        order: ask.order,
                        size: ask.size,
                        waited: Duration::ZERO,
                    },
                )
                .await;
                return;
            }
            self.stock = available.min(self.settings.stock_cap);
        }

        // 4. Nowhere to put it. Turned away at the door, so nobody ever experienced it.
        self.say(
            cx,
            Event::Refused {
                order: ask.order,
                size: ask.size,
            },
        )
        .await;
    }

    /// A lot comes off the line, unless there is nowhere to put it.
    #[nexosim(schedulable)]
    async fn produce(&mut self, _: (), cx: &Context<Self>) {
        let lot = self.settings.lot;

        // ⛔ A LINE DOES NOT MAKE WHAT IT CANNOT HOLD, and modelling one that does puts a fifth
        //   outcome in the history that the five holders have no home for. Idling instead leaves
        //   the whole difference between the rating and the run as one thing: unused capacity,
        //   which the schema files as a `clearance` remainder absorbed by `capacity`.
        if self.queue.is_empty() && self.stock + lot > self.settings.stock_cap + 1e-9 {
            self.say(cx, Event::Idled { lot }).await;
            return;
        }

        self.say(cx, Event::Produced { lot }).await;

        let mut available = self.stock + lot;

        // Serve the waiting, oldest first, while whole asks can be met.
        while let Some(head) = self.queue.first() {
            if available + 1e-9 < head.size {
                break;
            }
            let head = self.queue.remove(0);
            available -= head.size;
            if let Some(key) = head.give_up {
                key.cancel();
            }
            let waited = cx.time().duration_since(head.since);
            self.say(
                cx,
                Event::Served {
                    order: head.order,
                    size: head.size,
                    waited,
                },
            )
            .await;
        }

        // What is left goes to stock, and what will not fit is gone.
        self.stock = available.min(self.settings.stock_cap);
        let spilled = available - self.stock;
        if spilled > 1e-9 {
            self.say(cx, Event::Spilled { amount: spilled }).await;
        }
    }

    /// An ask ran out of patience.
    #[nexosim(schedulable)]
    async fn give_up(&mut self, order: u64, cx: &Context<Self>) {
        let Some(at) = self.queue.iter().position(|w| w.order == order) else {
            return;
        };
        let gone = self.queue.remove(at);
        let waited = cx.time().duration_since(gone.since);
        self.say(
            cx,
            Event::Reneged {
                order: gone.order,
                size: gone.size,
                waited,
            },
        )
        .await;
    }

    async fn say(&mut self, cx: &Context<Self>, what: Event) {
        let at = cx.time().duration_since(MonotonicTime::EPOCH);
        self.log.send(Record { at, what }).await;
    }
}
