//! What a supply with more than one lot size can and cannot fill exactly.
//!
//! `pm:Remainder`'s annotation describes a lumpy supply with one lot size, whose nameplate is a
//! whole number of lots: there the residue never goes away, and every demand leaves the same one
//! each time it comes round. A supply with two lot sizes behaves differently. Some demands it can
//! meet with nothing left over, and above a certain size it can meet every demand exactly, so the
//! residue stops. One shop, described both ways, either carries the cost of whole units for ever
//! or stops carrying it past a size it can name.
//!
//! For two lot sizes with no common factor, `sylvester` gives the largest demand that cannot be
//! met exactly, and how many demands cannot. The sieve in `Fillable::new` finds both again, so
//! neither is taken on trust.

/// The set of demands a supply with these lot sizes can fill with nothing left over.
pub struct Fillable {
    pub generators: Vec<u64>,
    /// `in_semigroup[s]` is true where a demand of exactly `s` can be met by whole lots.
    in_semigroup: Vec<bool>,
}

impl Fillable {
    /// Marks every demand up to `ceiling` that whole lots can meet exactly. The ceiling must be
    /// comfortably past the largest demand that cannot be met.
    pub fn new(generators: Vec<u64>, ceiling: usize) -> Self {
        let mut reachable = vec![false; ceiling + 1];
        reachable[0] = true;
        for value in 1..=ceiling {
            for g in &generators {
                let g = *g as usize;
                if g <= value && reachable[value - g] {
                    reachable[value] = true;
                    break;
                }
            }
        }
        Fillable {
            generators,
            in_semigroup: reachable,
        }
    }

    pub fn fills_exactly(&self, demand: u64) -> bool {
        self.in_semigroup
            .get(demand as usize)
            .copied()
            .unwrap_or(true)
    }

    /// Every demand below the ceiling that no combination of lots can meet exactly.
    pub fn gaps(&self) -> Vec<u64> {
        (1..self.in_semigroup.len())
            .filter(|s| !self.in_semigroup[*s])
            .map(|s| s as u64)
            .collect()
    }

    /// The largest demand that cannot be met exactly. `None` where a lot size is 1.
    pub fn frobenius(&self) -> Option<u64> {
        self.gaps().last().copied()
    }

    /// The smallest overshoot. A shop that will not leave a customer short ships the next amount
    /// up that whole lots can make, and the difference is supply nobody asked for. It is zero
    /// exactly where the demand can be met, which is why the gaps are the thing to look at.
    pub fn overshoot(&self, demand: u64) -> u64 {
        let mut up = demand;
        while !self.fills_exactly(up) {
            up += 1;
        }
        up - demand
    }

    /// The largest demand that cannot be met exactly, and how many cannot, for two lot sizes with
    /// no common factor.
    pub fn sylvester(&self) -> Option<(u64, u64)> {
        if self.generators.len() != 2 {
            return None;
        }
        let (a, b) = (self.generators[0], self.generators[1]);
        if gcd(a, b) != 1 {
            return None;
        }
        Some((a * b - a - b, (a - 1) * (b - 1) / 2))
    }
}

pub fn gcd(a: u64, b: u64) -> u64 {
    if b == 0 { a } else { gcd(b, a % b) }
}
