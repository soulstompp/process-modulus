//! The history: what actually happened, at full resolution.
//!
//! Every variant here is something no filing can contain. A filing carries totals over a window;
//! this carries the events those totals are added up from. Written out, the adding up is a
//! function you can read, and what it drops shows as the fields no longer mentioned on the other
//! side.

use std::time::Duration;

use serde::{Deserialize, Serialize};

/// One thing that happened, and when.
#[derive(Clone, Debug, PartialEq)]
pub struct Record {
    pub at: Duration,
    pub what: Event,
}

/// The outcomes are separate variants on purpose. `Refused` and `Reneged` are the same size of
/// shortfall and different `pm:HolderKind`s, and keeping them apart here is what lets
/// `instrument.rs` show an instrument merging them.
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
    /// A whole lot came off the line. This is the quantum: supply arrives in lots and demand
    /// arrives in any size, and the remainder between them comes from that.
    Produced { lot: f64 },
    /// A lot was pulled forward and made inside a cycle rather than at its end.
    ///
    /// The third buffer, without which the bench cannot show what the model is about. Factory
    /// Physics says a shortfall is absorbed by inventory, by capacity or by time, each able to
    /// stand in for another. A line with only two of the three can never show one standing in,
    /// and only a line that runs above its rating files a sized `capacitySlack` for the rules in
    /// `assets/sql/checks/` to read.
    RanHot { lot: f64 },
    /// A lot was not started, because the stock was full and nobody was waiting.
    ///
    /// This is the clearance, and the schema says it is not a slack. Idle capacity is the
    /// capacity buffer, and `Nameplate/capacitySlack` measures the other end, the room above the
    /// rating. A line that runs below its rating files a positive remainder absorbed by
    /// `capacity`, not a capacity slack.
    Idled { lot: f64 },
    /// A lot was made with nowhere to hold it. It cannot happen while the line idles, and it is
    /// kept because a continuous process that cannot stop is real and would produce it.
    Spilled { amount: f64 },
}


/// A deterministic source of variation, so that a run is a function of its seed.
///
/// Not a library, on purpose. `tests/independence.rs` allowlists every dependency, and each name
/// on it is a route by which somebody else's types arrive. A few lines of arithmetic are a smaller
/// thing to own than an entry on that list.
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
