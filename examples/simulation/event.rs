//! The history: what actually happened, at full resolution.
//!
//! ⭐⭐ EVERY VARIANT HERE IS SOMETHING NO FILING CAN CONTAIN. A filing carries totals over a
//! window; this carries the events those totals are a fold of. The point of writing it out is
//! that the fold is then a function you can read, and the things it drops are visible as the
//! fields no longer mentioned on the other side.

use std::time::Duration;

use serde::{Deserialize, Serialize};

/// One thing that happened, and when.
#[derive(Clone, Debug, PartialEq)]
pub struct Record {
    pub at: Duration,
    pub what: Event,
}

/// ⛔ THE FIVE UNSERVED-OR-NOT OUTCOMES ARE DELIBERATELY SEPARATE VARIANTS. `Refused` and
/// `Reneged` are the same magnitude of shortfall and different `pm:HolderKind`s, and keeping
/// them apart here is what lets `instrument.rs` demonstrate an instrument collapsing them.
#[derive(Clone, Debug, PartialEq)]
pub enum Event {
    /// Somebody asked for `size` and is prepared to wait `patience`.
    Asked {
        order: u64,
        size: f64,
        patience: Duration,
    },
    /// The ask was met, after waiting `waited`.
    Served {
        order: u64,
        size: f64,
        waited: Duration,
    },
    /// The ask was turned away at the door, because the queue had no room. It never became
    /// anybody's experience, which is `pm:HolderKind` **unrealised**.
    Refused { order: u64, size: f64 },
    /// The ask was accepted, waited past its patience, and left. Somebody experienced this,
    /// which is `pm:HolderKind` **customer**.
    Reneged {
        order: u64,
        size: f64,
        waited: Duration,
    },
    /// A whole lot came off the line. ⭐ THE QUANTUM IS HERE: supply arrives in lots and demand
    /// arrives in arbitrary sizes, and `r = n − d` is the difference that fact creates.
    Produced { lot: f64 },
    /// A lot was pulled forward and made inside a cycle rather than at its end.
    ///
    /// ⭐⭐⭐ THE THIRD BUFFER, AND WITHOUT IT THE BENCH CANNOT SHOW THE ONE THING THE MODEL IS
    /// ABOUT. Factory Physics says a shortfall is absorbed by inventory, by capacity or by time,
    /// AS SUBSTITUTES. A line with only two of the three can never demonstrate a substitution,
    /// and two rules in `assets/sql/checks/` had no population anywhere in the corpus for exactly
    /// this reason: nothing had ever filed a sized `capacitySlack`.
    RanHot { lot: f64 },
    /// A lot was not started, because the stock was full and nobody was waiting.
    ///
    /// ⭐⭐⭐ THIS IS THE CLEARANCE, AND THE SCHEMA IS EXPLICIT THAT IT IS NOT A SLACK. Idle
    /// capacity IS the capacity buffer, and `Nameplate/capacitySlack` measures the opposite end,
    /// the room ABOVE the rating. A line that runs below its rating is filing a positive
    /// remainder absorbed by `capacity`, not a capacity slack, and the two are half an axis apart.
    Idled { lot: f64 },
    /// A lot was made with nowhere to hold it. ⛔ UNREACHABLE WHILE THE LINE IDLES, and kept
    /// because a continuous process that cannot stop is a real thing and would produce it.
    Spilled { amount: f64 },
}


/// A deterministic source of variation, so that a run is a function of its seed.
///
/// ⛔ NOT A LIBRARY, ON PURPOSE. `tests/independence.rs` allowlists every dependency and each
/// name is a route by which somebody else's types arrive. Twelve lines of arithmetic is a
/// smaller thing to own than an entry on that list.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Seeded(u64);

impl Seeded {
    pub fn new(seed: u64) -> Self {
        // Any non-zero start; the constant is Knuth's.
        Seeded(seed.wrapping_mul(6364136223846793005).wrapping_add(1) | 1)
    }

    /// Uniform on `[0, 1)`.
    pub fn unit(&mut self) -> f64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        (self.0 >> 11) as f64 / (1u64 << 53) as f64
    }

    /// Uniform on `[low, high)`.
    pub fn between(&mut self, low: f64, high: f64) -> f64 {
        low + self.unit() * (high - low)
    }

    /// An exponential inter-arrival time with the given mean, so arrivals are Poisson.
    pub fn after(&mut self, mean: Duration) -> Duration {
        let u = self.unit().max(1e-12);
        Duration::from_secs_f64(mean.as_secs_f64() * -u.ln())
    }
}
