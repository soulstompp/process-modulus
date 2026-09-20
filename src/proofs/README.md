The equations this model states, each shown to hold by a program that `cargo test` runs.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

## What this page is for

The schemas define every quantity a filing carries, and the queries in `assets/sqlc/` compute what
those definitions imply. Somewhere between the two, an equation gets written down: the remainder is
the nameplate less the demand, the exposure is the largest demand against the smallest supply. This
page is where each of those equations is shown to hold, on documents you can open, by code that runs
on every build.

Other documents in this repository point here rather than restating an equation. The schemas keep
their normative definitions.

## How an entry is built

Each entry has four parts.

1. **The statement**, in a `text` block, with the names the schema and the queries use.
2. **What it means** for a filing, with worked figures from real documents.
3. **A Rust block** that reads those documents with this crate's own types and asserts every figure
   the entry mentions. `cargo test --doc` compiles and runs it.
4. **Where the database holds it**: the law on `assets/sqlc/algebra/roster.sqlc` that recomputes
   the same figure for every document loaded, and the rule on `assets/sqlc/checks/roster.sqlc`
   that accuses a filing contradicting it. `cargo run --example soundness` runs every law.

A block and a law prove different halves. The block shows what the equation means on one filing a
reader can check by hand; the law shows the database computes the same thing for all of them.

### The shared file

Every block begins with the same line:

```text
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));
```

`support.rs`, beside this page, loads documents and reads figures out of them, one function per
figure. It does no arithmetic apart from the 1e-9 tolerance `close` and `close3` compare within,
which is the tolerance the queries use. Every subtraction, bound and magnitude a proof relies on
is written in the block itself.

### Grids

Where an entry claims something of every possible claim, not only of the filed ones, its block
checks every ordered claim on a small grid of whole numbers. Whole numbers are exact in floating
point, so those comparisons need no tolerance.

## 1. The remainder and its fit

### The crossed subtraction

```text
r = n - d = [n_low - d_high,  n_mode - d_mode,  n_high - d_low]
```

The remainder's lowest value pairs the least supply with the most demand, and its highest pairs the
most supply with the least demand. Subtracting bound by bound instead describes one week twice: its
low would pair the good week's supply with the good week's demand. The crossed pairing always gives
an ordered claim; bound by bound does not.

`refutation`'s `compute` layer states a demand of [11.0, 13.2, 16.4] GPU against a nameplate of
[16.0, 16.0, 16.0], so `r` is [-0.4, 2.8, 5.0]: short at the top of the demand range and spare at
the bottom. `enterprise-contract`'s `labour` layer states [4.5, 5.2, 6.0] people against
[4.0, 4.0, 4.0], so `r` is [-2.0, -1.2, -0.5], short throughout. A capacity of [9, 10, 11] against
a demand of [8, 12, 15] nets to [-6, -2, 3]; bound by bound it would be [1, -2, -4], whose low
exceeds its high.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // n - d with its bounds crossed.
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    assert!(close3(demand(compute), (11.0, 13.2, 16.4)));
    assert!(close3(nameplate(compute), (16.0, 16.0, 16.0)));
    assert!(close3(crossed(nameplate(compute), demand(compute)), (-0.4, 2.8, 5.0)));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    assert!(close3(demand(labour), (4.5, 5.2, 6.0)));
    assert!(close3(nameplate(labour), (4.0, 4.0, 4.0)));
    assert!(close3(crossed(nameplate(labour), demand(labour)), (-2.0, -1.2, -0.5)));

    let (capacity, need) = ((9.0, 10.0, 11.0), (8.0, 12.0, 15.0));
    assert!(close3(crossed(capacity, need), (-6.0, -2.0, 3.0)));
    let bound_by_bound = (capacity.0 - need.0, capacity.1 - need.1, capacity.2 - need.2);
    assert!(close3(bound_by_bound, (1.0, -2.0, -4.0)));
    assert!(bound_by_bound.0 > bound_by_bound.2);

    // Every ordered nameplate against every ordered demand, on a grid of whole numbers: the
    // crossed pairing is ordered every time.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &n in &claims {
        for &d in &claims {
            let r = crossed(n, d);
            assert!(r.0 <= r.1 && r.1 <= r.2);
        }
    }
}
```

**Entry** `crossed_subtraction` · **Law** `algebra/crossed_remainder`

### The magnitude

```text
|r| = [0 if r_low <= 0 <= r_high, else min(|r_low|, |r_high|),  |r_mode|,  max(|r_low|, |r_high|)]
    = [max(r_low, -r_high, 0),  |r_mode|,  max(r_high, -r_low)]
```

The magnitude is how much remainder there is, whichever side of the nameplate it falls on. The
absolute value is not monotone across zero, so where `r` straddles zero the smallest magnitude is
0, not the smaller of the two ends' magnitudes. A stated `quantity` is this figure, and so is the
sum of a remainder's holder shares. The first line is how `layers/remainder.sqlc` computes it; the
second is how `algebra/crossed_remainder.sqlc` checks it, and the two agree on every ordered `r`.

For `refutation`'s `compute`, `r` = [-0.4, 2.8, 5.0] gives `|r|` = [0.0, 2.8, 5.0], which is the
`quantity` that filing states. The smaller end's magnitude would put a floor of 0.4 under a
remainder that reaches zero. For `labour`, [-2.0, -1.2, -0.5] gives [0.5, 1.2, 2.0].
`enterprise-contract`'s `support-cover` states a demand of [92, 118, 147] engineer-hours a week
against a nameplate of 168, a clearance whose magnitude is `r` itself, [21, 50, 76], and its one
holder's share is that figure.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    // By cases, on whether r straddles zero.
    let by_cases = |r: Triple| {
        let low = if r.0 <= 0.0 && r.2 >= 0.0 { 0.0 } else { r.0.abs().min(r.2.abs()) };
        (low, r.1.abs(), r.0.abs().max(r.2.abs()))
    };
    // In closed form.
    let closed = |r: Triple| (r.0.max(-r.2).max(0.0), r.1.abs(), r.2.max(-r.0));

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let r = crossed(nameplate(compute), demand(compute));
    assert!(close3(by_cases(r), (0.0, 2.8, 5.0)));
    assert!(close3(closed(r), (0.0, 2.8, 5.0)));
    assert!(close3(quantity(compute).expect("refutation states this quantity"), (0.0, 2.8, 5.0)));
    assert!(close(r.0.abs().min(r.2.abs()), 0.4));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    let r = crossed(nameplate(labour), demand(labour));
    assert!(close3(by_cases(r), (0.5, 1.2, 2.0)));
    assert!(close3(closed(r), (0.5, 1.2, 2.0)));

    let cover = layer(&contract, "support-cover");
    assert!(close3(demand(cover), (92.0, 118.0, 147.0)));
    assert!(close3(nameplate(cover), (168.0, 168.0, 168.0)));
    let r = crossed(nameplate(cover), demand(cover));
    assert!(close3(r, (21.0, 50.0, 76.0)));
    assert!(close3(by_cases(r), r));
    let held = shares(cover);
    assert_eq!(held.len(), 1);
    assert!(close3(held[0].expect("the share is stated"), by_cases(r)));

    // Every ordered r on a grid of whole numbers either side of zero: the two forms agree, and
    // the magnitude is itself ordered.
    for low in -6..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                let r = (low as f64, mode as f64, high as f64);
                let m = by_cases(r);
                assert_eq!(m, closed(r));
                assert!(m.0 <= m.1 && m.1 <= m.2);
            }
        }
    }
}
```

**Entry** `magnitude` · **Law** `algebra/crossed_remainder` · **Rule**
`checks/stated_quantity_is_not_the_magnitude`, `checks/shares_do_not_sum`

### The fit criteria

```text
clearance     r_low >= 0             n_low >= d_high    supply exceeds demand across the whole range
interference  r_high <= 0            n_high <= d_low    demand exceeds supply across the whole range
transition    r_low < 0 < r_high                        the ranges overlap
```

The fit compares two ranges, not two points: ISO 286's criterion for a hole and a shaft, borrowed
intact. Every pair of ordered claims meets at least one criterion. Exactly one kind of pair meets
two: a point nameplate equal to a point demand, where `r` is [0, 0, 0] and `clearance` and
`interference` both hold, since chaining the two forces every bound equal. The overlap comes with
the criterion. ISO 286-1:1988 defines both fits with "in the extreme case, equal to", in clauses
4.10.1 and 4.10.2, and never has to choose, because its tolerances always have width.
`layers/remainder.sqlc` tests `clearance` first, so that pair reads as `clearance`: the model's
tie-break, extending ISO's line-to-line clearance, and the reading under which nothing went unmet.

The corpus's filed fits read the same way. `refutation`'s `compute` overlaps and is filed
`transition`; `enterprise-contract`'s `labour` sits wholly below its demand and is filed
`interference`; its `compute`, [3.1, 4.4, 6.0] GPU against 8, clears and is filed `clearance`.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // The arms of layers/remainder.sqlc, in its order.
    let derived = |r_low: f64, r_high: f64| {
        if r_low >= 0.0 {
            "clearance"
        } else if r_high <= 0.0 {
            "interference"
        } else {
            "transition"
        }
    };

    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let mut overlaps = 0;
    for &n in &claims {
        for &d in &claims {
            let (r_low, r_high) = (n.0 - d.2, n.2 - d.0);
            let clearance = r_low >= 0.0;
            let interference = r_high <= 0.0;
            let transition = r_low < 0.0 && r_high > 0.0;
            let met = [clearance, interference, transition].iter().filter(|&&c| c).count();
            assert!(met >= 1);
            if met == 1 {
                let only = if clearance {
                    "clearance"
                } else if interference {
                    "interference"
                } else {
                    "transition"
                };
                assert_eq!(derived(r_low, r_high), only);
            } else {
                assert!(clearance && interference && !transition);
                assert!(n.0 == n.2 && d.0 == d.2 && n.0 == d.0);
                assert_eq!(derived(r_low, r_high), "clearance");
                overlaps += 1;
            }
        }
    }
    // One overlapping pair for each point value on the grid, so the case is exercised.
    assert_eq!(overlaps, 7);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "transition");
    assert!(matches!(sign(compute), Some(FitType::Transition)));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    let (d, n) = (demand(labour), nameplate(labour));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "interference");
    assert!(matches!(sign(labour), Some(FitType::Interference)));

    let compute = layer(&contract, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert!(close3(d, (3.1, 4.4, 6.0)));
    assert_eq!(derived(n.0 - d.2, n.2 - d.0), "clearance");
    assert!(matches!(sign(compute), Some(FitType::Clearance)));
}
```

**Entry** `fit_criteria` · **Law** `algebra/crossed_remainder` · **Rule** `checks/fit_disagrees`

### The exposure

```text
exposure = max(-r_low, 0) = max(d_high - n_low, 0)
```

The exposure is the most that could have gone unserved: the largest demand against the smallest
supply, floored at zero. Nobody measured it. It is the ceiling a filing's own two figures imply,
which is why the rule built on it compares it with what the filing admits went unserved rather
than with a reading. It is zero exactly where the fit is `clearance`, and it never exceeds the
largest magnitude, `max(r_high, -r_low)`.

For `refutation`'s `compute` it is 16.4 less 16, 0.4 GPU, the ceiling that filing's own note gives
for the requests it could not serve. For `enterprise-contract`'s `labour` it is 2.0 people. Its
`compute` clears, and its exposure is 0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let exposure = |n: Triple, d: Triple| (d.2 - n.0).max(0.0);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    assert!(close(d.2, 16.4));
    assert!(close(exposure(n, d), 0.4));

    let contract = filing("corpus/enterprise-contract.xml");
    let labour = layer(&contract, "labour");
    assert!(close(exposure(nameplate(labour), demand(labour)), 2.0));
    let compute = layer(&contract, "compute");
    assert!(close(exposure(nameplate(compute), demand(compute)), 0.0));

    // Every ordered nameplate against every ordered demand on a grid of whole numbers: the two
    // forms agree, the exposure is zero exactly on clearance, and it never exceeds the largest
    // magnitude.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &n in &claims {
        for &d in &claims {
            let (r_low, r_high) = (n.0 - d.2, n.2 - d.0);
            let e = exposure(n, d);
            assert_eq!(e, (-r_low).max(0.0));
            assert_eq!(e == 0.0, r_low >= 0.0);
            assert!(e <= r_high.max(-r_low));
        }
    }
}
```

**Entry** `exposure` · **Law** `algebra/exposure` · **Rule** `checks/exposure_unaccounted`

## 2. The quantum and the sawtooth

### The floors cancel

```text
k = n / q        m = k - floor(d / q)        residue = d mod q = d - q * floor(d / q)

m * q - residue = (n/q - floor(d/q)) * q - (d - q * floor(d/q)) = n - d
```

A lumpy remainder splits into whole quanta, `m * q`, which a procurement decision moves, and a
residue, which no choice of how many quanta to hold removes. The floor appears twice with opposite
signs, so the split gives back `n - d` exactly, for any demand and any nameplate, interval or not.

`refutation`'s `compute` layer holds a quantum of 8 GPU and a nameplate of 16. At the remainder's
low corner the demand is 16.4: `m` is 0 and the residue 0.4, so `r` is -0.4. At the mode, 13.2 gives
`m` = 1 and a residue of 5.2, so `r` is 2.8. At the high corner, 11.0 gives `m` = 1 and a residue of
3.0, so `r` is 5.0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // The split, returning (m, residue, m * q - residue).
    let split = |n: f64, d: f64, q: f64| {
        let m = n / q - (d / q).floor();
        let residue = d - q * (d / q).floor();
        (m, residue, m * q - residue)
    };

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    let q = quantum(compute).expect("compute is lumpy").1;
    assert!(close(q, 8.0));

    // The crossed pairs: the low corner pairs n_low with d_high.
    let (m, residue, r) = split(n.0, d.2, q);
    assert!(close(d.2, 16.4) && close(m, 0.0) && close(residue, 0.4) && close(r, -0.4));
    let (m, residue, r) = split(n.1, d.1, q);
    assert!(close(d.1, 13.2) && close(m, 1.0) && close(residue, 5.2) && close(r, 2.8));
    let (m, residue, r) = split(n.2, d.0, q);
    assert!(close(d.0, 11.0) && close(m, 1.0) && close(residue, 3.0) && close(r, 5.0));

    // Every nameplate and demand on a grid of whole numbers, for several quanta, whether or not
    // the nameplate is a multiple: the split gives back n - d.
    for q in 1..=5 {
        for n in 0..=20 {
            for d in 0..=20 {
                let (_, _, r) = split(n as f64, d as f64, q as f64);
                assert!(close(r, (n - d) as f64));
            }
        }
    }
}
```

**Entry** `floors_cancel` · **Law** `algebra/remainder_decomposes`

### The congruence

```text
n = k * q with k whole   ==>   r = n - d ≡ -d (mod q)
```

A lumpy nameplate is a whole number of quanta, so `r + d = n` is a multiple of `q`, and the
remainder sits at the same place inside a quantum as the negated demand. Holding one more quantum
moves `r` by a whole quantum and never moves that place: the residue is fixed by the demand.

For `refutation`'s `compute`, `r + d` is 16 at all three corners: -0.4 + 16.4, 2.8 + 13.2 and
5.0 + 11.0, each two quanta of 8.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, n) = (demand(compute), nameplate(compute));
    let q = quantum(compute).expect("compute is lumpy").1;
    let r = (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    assert!(close3(r, (-0.4, 2.8, 5.0)));
    for (r, d) in [(r.0, d.2), (r.1, d.1), (r.2, d.0)] {
        assert!(close(r + d, 16.0) && close(r + d, 2.0 * q));
    }
    assert!(close3(d, (11.0, 13.2, 16.4)));

    // Every whole number of quanta against every whole demand: r and -d leave the same residue.
    for q in 1..=5_i64 {
        for k in 0..=6_i64 {
            for d in 0..=30_i64 {
                let r = k * q - d;
                assert_eq!(r.rem_euclid(q), (-d).rem_euclid(q));
            }
        }
    }
}
```

**Entry** `congruence` · **Rule** `checks/nameplate_not_a_multiple`

### The two readings

```text
up   = (-d) mod q     in [0, q)     what a nameplate rounded up to a whole quantum leaves spare
down = -(d mod q)     in (-q, 0]    what a nameplate rounded down to a whole quantum leaves short

up - down = q, except where q divides d, and there both are 0
```

Clearance and interference are one division read from opposite sides: the nearest whole quantum
above the demand and the nearest one below. Their sizes add up to a whole quantum, except on the
lattice itself, where the demand is a whole number of quanta and neither side has anything left.

For a demand of 13.2 against a quantum of 8, rounding up to 16 leaves 2.8 spare and rounding down
to 8 leaves 5.2 short, and 2.8 + 5.2 is 8. For a demand of 16 both are 0.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let readings = |d: f64, q: f64| {
        let up = (-d).rem_euclid(q);
        let down = -(d.rem_euclid(q));
        (up, down)
    };

    let (up, down) = readings(13.2, 8.0);
    assert!(close(up, 2.8) && close(down, -5.2) && close(up - down, 8.0));
    let (up, down) = readings(16.0, 8.0);
    assert!(close(up, 0.0) && close(down, 0.0));

    // Every whole demand against several quanta: the two sizes add to q off the lattice, and
    // both vanish on it.
    for q in 1..=6 {
        for d in 0..=40 {
            let (up, down) = readings(d as f64, q as f64);
            assert!(up >= 0.0 && up < q as f64 && down <= 0.0 && down > -(q as f64));
            if d % q == 0 {
                assert!(up == 0.0 && down == 0.0);
            } else {
                assert_eq!(up - down, q as f64);
            }
        }
    }
}
```

**Entry** `two_readings` · **Law** `none`

### The nearest multiple

```text
distance from d to the nearest whole multiple of q = min(d mod q, q - d mod q)
```

The closest any decision about how many quanta to hold can bring the supply to the demand. Whatever
is chosen, this much of the remainder stays, and it is the residue read from whichever side is
shorter.

For a demand of 13.2 against a quantum of 8 it is 2.8: 16 is nearer than 8.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let formula = |d: f64, q: f64| d.rem_euclid(q).min(q - d.rem_euclid(q));
    // The nearest multiple found by trying every whole number of quanta up to well past d.
    let searched = |d: f64, q: f64| {
        (0..=200)
            .map(|k| (d - k as f64 * q).abs())
            .fold(f64::INFINITY, f64::min)
    };

    assert!(close(formula(13.2, 8.0), 2.8) && close(searched(13.2, 8.0), 2.8));

    for q in 1..=6 {
        for d in 0..=60 {
            let (d, q) = (d as f64, q as f64);
            assert_eq!(formula(d, q), searched(d, q));
        }
    }
}
```

**Entry** `nearest_multiple` · **Law** `none`

### The sawtooth

```text
floor(d_low / q) = floor(d_high / q)   ==>   d_low mod q <= d_mode mod q <= d_high mod q

the converse fails: (0.2, 1.5, 2.7) with q = 1 gives residues (0.2, 0.5, 0.7), ordered, across two teeth
```

The residue drops back to zero at every multiple of the quantum, so read at a demand's three points
it need not come back ordered, and an unordered triple is not a claim at all. Inside one tooth,
where no multiple falls between the low and the high, it is always ordered. The census counts
demands that cross a tooth, not unordered residues, because an ordered triple can still cross.
That is why the schema carries the remainder's total and never its split.

`refutation`'s `compute` demand of [11.0, 13.2, 16.4] against a quantum of 8 crosses 16, and its
residues are (3.0, 5.2, 0.4). A demand of (4.5, 5.2, 6.7) against 1 crosses two teeth and gives
(0.5, 0.2, 0.7).

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let residues = |d: Triple, q: f64| (d.0.rem_euclid(q), d.1.rem_euclid(q), d.2.rem_euclid(q));
    let crosses = |d: Triple, q: f64| (d.0 / q).floor() != (d.2 / q).floor();
    let ordered = |r: Triple| r.0 <= r.1 && r.1 <= r.2;

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    let (d, q) = (demand(compute), quantum(compute).expect("compute is lumpy").1);
    assert!(close3(d, (11.0, 13.2, 16.4)) && crosses(d, q));
    assert!(close3(residues(d, q), (3.0, 5.2, 0.4)) && !ordered(residues(d, q)));

    let d = (4.5, 5.2, 6.7);
    assert!(crosses(d, 1.0) && close3(residues(d, 1.0), (0.5, 0.2, 0.7)));

    let d = (0.2, 1.5, 2.7);
    assert!(crosses(d, 1.0) && close3(residues(d, 1.0), (0.2, 0.5, 0.7)));
    assert!(ordered(residues(d, 1.0)));

    // Every ordered demand on a grid of whole numbers, for several quanta: inside one tooth the
    // residues are always ordered.
    for q in 1..=5 {
        for low in 0..=15 {
            for mode in low..=15 {
                for high in mode..=15 {
                    let d = (low as f64, mode as f64, high as f64);
                    if !crosses(d, q as f64) {
                        assert!(ordered(residues(d, q as f64)));
                    }
                }
            }
        }
    }
}
```

**Entry** `sawtooth` · **Law** `algebra/sawtooth`

### The composed quantum

```text
g = gcd(q1 * f1, q2 * f2, ...)       each part's quantum converted by its factor

every a1 * q1 * f1 + a2 * q2 * f2 + ... with whole a >= 0 is a multiple of g, and g is the largest
not every multiple of g is attainable: with quanta of 4 and 6, g = 2 and 2 = 4a + 6b has no answer
```

A composed supply built from lumpy parts still arrives in whole units, and the largest unit that
divides every total the parts could make is the greatest common divisor of their quanta, each
converted into the composed layer's unit first. Integer combinations reach every multiple of `g`,
but nobody holds a negative number of units, so the totals actually attainable are a numerical
semigroup: multiples of `g`, all of them past some point, not all of them below it. For two coprime
quanta `a` and `b`, the largest total out of reach is `a * b - a - b`, Sylvester's formula.

`merge-holding-composition`'s `compute` fuses a part of 8 GPU, converted at a factor of
[672, 720, 744] GPU-hour per GPU, with a part of 720 GPU-hour. At the factor's mode the first
quantum is 5760 GPU-hour, `g` is 720, and the filed composed nameplate of 6480 is nine of them.
Left unconverted, the fold would give 8, which also divides 6480: the filed total alone cannot tell
the two apart, which is why this block asserts the converted figure.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    fn gcd(a: i64, b: i64) -> i64 {
        if b == 0 {
            a
        } else {
            gcd(b, a % b)
        }
    }

    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = quantum(layer(&group.process_modulus, "compute-us")).expect("lumpy");
    let pt = quantum(layer(&group.process_modulus, "compute-pt")).expect("lumpy");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close(us.1, 8.0) && close(pt.1, 720.0));
    assert!(close3(f, (672.0, 720.0, 744.0)));

    let converted = us.1 * f.1;
    assert!(close(converted, 5760.0));
    let g = gcd(converted as i64, pt.1 as i64);
    assert_eq!(g, 720);
    let filed = nameplate(layer(&holding.process_modulus, "compute")).1;
    assert!(close(filed, 6480.0));
    assert_eq!(filed as i64 % g, 0);
    assert_eq!(filed as i64 / g, 9);
    // Unconverted, the fold gives 8, and 8 divides the filed total too.
    assert_eq!(gcd(us.1 as i64, pt.1 as i64), 8);
    assert_eq!(filed as i64 % 8, 0);

    // Quanta of 4 and 6: every attainable total is even, 2 is not attainable, every even total
    // from 4 up is.
    let attainable = |t: i64, a: i64, b: i64| (0..=t / a).any(|x| (t - x * a) % b == 0);
    assert_eq!(gcd(4, 6), 2);
    assert!(!attainable(2, 4, 6));
    for t in 0..=60 {
        if attainable(t, 4, 6) {
            assert_eq!(t % 2, 0);
        }
        if t >= 4 && t % 2 == 0 {
            assert!(attainable(t, 4, 6));
        }
    }

    // Sylvester's formula, checked by search for small coprime pairs.
    for a in 2..=9 {
        for b in (a + 1)..=10 {
            if gcd(a, b) != 1 {
                continue;
            }
            let largest_missed = (0..=a * b).filter(|&t| !attainable(t, a, b)).max().unwrap();
            assert_eq!(largest_missed, a * b - a - b);
        }
    }
}
```

**Entry** `composed_quantum` · **Law** `algebra/composed_quantum`

## 3. Shares, slack, exposure and draw

### The shares sum to the magnitude

```text
Σ share_mode = |r|_mode        Σ share_low >= |r|_low        Σ share_high <= |r|_high
```

A remainder's holders are a distribution of it over who bore it, so the stated shares account for
the whole of it at the mode. At the ends a filing may know its shares more narrowly than the
remainder's range, so the rule asks for containment there; equality at the ends would accuse the
more careful filing. One share left unstated suspends the rule, because the sum is then unknown,
not short.

`enterprise-contract`'s `support-cover` has a demand of [92, 118, 147] against 168, a remainder of
[21, 50, 76], and one `booked` share of exactly that. `every-unserved-excess` has a demand of
[12, 14, 16] against 10, a remainder of [-6, -4, -2] whose magnitude is [2, 4, 6], and two shares,
`customer` [1, 3, 4] and `unrealised` [1, 1, 2], that sum to it.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    let magnitude = |r: Triple| (r.0.max(-r.2).max(0.0), r.1.abs(), r.2.max(-r.0));
    let sum = |shares: &[Triple]| {
        shares.iter().fold((0.0, 0.0, 0.0), |t, s| (t.0 + s.0, t.1 + s.1, t.2 + s.2))
    };
    let within = |s: Triple, m: Triple| close(s.1, m.1) && s.0 >= m.0 - 1e-9 && s.2 <= m.2 + 1e-9;

    let contract = filing("corpus/enterprise-contract.xml");
    let cover = layer(&contract, "support-cover");
    assert!(close3(demand(cover), (92.0, 118.0, 147.0)) && close(nameplate(cover).0, 168.0));
    let r = crossed(nameplate(cover), demand(cover));
    assert!(close3(r, (21.0, 50.0, 76.0)));
    let held: Vec<Triple> = holders(cover).into_iter().map(|(_, s)| s.expect("stated")).collect();
    assert!(close3(sum(&held), magnitude(r)) && within(sum(&held), magnitude(r)));

    let excess = filing("fixtures/every-unserved-excess.xml");
    let line = layer(&excess, "line");
    assert!(close3(demand(line), (12.0, 14.0, 16.0)) && close(nameplate(line).0, 10.0));
    let r = crossed(nameplate(line), demand(line));
    assert!(close3(r, (-6.0, -4.0, -2.0)) && close3(magnitude(r), (2.0, 4.0, 6.0)));
    let held = holders(line);
    assert!(matches!(held[0].0, HolderKindType::Customer) && close3(held[0].1.unwrap(), (1.0, 3.0, 4.0)));
    assert!(matches!(held[1].0, HolderKindType::Unrealised) && close3(held[1].1.unwrap(), (1.0, 1.0, 2.0)));
    let shares: Vec<Triple> = held.iter().map(|(_, s)| s.unwrap()).collect();
    assert!(within(sum(&shares), magnitude(r)));

    // Containment at the ends: a narrower pair of shares is accepted, a wider one is not.
    assert!(within((2.5, 4.0, 5.5), (2.0, 4.0, 6.0)));
    assert!(!within((1.5, 4.0, 6.0), (2.0, 4.0, 6.0)));
}
```

**Entry** `share_sum` · **Rule** `checks/shares_do_not_sum`

### Served shares stay within the slack

```text
under interference:   Σ served share_mode  <=  slack_mode of the buffer the absorber names
served holders are booked, counterparty and people; customer and unrealised went without
```

A buffer bounds what it absorbed. Under interference the excess above the nameplate went
somewhere, and a `booked`, `counterparty` or `people` holder says a buffer took part of it, so the
shares those holders bear cannot exceed the room the buffer the remainder names had. The two
holders who went without were absorbed by nothing, and the bound does not apply to them. A buffer
nobody sized suspends it: its room is unknown, not zero. What the holders bear splits exactly into
what a buffer absorbed and what went unserved, and a law holds that split on every run.

No loaded filing reaches the bound itself: every interference layer with a served holder leaves
the buffer it names unsized. A layer 3 short whose capacity buffer can take [0, 2, 3], with a
`people` holder bearing [0, 2, 3] and a `customer` holder bearing the rest, is inside it; the same
layer with the `people` share at a mode of 2.5 is not.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let served = |k: &str| matches!(k, "booked" | "counterparty" | "people");
    let within = |holders: &[(&str, f64)], slack_mode: f64| {
        let borne: f64 = holders.iter().filter(|(k, _)| served(k)).map(|(_, s)| s).sum();
        borne <= slack_mode + 1e-9
    };

    let slack = (0.0, 2.0, 3.0);
    assert!(within(&[("people", 2.0), ("customer", 1.0)], slack.1));
    assert!(!within(&[("people", 2.5), ("customer", 0.5)], slack.1));
    // The two unserved holders are exempt however large their shares.
    assert!(within(&[("customer", 2.0), ("unrealised", 1.0)], 0.0));

    // What every-unserved-excess's holders bear splits into what a buffer absorbed and what went
    // unserved, and here nothing was absorbed.
    let excess = filing("fixtures/every-unserved-excess.xml");
    let held = holders(layer(&excess, "line"));
    let total: f64 = held.iter().map(|(_, s)| s.unwrap().1).sum();
    let absorbed: f64 = held
        .iter()
        .filter(|(k, _)| !matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().1)
        .sum();
    let unserved: f64 = held
        .iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().1)
        .sum();
    assert!(close(total, absorbed + unserved) && close(absorbed, 0.0) && close(unserved, 4.0));
}
```

**Entry** `served_within_slack` · **Law** `algebra/borne` · **Rule** `checks/share_exceeds_slack`

### The exposure is accounted for

```text
exposure = max(0, d_high - n_low)  <=  Σ buffers slack_high + Σ unserved share_high      at the high corner
```

The exposure is the most that could have gone unserved, and it is at most what the three buffers
could absorb plus what the filing admits went unserved. The buffers are substitutes, so all three
are summed, and one nobody sized suspends the check. It is read at one corner because the two
sides of a remainder that overlaps its nameplate are anti-correlated: summed across the range they
describe a week that never happened.

`every-unserved-excess` exposes 16 less 10, 6 shifts, with every buffer at 0, and its unserved
shares reach 4 and 2 at their highs: 6, exactly accounted for. `refutation`'s `compute` exposes
0.4 GPU with every buffer at 0, and files its one unserved share as unmeasured, so the check is
suspended there rather than passed.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let excess = filing("fixtures/every-unserved-excess.xml");
    let line = layer(&excess, "line");
    let exposure = (demand(line).2 - nameplate(line).0).max(0.0);
    assert!(close(exposure, 6.0) && close(demand(line).2, 16.0));
    let buffers = [
        claim(&line.supply.nameplate.capacity_slack),
        claim(&line.supply.nameplate.inventory_slack),
        claim(&line.time_slack),
    ];
    let absorbable: f64 = buffers.iter().map(|b| b.expect("stated").2).sum();
    assert!(close(absorbable, 0.0));
    let unserved: f64 = holders(line)
        .iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.unwrap().2)
        .sum();
    assert!(close(unserved, 6.0));
    assert!(exposure <= absorbable + unserved + 1e-9);

    let refutation = filing("corpus/refutation.xml");
    let compute = layer(&refutation, "compute");
    assert!(close((demand(compute).2 - nameplate(compute).0).max(0.0), 0.4));
    let unserved: Vec<Option<Triple>> = holders(compute)
        .into_iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s)
        .collect();
    assert!(unserved.iter().any(|s| s.is_none()));
}
```

**Entry** `exposure_bound` · **Rule** `checks/exposure_unaccounted`

### A draw stays within what the supply can make

```text
draw_low  > n_high + capacity_high     the whole draw is above what the supply can make
draw_high <= n_low + capacity_low      the whole draw clears
otherwise                              the ranges overlap, and the document does not settle it

draw, nameplate and capacity slack in one unit
```

A supply cannot serve more than its rating plus the room it has above it. The draw is what came
out, and only a draw whose whole range is above the whole of what the supply could make is a
filing error; ranges that overlap are a document that cannot settle its own question. The bound is
the supply's and never the demand's: a shared line's output is partly somebody else's demand.

`enterprise-contract`'s `support-cover` drew [92, 118, 147] engineer-hours a week against a
nameplate of 168 and a capacity slack reaching 40, and clears. A draw of [800, 900, 1000] would be
over the line, since 800 exceeds 208.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let verdict = |draw: Triple, n: Triple, slack: Triple| {
        if draw.0 > n.2 + slack.2 {
            "over the line"
        } else if draw.2 <= n.0 + slack.0 {
            "clears"
        } else {
            "overlaps"
        }
    };

    let contract = filing("corpus/enterprise-contract.xml");
    let cover = layer(&contract, "support-cover");
    let slack = claim(&cover.supply.nameplate.capacity_slack).expect("stated");
    assert!(close3(draw(cover), (92.0, 118.0, 147.0)) && close(slack.2, 40.0));
    assert!(close3(nameplate(cover), (168.0, 168.0, 168.0)));
    assert_eq!(verdict(draw(cover), nameplate(cover), slack), "clears");
    assert_eq!(verdict((800.0, 900.0, 1000.0), nameplate(cover), slack), "over the line");
    assert!(close(nameplate(cover).2 + slack.2, 208.0));
    assert_eq!(verdict((150.0, 180.0, 200.0), nameplate(cover), slack), "overlaps");
}
```

**Entry** `draw_bound` · **Rule** `checks/draw_exceeds_the_supply`

## 4. Fusion and eliminations

### The fusion sum

```text
x_composed = F Φ x_parts - e_x        for x in demand, nameplate, draw
```

A composed layer's figure is the sum of its parts' figures, each converted into the composed
layer's unit, less what the composer eliminated as counted twice. It holds for each quantity
separately, and an elimination names exactly one of them. It is owed only where the composer
searched for double counting and could size what was found, and where every layer the sum reads
states the quantity; everywhere else the sum is suspended, not passed.

`merge-group-composition`'s `labour` fuses the US member's demand of [4.5, 5.2, 6.0] people with
the Portuguese member's [6.4, 7.1, 8.2], converted at 1, and eliminates [0.5, 0.8, 1.2] of work
both members file: [10.9, 12.3, 14.2] less that is [10.4, 11.5, 13.0], the demand the group files.
Its `shift-line` fuses two nameplates of 10 that are the same machine, eliminates 10, and files 10;
the two draws of 10 and 4.4 are the same shifts recorded from both ends, so 14.4 less 4.4 is the 10
the group files.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let sum = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let less = |a: Triple, e: Triple| (a.0 - e.0, a.1 - e.1, a.2 - e.2);

    let us = filing("corpus/merge-us-member.xml");
    let pt = filing("corpus/merge-pt-member.xml");
    let group = composition("corpus/merge-group-composition.xml");

    let labour = fusion(&group, "labour");
    let f = factor(part(labour, "pessoal")).expect("a stated factor");
    assert!(close3(f, (1.0, 1.0, 1.0)));
    let d_us = demand(layer(&us, "labour"));
    let d_pt = demand(layer(&pt, "pessoal"));
    assert!(close3(d_us, (4.5, 5.2, 6.0)) && close3(d_pt, (6.4, 7.1, 8.2)));
    let parts = sum(d_us, (d_pt.0 * f.0, d_pt.1 * f.1, d_pt.2 * f.2));
    assert!(close3(parts, (10.9, 12.3, 14.2)));
    let e = elimination(labour, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e, (0.5, 0.8, 1.2)));
    assert!(close3(less(parts, e), (10.4, 11.5, 13.0)));
    assert!(close3(demand(layer(&group.process_modulus, "labour")), less(parts, e)));

    let line = fusion(&group, "shift-line");
    let (us_line, pt_line) = (layer(&us, "shift-line"), layer(&pt, "linha-partilhada"));
    let n = sum(nameplate(us_line), nameplate(pt_line));
    let e = elimination(line, EliminationAgainstType::Nameplate).expect("filed");
    assert!(close3(n, (20.0, 20.0, 20.0)) && close3(e, (10.0, 10.0, 10.0)));
    assert!(close3(nameplate(layer(&group.process_modulus, "shift-line")), less(n, e)));

    let d = sum(draw(us_line), draw(pt_line));
    let e = elimination(line, EliminationAgainstType::Draw).expect("filed");
    assert!(close3(d, (14.4, 14.4, 14.4)) && close3(e, (4.4, 4.4, 4.4)));
    assert!(close3(draw(layer(&group.process_modulus, "shift-line")), less(d, e)));
    assert!(close3(less(d, e), (10.0, 10.0, 10.0)));
}
```

**Entry** `fusion_sum` · **Law** `algebra/fusion_sum` · **Rule** `checks/fusion_sum_disagrees`

### The elimination, bound by bound

```text
bound by bound   [Σ low - e_low,  Σ mode - e_mode,  Σ high - e_high]    wherever that is ordered
crossed          [Σ low - e_high, Σ mode - e_mode,  Σ high - e_low]     wherever it is not
```

An elimination removes a component of the figure it is taken from, so at the sum's low corner the
overlap is at its own low: the subtraction goes bound by bound, the opposite of a remainder's
crossed subtraction. That pairing assumes the sum has width for the overlap to move with. Where it
has less, the bound-by-bound result inverts, and the crossed pairing is the only ordered reading:
the most overlap against the least total.

⭐ What the ordering condition is, said once: a `Claim` declares the cone
`low ≤ mostLikely ≤ high`, and a figure a fusion files has to land inside it. So the choice between
the two pairings is not a preference between two arithmetics. It is whichever one stays in the type,
and `eliminations/paired.sqlc` decides it per elimination from the sum and the overlap alone.

`every-partial-elimination` files two point parts of 10 and a shared block of 3, so 20 less 3 is
17 either way. `every-inverting-elimination` files the same parts and a shared block of [2, 3, 5]:
bound by bound that is [18, 17, 15], which is not a claim, and the composed nameplate it files is the
crossed [15, 17, 18].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bound_by_bound = |t: Triple, e: Triple| (t.0 - e.0, t.1 - e.1, t.2 - e.2);
    let crossed = |t: Triple, e: Triple| (t.0 - e.2, t.1 - e.1, t.2 - e.0);
    let ordered = |r: Triple| r.0 <= r.1 && r.1 <= r.2;
    let eliminate = |t: Triple, e: Triple| {
        if ordered(bound_by_bound(t, e)) {
            bound_by_bound(t, e)
        } else {
            crossed(t, e)
        }
    };

    let partial = composition("fixtures/every-partial-elimination.xml");
    let e = elimination(fusion(&partial, "shift-capacity"), EliminationAgainstType::Nameplate)
        .expect("filed");
    let stack = &partial.process_modulus;
    let total = (20.0, 20.0, 20.0);
    assert!(close3(nameplate(layer(stack, "team-a")), (10.0, 10.0, 10.0)));
    assert!(close3(nameplate(layer(stack, "team-b")), (10.0, 10.0, 10.0)));
    assert!(close3(e, (3.0, 3.0, 3.0)));
    assert!(close3(eliminate(total, e), (17.0, 17.0, 17.0)));
    assert!(close3(nameplate(layer(stack, "shift-capacity")), eliminate(total, e)));

    let inverting = composition("fixtures/every-inverting-elimination.xml");
    let e = elimination(fusion(&inverting, "shift-capacity"), EliminationAgainstType::Nameplate)
        .expect("filed");
    assert!(close3(e, (2.0, 3.0, 5.0)));
    assert!(close3(bound_by_bound(total, e), (18.0, 17.0, 15.0)));
    assert!(!ordered(bound_by_bound(total, e)));
    assert!(close3(eliminate(total, e), (15.0, 17.0, 18.0)));
    let filed = nameplate(layer(&inverting.process_modulus, "shift-capacity"));
    assert!(close3(filed, eliminate(total, e)));

    // Every ordered total against every ordered elimination on a grid of whole numbers: the
    // crossed pairing is always ordered, so the rule always gives a claim, and it agrees with
    // bound by bound wherever bound by bound is one.
    let mut claims = Vec::new();
    for low in 0..=6 {
        for mode in low..=6 {
            for high in mode..=6 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &t in &claims {
        for &e in &claims {
            assert!(ordered(crossed(t, e)));
            assert!(ordered(eliminate(t, e)));
            if ordered(bound_by_bound(t, e)) {
                assert_eq!(eliminate(t, e), bound_by_bound(t, e));
            }
        }
    }
}
```

**Entry** `elimination_componentwise` · **Law** `algebra/fusion_sum` · **Rule** `checks/fusion_sum_disagrees`

### Widening a part widens the figure; widening an elimination narrows it

```text
widen a part sum       the composed figure widens or stays, under either pairing
widen an elimination   bound by bound, the composed figure NARROWS.  Crossed, it widens
```

Every width in this model widens what it touches, with one exception, and the exception is the
elimination. Converting and summing are inclusion-isotone: a part stated less precisely yields a
composed figure no more precise than before. An elimination subtracted bound by bound reverses that in
its own width, because its low raises the composed low while its high lowers the composed high, so
widening it at both ends brings the two together. A composer who is less sure how much was double
counted therefore files a more precise composed figure, which is the only place here where less
knowledge produces a tighter answer.

⛔ The crossed pairing is isotone, and that is not why it is chosen.
`eliminations/paired.sqlc` reaches it only where subtracting bound by bound would leave the claim
disordered, so the monotonicity is a consequence of that repair rather than its motive. Which reading
each filed elimination takes, and therefore which direction its own width pushes, is
`eliminations/monotone.sqlc`.

A sum of [10, 12, 14] less an elimination of [1, 1, 2] is [9, 11, 12]. Less a wider [0, 1, 3] it is
[10, 11, 11]: the low has risen and the high has fallen, and the second figure is not contained in the
first.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bb = |s: Triple, e: Triple| (s.0 - e.0, s.1 - e.1, s.2 - e.2);
    let crossed = |s: Triple, e: Triple| (s.0 - e.2, s.1 - e.1, s.2 - e.0);
    // `outer` contains `inner`: the reading a wider input must give if the map is isotone.
    let contains = |inner: Triple, outer: Triple| outer.0 <= inner.0 && inner.2 <= outer.2;

    let mut narrowed_by_a_wider_elimination = 0;
    for s0 in 0..6 {
        for s2 in s0..6 {
            for e0 in 0..4 {
                for e2 in e0..4 {
                    for d in 1..3 {
                        let (s0, s2) = (s0 as f64, s2 as f64);
                        let (e0, e2, d) = (e0 as f64, e2 as f64, d as f64);
                        let (s, e) = ((s0, s0, s2), (e0, e0, e2));
                        let wider_part = (s0 - d, s0 - d, s2 + d);
                        let wider_e = (e0 - d, e0 - d, e2 + d);

                        // Isotone in the part, under both pairings.
                        assert!(contains(bb(s, e), bb(wider_part, e)));
                        assert!(contains(crossed(s, e), crossed(wider_part, e)));

                        // Isotone in the elimination under the crossed pairing, always.
                        assert!(contains(crossed(s, e), crossed(s, wider_e)));

                        // And not under bound by bound.
                        if !contains(bb(s, e), bb(s, wider_e)) {
                            narrowed_by_a_wider_elimination += 1;
                        }
                    }
                }
            }
        }
    }
    // Not a corner of the grid: it is the ordinary case for an elimination with width.
    assert!(narrowed_by_a_wider_elimination > 0);

    // The smallest witness, written out.
    let s = (10.0, 12.0, 14.0);
    assert_eq!(bb(s, (1.0, 1.0, 2.0)), (9.0, 11.0, 12.0));
    assert_eq!(bb(s, (0.0, 1.0, 3.0)), (10.0, 11.0, 11.0));
    assert!(!contains(bb(s, (1.0, 1.0, 2.0)), bb(s, (0.0, 1.0, 3.0))));
    assert!(contains(crossed(s, (1.0, 1.0, 2.0)), crossed(s, (0.0, 1.0, 3.0))));
}
```

**Entry** `isotone_in_parts_not_in_eliminations` · **Law** `none`

### A derived figure is computed through its parts

```text
x_derived = F Φ x_parts - e_x        a part filed as a derivation enters at its own x_derived
```

A figure filed as a `fusionSum` derivation states no value: it names the identity that computes it,
an output the receiver computes. On a composed layer it is computed by the fusion sum above, and a
part that itself files a derivation enters that sum at the figure its own fusion computes, so the
computation goes down until every path reaches a layer that states the figure. Each factor
multiplies and each elimination subtracts on the way. Where a layer on a path files the figure
absent for any other reason, the derived figure cannot be computed, and it is left without a value
rather than summed over what could be found.

`every-derived-quantity`'s `pair` files its demand as a `fusionSum` derivation and fuses `line-a`'s
[10, 12, 14] with `line-b`'s [20, 24, 30], less [1, 2, 3] of orders both lines count: its demand is
[29, 34, 41]. `site` fuses `pair` with `line-c`'s [5, 6, 8] and files [34, 40, 49], a figure that
can only be checked through `pair`'s. `single` files its draw as a `fusionSum` derivation over
`line-d` alone, whose draw nobody metered, so there is nothing to compute it from.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let sum = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let less = |a: Triple, e: Triple| (a.0 - e.0, a.1 - e.1, a.2 - e.2);

    let fixture = composition("fixtures/every-derived-quantity.xml");
    let stack = &fixture.process_modulus;

    let pair = layer(stack, "pair");
    assert_eq!(derivation(&pair.demand.amount), Some(&IdentityType::FusionSum));
    let (a, b) = (demand(layer(stack, "line-a")), demand(layer(stack, "line-b")));
    assert!(close3(a, (10.0, 12.0, 14.0)) && close3(b, (20.0, 24.0, 30.0)));
    let f = fusion(&fixture, "pair");
    assert!(factor(part(f, "line-a")).is_none() && factor(part(f, "line-b")).is_none());
    let e = elimination(f, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e, (1.0, 2.0, 3.0)));
    let computed = less(sum(a, b), e);
    assert!(close3(computed, (29.0, 34.0, 41.0)));

    let c = demand(layer(stack, "line-c"));
    assert!(close3(c, (5.0, 6.0, 8.0)));
    let f = fusion(&fixture, "site");
    assert!(elimination(f, EliminationAgainstType::Demand).is_none());
    assert!(close3(sum(computed, c), (34.0, 40.0, 49.0)));
    assert!(close3(demand(layer(stack, "site")), sum(computed, c)));

    let single = layer(stack, "single");
    assert_eq!(derivation(&single.supply.jagged.draw), Some(&IdentityType::FusionSum));
    assert_eq!(fusion(&fixture, "single").part.len(), 1);
    let d = layer(stack, "line-d");
    assert_eq!(absence(&d.supply.jagged.draw), Some(&ClaimAbsenceReasonType::Unmeasured));
}
```

**Entry** `derived_quantity` · **Law** `algebra/derived_quantities` · **Rule** `checks/fusion_sum_disagrees`

### The product is a join

```text
(F Φ x)[l] = Σ_p F[l, p] * Φ[p] * x[p] = Σ over the parts of l of factor * figure
```

`F` is an incidence, one row per composed layer and one column per part, with a 1 where the part
composes into the layer; `Φ` is diagonal, one factor per part. Their product with a vector of the
parts' figures is the same number as joining each part to its composed layer and summing the
converted figures per layer: the matrix and the relation are two spellings of one sum.
`examples/matrices/main.rs` builds the product with a linear algebra library and asserts it equals
the SQL's sum for every composed layer and quantity.

For `merge-holding-composition`'s `compute`, the US part's demand of [3.1, 4.4, 6.0] GPU at a
factor of [672, 720, 744] GPU-hour per GPU plus the Portuguese part's [430, 545, 690] GPU-hour is
[2513.2, 3713.0, 5154.0], both ways. Its `staff` is [10.4, 11.5, 13.0] plus [2.3, 2.8, 3.4], or
[12.7, 14.3, 16.4].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    // The parts, in column order, and the composed layers, in row order.
    let mut cols: Vec<(String, String, Triple, Triple)> = Vec::new();
    for f in &holding.fusion {
        for p in &f.part {
            let x = demand(layer(&group.process_modulus, &p.layer.filing.id));
            cols.push((f.name.clone(), p.layer.filing.id.clone(), factor(p).unwrap_or((1.0, 1.0, 1.0)), x));
        }
    }
    let rows: Vec<String> = holding.fusion.iter().map(|f| f.name.clone()).collect();

    for point in 0..3 {
        let at = |t: Triple| [t.0, t.1, t.2][point];

        // As a matrix product: F (rows x cols) times diag(Φ) times x.
        let incidence: Vec<Vec<f64>> = rows
            .iter()
            .map(|r| cols.iter().map(|c| if c.0 == *r { 1.0 } else { 0.0 }).collect())
            .collect();
        let scaled: Vec<f64> = cols.iter().map(|c| at(c.2) * at(c.3)).collect();
        let product: Vec<f64> = incidence
            .iter()
            .map(|row| row.iter().zip(&scaled).map(|(f, x)| f * x).sum())
            .collect();

        // As a join with a GROUP BY: each part keyed by its composed layer, summed per key.
        let mut grouped: std::collections::BTreeMap<&str, f64> = Default::default();
        for c in &cols {
            *grouped.entry(c.0.as_str()).or_default() += at(c.2) * at(c.3);
        }

        for (i, r) in rows.iter().enumerate() {
            assert!(close(product[i], grouped[r.as_str()]));
        }
        let compute = rows.iter().position(|r| r == "compute").unwrap();
        assert!(close(product[compute], at((2513.2, 3713.0, 5154.0))));
        let staff = rows.iter().position(|r| r == "staff").unwrap();
        assert!(close(product[staff], at((12.7, 14.3, 16.4))));
    }

    let us = cols.iter().find(|c| c.1 == "compute-us").unwrap();
    assert!(close3(us.2, (672.0, 720.0, 744.0)) && close3(us.3, (3.1, 4.4, 6.0)));
    let pt = cols.iter().find(|c| c.1 == "compute-pt").unwrap();
    assert!(close3(pt.3, (430.0, 545.0, 690.0)));
    let labour = cols.iter().find(|c| c.1 == "labour").unwrap();
    let on_call = cols.iter().find(|c| c.1 == "on-call").unwrap();
    assert!(close3(labour.3, (10.4, 11.5, 13.0)) && close3(on_call.3, (2.3, 2.8, 3.4)));
}
```

**Entry** `product_is_join` · **Law** `none`

### One part is carried

```text
a fusion of one part that eliminates nothing:   x_composed = Φ x_part    for every quantity
```

With one part there is nothing to sum, nothing to subtract and no judgement to make, so a composed
layer that files anything but its part, converted, has changed a figure it only carried. It holds
for every quantity the layer states, the buffer slacks included, not only the three a fusion sums.

`merge-holding-composition`'s `shift-line` carries the group's `shift-line`, with no factor: its
demand of [11.0, 12.7, 14.4] shifts a week and its nameplate and draw of 10 come through unchanged.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let f = fusion(&holding, "shift-line");
    assert_eq!(f.part.len(), 1);
    assert!(elimination(f, EliminationAgainstType::Demand).is_none());
    assert!(elimination(f, EliminationAgainstType::Nameplate).is_none());
    assert!(factor(part(f, "shift-line")).is_none());

    let carried = layer(&group.process_modulus, "shift-line");
    let composed = layer(&holding.process_modulus, "shift-line");
    assert!(close3(demand(carried), (11.0, 12.7, 14.4)));
    assert!(close3(demand(composed), demand(carried)));
    assert!(close3(nameplate(composed), nameplate(carried)));
    assert!(close3(draw(composed), draw(carried)));
    assert!(close3(nameplate(composed), (10.0, 10.0, 10.0)));
    assert!(close3(draw(composed), (10.0, 10.0, 10.0)));
}
```

**Entry** `one_part_carries` · **Rule** `checks/one_part_fusion_alters_its_part`

### A window is carried, never summed

```text
window_composed = window_part     for every part, never Σ window_parts
```

A duty cycle is a calendar, and two parts that name one machine file one calendar between them.
Amounts add because two supplies are two supplies; a calendar does not, because it is the same week
seen twice. So a composed layer files the window its parts file, and summing them would give a
machine that runs more days than the week has.

`merge-group-composition`'s `shift-line` fuses two parts that each run 5 days a week, one in `days`
and one in `dias`, and files 5 days, not 10. The holding carries the same 5.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let us = filing("corpus/merge-us-member.xml");
    let pt = filing("corpus/merge-pt-member.xml");
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    let (w_us, unit_us) = window(layer(&us, "shift-line")).expect("a window");
    let (w_pt, unit_pt) = window(layer(&pt, "linha-partilhada")).expect("a window");
    let (w_group, unit_group) = window(layer(&group.process_modulus, "shift-line")).expect("a window");
    let (w_holding, _) = window(layer(&holding.process_modulus, "shift-line")).expect("a window");
    assert_eq!((unit_us, unit_pt, unit_group), ("days", "dias", "days"));
    assert!(close3(w_us, (5.0, 5.0, 5.0)) && close3(w_pt, w_us));
    assert!(close3(w_group, w_us) && close3(w_holding, w_group));
    let summed = (w_us.0 + w_pt.0, w_us.1 + w_pt.1, w_us.2 + w_pt.2);
    assert!(close3(summed, (10.0, 10.0, 10.0)) && !close3(summed, w_group));
}
```

**Entry** `window_carried` · **Rule** `checks/window_lost_or_summed`

### A coupling attenuates

```text
strength_upper <= strength_lower * share      share = max(Φ n_A) / min(n_X)
```

If A moves with B, and A is fused into a larger X one level up, the dependence survives but
weakens: relief applied to X may land on A's fellow parts rather than on A, so at most A's share
of X can move. The share is A's nameplate, converted into X's unit, over X's filed nameplate, read
where it is largest, because the bound accuses when it is exceeded and must not accuse a correct
filing.

The group files `labour` coupled to `shift-line` at [0.10, 0.22, 0.35]. The holding fuses `labour`,
10 people, into `staff`, 12, and files `staff` coupled to `shift-line` at [0.06, 0.15, 0.26]: inside
the group's strength times 10 of 12 at every bound.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");

    let lower = coupling(&group.process_modulus, "labour", "shift-line");
    let upper = coupling(&holding.process_modulus, "staff", "shift-line");
    assert!(close3(lower, (0.10, 0.22, 0.35)));
    assert!(close3(upper, (0.06, 0.15, 0.26)));

    let a = nameplate(layer(&group.process_modulus, "labour"));
    let x = nameplate(layer(&holding.process_modulus, "staff"));
    let f = factor(part(fusion(&holding, "staff"), "labour")).unwrap_or((1.0, 1.0, 1.0));
    let share = a.2 * f.2 / x.0;
    assert!(close(a.2, 10.0) && close(x.0, 12.0) && close(share, 10.0 / 12.0));

    let ceiling = (lower.0 * share, lower.1 * share, lower.2 * share);
    assert!(upper.0 <= ceiling.0 && upper.1 <= ceiling.1 && upper.2 <= ceiling.2);
    // The group's own strength is not a ceiling the holding may reach.
    assert!(upper.2 < lower.2);
}
```

**Entry** `coupling_attenuates` · **Rule** `checks/coupling_does_not_attenuate`

## 5. Conversion factors and cycles

### A positive factor multiplies bound by bound

```text
Φ > 0:   Φ x = [min(φ_low x_low, φ_high x_low),  φ_mode x_mode,  max(φ_low x_high, φ_high x_high)]
         which is [φ_low x_low, φ_mode x_mode, φ_high x_high] wherever x >= 0
```

A conversion factor is strictly positive, so the product never reorders a claim's bounds: its low
comes from `x`'s low and its high from `x`'s high, and only the factor's corner depends on the
sign. For a demand or a nameplate, which cannot be negative, that is the bound-by-bound product.
A remainder can be negative, and there the low takes the factor's high: more of a shortfall,
converted at the larger rate, is the smaller number. The general four-corner product, where both
operands straddle zero, is never needed.

`merge-holding-composition` converts the group's `compute-us` at [672, 720, 744] GPU-hour per GPU:
its nameplate of 8 becomes [5376, 5760, 5952], its demand of [3.1, 4.4, 6.0] becomes
[2083.2, 3168, 4464], and its remainder of [2.0, 3.6, 4.9] becomes [1344, 2592, 3645.6]. A remainder
of [-3.0, -1.5, -0.4] at a factor of [0.5, 1, 2] becomes [-6, -1.5, -0.2], where bound by bound
would give [-1.5, -1.5, -0.8].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let convert = |x: Triple, f: Triple| {
        ((x.0 * f.0).min(x.0 * f.2), x.1 * f.1, (x.2 * f.0).max(x.2 * f.2))
    };

    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close3(f, (672.0, 720.0, 744.0)));
    assert!(close3(convert(nameplate(us), f), (5376.0, 5760.0, 5952.0)));
    assert!(close3(demand(us), (3.1, 4.4, 6.0)));
    assert!(close3(convert(demand(us), f), (2083.2, 3168.0, 4464.0)));
    let r = (nameplate(us).0 - demand(us).2, nameplate(us).1 - demand(us).1, nameplate(us).2 - demand(us).0);
    assert!(close3(r, (2.0, 3.6, 4.9)));
    assert!(close3(convert(r, f), (1344.0, 2592.0, 3645.6)));

    let (r, f) = ((-3.0, -1.5, -0.4), (0.5, 1.0, 2.0));
    assert!(close3(convert(r, f), (-6.0, -1.5, -0.2)));
    assert!(close3((r.0 * f.0, r.1 * f.1, r.2 * f.2), (-1.5, -1.5, -0.8)));

    // Every claim on a grid of whole numbers either side of zero, against every positive factor:
    // the formula is the least and greatest product over the four corners, and it is ordered.
    let mut xs = Vec::new();
    for low in -4..=4 {
        for mode in low..=4 {
            for high in mode..=4 {
                xs.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let mut fs = Vec::new();
    for low in 1..=4 {
        for mode in low..=4 {
            for high in mode..=4 {
                fs.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    for &x in &xs {
        for &f in &fs {
            let corners = [x.0 * f.0, x.0 * f.2, x.2 * f.0, x.2 * f.2];
            let lowest = corners.iter().cloned().fold(f64::INFINITY, f64::min);
            let highest = corners.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
            let c = convert(x, f);
            assert_eq!((c.0, c.2), (lowest, highest));
            assert!(c.0 <= c.1 && c.1 <= c.2);
            if x.0 >= 0.0 {
                assert_eq!(c, (x.0 * f.0, x.1 * f.1, x.2 * f.2));
            }
        }
    }
}
```

**Entry** `positive_factor_componentwise` · **Law** `algebra/composed_remainder`

### A conversion is two slopes and a sign

```text
Φ x at a bound = a·max(x, 0) − b·max(−x, 0)
  the low takes (a, b) = (φ_low, φ_high);  the high takes the same pair exchanged
```

The entry above gives the corner form. This says the corner form is the whole of the operator. A
continuous map of one variable that is positively homogeneous and piecewise linear with a single fold
is exactly two slopes joined at that fold, so a conversion has two degrees of freedom and the sign of
its operand, and there is nothing else about one to state or to file. The low and the high are the
same function with its two slopes exchanged.

⭐ The fold sits at zero and cannot be moved, because an operator of this shape has no offset to move
it with. Zero is where a remainder changes sign, which is the boundary between clearance and
interference, so the one place a conversion changes behaviour is the one place the fit does.

A remainder of 2.0 converted at [672, 720, 744] takes 1344 at its low: the factor's low times the
positive part, and nothing times the negative part, which is absent. Its mode is 3.6 times 720, or
2592. A remainder of -3.0 at [0.5, 1, 2] takes -6 at its low instead: the negative part times the
factor's high, which is the same formula reading its other branch.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let relu = |x: f64| if x > 0.0 { x } else { 0.0 };
    let corner_low = |x: f64, lo: f64, hi: f64| (x * lo).min(x * hi);
    let corner_high = |x: f64, lo: f64, hi: f64| (x * lo).max(x * hi);
    let slopes = |x: f64, a: f64, b: f64| a * relu(x) - b * relu(-x);

    // The corner form and the slope form are one function, at both bounds and either sign.
    for x in -40..=40 {
        for lo in 1..=12 {
            for hi in lo..=12 {
                let (x, lo, hi) = (x as f64, lo as f64, hi as f64);
                assert_eq!(corner_low(x, lo, hi), slopes(x, lo, hi));
                assert_eq!(corner_high(x, lo, hi), slopes(x, hi, lo));
            }
        }
    }

    // Two slopes are the whole of it: the operator's value is one of them times the operand, never
    // a third thing, because the two branches already cover both sides of the only fold.
    for x in -40..=40 {
        let x = x as f64;
        assert!(slopes(x, 3.0, 7.0) == 3.0 * x || slopes(x, 3.0, 7.0) == 7.0 * x);
    }

    // The two operands the entry above converts, read through the slope form.
    assert!(close(slopes(2.0, 672.0, 744.0), 1344.0));
    assert!(close(corner_low(2.0, 672.0, 744.0), 1344.0));
    assert!(close(3.6 * 720.0, 2592.0));
    assert!(close(slopes(-3.0, 0.5, 2.0), -6.0));
    assert!(close(corner_low(-3.0, 0.5, 2.0), -6.0));
}
```

**Entry** `two_slopes` · **Law** `none`

### A month is not 720 hours

```text
a month = [28, 30, 31] days × 24 = [672, 720, 744] hours
```

A reservation priced by the month converts to hours at whichever month it was, so the factor is a
range whose bounds are the calendar's: the shortest month and the longest. The 720 in the middle is
a thirty-day month, which is the convention a composer chose for the mode, not the average of the
year and not the most common length. A factor filed as a point would claim every month has the same
number of hours.

`merge-holding-composition` files the factor that turns the group's GPUs into GPU-hours as exactly
this range.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let holding = composition("corpus/merge-holding-composition.xml");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("a stated factor");
    assert!(close3(f, (28.0 * 24.0, 30.0 * 24.0, 31.0 * 24.0)));
    assert!(close3(f, (672.0, 720.0, 744.0)));

    // The months of an ordinary year and of a leap year, in hours: the shortest and the longest
    // are the factor's bounds, and 720 is a length some months have.
    for february in [28, 29] {
        let days = [31, february, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        let hours: Vec<f64> = days.iter().map(|d| (d * 24) as f64).collect();
        let shortest = hours.iter().cloned().fold(f64::INFINITY, f64::min);
        let longest = hours.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        assert!(shortest >= f.0 && longest == f.2);
        assert!(hours.contains(&f.1));
    }
}
```

**Entry** `month_hours` · **Law** `none`

### A cycle of conversions comes back

```text
x →(φ1) →(φ2) → ... →(φk) x      requires      1 ∈ φ1 × φ2 × ... × φk
```

Converting a quantity all the way round a cycle of units must be able to give back what it started
with. The factors are ranges, so the product round the loop is a range, and the most a receiver can
ask is that 1 lies inside it. Exact closure at the mode is out of reach for any document that files
decimals: a cycle through 720 needs the other factors to multiply to 1/720, and 720 = 2⁴ × 3² × 5,
while a product of terminating decimals has only twos and fives under the line. The nine is the
obstruction.

`every-unit-cycle` converts GPU-hours to node-hours at 0.125 and node-hours to GPUs at
[0.0108, 0.0112, 0.0116], and `merge-holding-composition` converts GPUs back to GPU-hours at
[672, 720, 744]. The product round the loop is [0.9072, 1.008, 1.0788], which contains 1, and its
mode is not 1.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let cycle = composition("fixtures/every-unit-cycle.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let to_node = factor(part(fusion(&cycle, "node-capacity"), "reserved-hours")).expect("stated");
    let to_gpu = factor(part(fusion(&cycle, "cards"), "node-capacity")).expect("stated");
    let to_hours = factor(part(fusion(&holding, "compute"), "compute-us")).expect("stated");
    assert!(close3(to_node, (0.125, 0.125, 0.125)));
    assert!(close3(to_gpu, (0.0108, 0.0112, 0.0116)));
    assert!(close3(to_hours, (672.0, 720.0, 744.0)));

    let product = (
        to_node.0 * to_gpu.0 * to_hours.0,
        to_node.1 * to_gpu.1 * to_hours.1,
        to_node.2 * to_gpu.2 * to_hours.2,
    );
    assert!(close3(product, (0.9072, 1.008, 1.0788)));
    assert!(product.0 <= 1.0 && 1.0 <= product.2);
    assert!(!close(product.1, 1.0));

    // 720 = 2^4 * 3^2 * 5.
    assert_eq!(2_i64.pow(4) * 3_i64.pow(2) * 5, 720);
    // Two terminating decimals p/10^i and q/10^j closing the loop exactly would need
    // 720 * p * q = 10^(i + j). Nine divides the left side and never a power of ten.
    for k in 0..=18 {
        assert_eq!(10_i64.pow(k) % 9, 1);
    }
    assert_eq!(720 % 9, 0);
}
```

**Entry** `cycle_closes` · **Rule** `checks/conversion_cycle_does_not_close`

### A path of conversions is one conversion

```text
Φ′(Φ x) = (Φ′Φ) x        at either bound and either sign, because a positive factor cannot move a sign
```

A factor is strictly positive, so the corner a bound takes is decided by the sign of what is being
converted, and converting cannot change that sign. The corner is therefore the same at every level of
a nesting, and a chain of factors collapses into their product. That is what lets a remainder walk
carry one running product per path and read one row per settled node instead of recursing, and it is
why nesting a composition adds witnesses rather than arithmetic: the composite has the folds of its
leaves and no others.

⛔ The collapse stops at a subtraction, not at a depth. A factor distributes over a sum of parts and
not over an elimination taken off one, so an intermediate elimination with width beneath a factor
with width is where the product may no longer be pushed down. That is the stopping rule
`composition/unsettled.sqlc` states and `composition/settled_remainders.sqlc` obeys, and it is why
the walk halts at a settled node rather than at a leaf.

`every-nested-conversion` is the corpus's two-level path. `line-hours` converts `line-runs` at
[0.8, 1.0, 1.25] and `line-batches` converts `line-hours` at [0.5, 1.0, 2.0], so the product down the
whole path is [0.4, 1.0, 2.5]. A remainder of 2 at the leaf reaches [0.8, 2.0, 5.0] either way:
stepwise it passes through 1.6 at the middle level and is halved, and in one conversion it is
multiplied by the product.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // One conversion of a signed quantity, at each bound: the corner its sign picks.
    let lo_of = |x: f64, lo: f64, hi: f64| (x * lo).min(x * hi);
    let hi_of = |x: f64, lo: f64, hi: f64| (x * lo).max(x * hi);

    // Two levels against one, over every whole operand either side of the fold and every pair of
    // whole positive corners.
    for x in -8..=8 {
        for a1 in 1..=4 {
            for a2 in a1..=4 {
                for b1 in 1..=4 {
                    for b2 in b1..=4 {
                        let (x, a1, a2) = (x as f64, a1 as f64, a2 as f64);
                        let (b1, b2) = (b1 as f64, b2 as f64);
                        assert_eq!(lo_of(lo_of(x, a1, a2), b1, b2), lo_of(x, a1 * b1, a2 * b2));
                        assert_eq!(hi_of(hi_of(x, a1, a2), b1, b2), hi_of(x, a1 * b1, a2 * b2));
                    }
                }
            }
        }
    }

    // The corpus's own nested path, read from the filing rather than restated.
    let nested = composition("fixtures/every-nested-conversion.xml");
    let inner = factor(part(fusion(&nested, "line-hours"), "line-runs")).expect("a stated factor");
    let outer = factor(part(fusion(&nested, "line-batches"), "line-hours")).expect("a stated factor");
    assert!(close3(inner, (0.8, 1.0, 1.25)) && close3(outer, (0.5, 1.0, 2.0)));

    let product = (inner.0 * outer.0, inner.1 * outer.1, inner.2 * outer.2);
    assert!(close3(product, (0.4, 1.0, 2.5)));

    let middle = lo_of(2.0, inner.0, inner.2);
    assert!(close(middle, 1.6));
    let stepwise = (
        lo_of(middle, outer.0, outer.2),
        2.0 * inner.1 * outer.1,
        hi_of(hi_of(2.0, inner.0, inner.2), outer.0, outer.2),
    );
    let at_once = (lo_of(2.0, product.0, product.2), 2.0 * product.1, hi_of(2.0, product.0, product.2));
    assert!(close3(stepwise, (0.8, 2.0, 5.0)) && close3(at_once, (0.8, 2.0, 5.0)));
}
```

**Entry** `conversion_collapses` · **Law** `none`

### Converted totals are correlated

```text
n_composed - d_composed, read crossed, counts φ's width twice; Σ φ r_parts counts it once

gap at each bound = d_part at that bound × (φ_high - φ_low) - (e_d_high - e_d_low)
```

One factor multiplies both a part's nameplate and its demand, so the two converted totals move
together. Differencing them with the bound reversal that independent quantities need pairs the
nameplate converted at the factor's low with the demand converted at its high, a month that is short
and long at once. The pivot through the parts converts each part's own remainder and never makes
that pairing. Both figures are arithmetic done correctly; only the pivot is the remainder.

For `merge-holding-composition`'s `compute` the pivot is [1414, 2857, 4085.6] and the converted
totals differenced give [1092, 2857, 4198.8]: equal at the mode, 322.0 wider at the low and 113.2
at the high. At the low that is the US demand's high of 6.0 times the factor's width of 72, less the
demand elimination's width of 110; at the high it is the demand's low of 3.1 times 72, less the same
110.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let compute = layer(&holding.process_modulus, "compute");
    let f = factor(part(fusion(&holding, "compute"), "compute-us")).expect("stated");
    let e_d = elimination(fusion(&holding, "compute"), EliminationAgainstType::Demand).expect("filed");

    let pivot = quantity(compute).expect("stated");
    let (n, d) = (nameplate(compute), demand(compute));
    let differenced = (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    assert!(close3(pivot, (1414.0, 2857.0, 4085.6)));
    assert!(close3(differenced, (1092.0, 2857.0, 4198.8)));
    assert!(close(pivot.1, differenced.1));

    let width = f.2 - f.0;
    let e_width = e_d.2 - e_d.0;
    assert!(close(width, 72.0) && close(e_width, 110.0));
    let d_us = demand(us);
    assert!(close(d_us.2, 6.0) && close(d_us.0, 3.1));
    assert!(close(pivot.0 - differenced.0, 322.0));
    assert!(close(pivot.0 - differenced.0, d_us.2 * width - e_width));
    assert!(close(differenced.2 - pivot.2, 113.2));
    assert!(close(differenced.2 - pivot.2, d_us.0 * width - e_width));
}
```

**Entry** `phi_correlated` · **Law** `algebra/composed_remainder` · **Rule** `checks/shares_do_not_sum`

## 6. The composed remainder

### The pivot through the parts

```text
r_composed = Σ Φ r_parts - e_n + e_d

each part's own remainder converted once; each elimination read at the corner of its own quantity
```

A composed layer's remainder is not its composed nameplate less its composed demand once a
conversion factor has width. One factor multiplies both a part's nameplate and its demand, so the
two converted totals move together, and differencing them as though they were independent counts
the factor's width twice. Converting each part's own remainder puts the factor on each term once.
Removing double-counted demand raises the remainder and removing double-counted nameplate lowers
it, each read where the quantity it was counted in is at the corner in play. Where no factor on the
way down has width the pivot equals the crossed difference of the composed totals exactly; where
one does, it lies inside it, equal at the mode.

`merge-holding-composition`'s `compute` fuses the group's `compute-us`, a remainder of
[2.0, 3.6, 4.9] GPU converted at [672, 720, 744], with its `compute-pt`, [30, 175, 290] GPU-hour:
[1344, 2592, 3645.6] plus [30, 175, 290] is [1374, 2767, 3935.6], and the demand elimination of
[40, 90, 150] brings it to [1414, 2857, 4085.6], the quantity the holding files. Its composed
totals differenced give [1092, 2857, 4198.8], wider at both ends. `every-local-part`'s
`both-views` sums two parts of [-240, 160, 360], eliminates a nameplate of 2160 and a demand of
[1800, 2000, 2400], and lands on [-240, 160, 360], exactly its own totals differenced.
`every-inverting-elimination`'s parts sum to [5, 7, 9], and its nameplate elimination, which that
sum read crossed, comes off as 5 at the low and 2 at the high: [0, 4, 7].

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let crossed = |n: Triple, d: Triple| (n.0 - d.2, n.1 - d.1, n.2 - d.0);
    let add = |a: Triple, b: Triple| (a.0 + b.0, a.1 + b.1, a.2 + b.2);
    let inside = |r: Triple, bound: Triple| bound.0 <= r.0 && r.2 <= bound.2;

    // merge-holding-composition/compute: a factor with width, and a positive remainder, so each
    // bound of the product is the factor's bound of the same name.
    let group = composition("corpus/merge-group-composition.xml");
    let holding = composition("corpus/merge-holding-composition.xml");
    let us = layer(&group.process_modulus, "compute-us");
    let pt = layer(&group.process_modulus, "compute-pt");
    let fusion_ = fusion(&holding, "compute");
    let f = factor(part(fusion_, "compute-us")).expect("a stated factor");
    let r_us = crossed(nameplate(us), demand(us));
    let r_pt = crossed(nameplate(pt), demand(pt));
    assert!(close3(r_us, (2.0, 3.6, 4.9)) && close3(f, (672.0, 720.0, 744.0)));
    assert!(close3(r_pt, (30.0, 175.0, 290.0)));
    let converted = (r_us.0 * f.0, r_us.1 * f.1, r_us.2 * f.2);
    assert!(close3(converted, (1344.0, 2592.0, 3645.6)));
    let parts = add(converted, r_pt);
    assert!(close3(parts, (1374.0, 2767.0, 3935.6)));
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let e_d = elimination(fusion_, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e_n, (0.0, 0.0, 0.0)) && close3(e_d, (40.0, 90.0, 150.0)));
    // With a spread factor and r > 0, both quantities are at their low at r's low.
    let pivot = (parts.0 - e_n.0 + e_d.0, parts.1 - e_n.1 + e_d.1, parts.2 - e_n.2 + e_d.2);
    assert!(close3(pivot, (1414.0, 2857.0, 4085.6)));
    let compute = layer(&holding.process_modulus, "compute");
    assert!(close3(quantity(compute).expect("stated"), pivot));
    let differenced = crossed(nameplate(compute), demand(compute));
    assert!(close3(differenced, (1092.0, 2857.0, 4198.8)));
    assert!(inside(pivot, differenced) && close(pivot.1, differenced.1));

    // every-local-part/both-views: no factor anywhere, so the pivot is the totals' difference.
    let local = composition("fixtures/every-local-part.xml");
    let fusion_ = fusion(&local, "both-views");
    let mut parts = (0.0, 0.0, 0.0);
    for p in &fusion_.part {
        let l = layer(&local.process_modulus, &p.layer.filing.id);
        let r = crossed(nameplate(l), demand(l));
        assert!(close3(r, (-240.0, 160.0, 360.0)));
        parts = add(parts, r);
    }
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let e_d = elimination(fusion_, EliminationAgainstType::Demand).expect("filed");
    assert!(close3(e_n, (2160.0, 2160.0, 2160.0)) && close3(e_d, (1800.0, 2000.0, 2400.0)));
    // No spread: r's low takes the nameplate at its low and the demand at its high.
    let pivot = (parts.0 - e_n.0 + e_d.2, parts.1 - e_n.1 + e_d.1, parts.2 - e_n.2 + e_d.0);
    assert!(close3(pivot, (-240.0, 160.0, 360.0)));
    let both = layer(&local.process_modulus, "both-views");
    assert!(close3(pivot, crossed(nameplate(both), demand(both))));

    // every-inverting-elimination: the nameplate sum was read crossed, so its elimination is at
    // its high where the nameplate is at its low.
    let inverting = composition("fixtures/every-inverting-elimination.xml");
    let fusion_ = fusion(&inverting, "shift-capacity");
    let mut parts = (0.0, 0.0, 0.0);
    for p in &fusion_.part {
        let l = layer(&inverting.process_modulus, &p.layer.filing.id);
        parts = add(parts, crossed(nameplate(l), demand(l)));
    }
    assert!(close3(parts, (5.0, 7.0, 9.0)));
    let e_n = elimination(fusion_, EliminationAgainstType::Nameplate).expect("filed");
    let (n_at_low, n_at_high) = (e_n.2, e_n.0);
    assert!(close(n_at_low, 5.0) && close(n_at_high, 2.0));
    let pivot = (parts.0 - n_at_low, parts.1 - e_n.1, parts.2 - n_at_high);
    assert!(close3(pivot, (0.0, 4.0, 7.0)));
    let composed = layer(&inverting.process_modulus, "shift-capacity");
    assert!(close3(pivot, crossed(nameplate(composed), demand(composed))));

    // Two parts with no factor, on a grid of whole numbers: with each elimination read at its own
    // quantity's corners, the pivot is always ordered and always the composed totals' crossed
    // difference.
    let mut claims = Vec::new();
    for low in 0..=2 {
        for mode in low..=2 {
            for high in mode..=2 {
                claims.push((low as f64, mode as f64, high as f64));
            }
        }
    }
    let sum_rule = |t: Triple, e: Triple| {
        let b = (t.0 - e.0, t.1 - e.1, t.2 - e.2);
        if b.0 <= b.1 && b.1 <= b.2 { (b, false) } else { ((t.0 - e.2, t.1 - e.1, t.2 - e.0), true) }
    };
    for &n1 in &claims {
        for &d1 in &claims {
            for &n2 in &claims {
                for &d2 in &claims {
                    for &e_n in &claims {
                        for &e_d in &claims {
                            let (n_c, n_crossed) = sum_rule(add(n1, n2), e_n);
                            let (d_c, d_crossed) = sum_rule(add(d1, d2), e_d);
                            let (n_lo, n_hi) = if n_crossed { (e_n.2, e_n.0) } else { (e_n.0, e_n.2) };
                            let (d_lo, d_hi) = if d_crossed { (e_d.2, e_d.0) } else { (e_d.0, e_d.2) };
                            let parts = add(crossed(n1, d1), crossed(n2, d2));
                            let pivot = (parts.0 - n_lo + d_hi, parts.1 - e_n.1 + e_d.1, parts.2 - n_hi + d_lo);
                            assert_eq!(pivot, crossed(n_c, d_c));
                        }
                    }
                }
            }
        }
    }
}
```

**Entry** `composed_remainder` · **Law** `algebra/composed_remainder` · **Rule** `checks/shares_do_not_sum`, `checks/stated_quantity_is_not_the_magnitude`

## 7. Windows and duty cycles

### A duty cycle folds into a rate

```text
delivered per period = rate while running × window ÷ period × period = rate while running × window
```

A supply that runs only part of each period files its nameplate per period, and the window says how
much of the period it runs. The rate while it runs is the nameplate over the window, not over the
period. The duty cycle then vanishes from the nameplate: two lines with one daily output and
different schedules file the same figure, and only the window tells them apart.

The schema's own line runs 02:00 to 05:00 at one muffin every five seconds: 10800 seconds over 5 is
2160 muffins a day, and 720 an hour while it runs. `merge-us-member`'s `shift-line` runs 5 days a
week and files 10 shifts a week, so it makes 2 shifts a running day.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let window_seconds = 3.0 * 3600.0;
    assert!(close(window_seconds, 10800.0));
    let per_day = window_seconds / 5.0;
    assert!(close(per_day, 2160.0));
    let per_running_hour = 3600.0 / 5.0;
    assert!(close(per_running_hour, 720.0) && close(per_running_hour * 3.0, per_day));

    let us = filing("corpus/merge-us-member.xml");
    let line = layer(&us, "shift-line");
    let (w, unit) = window(line).expect("a window");
    assert_eq!(unit, "days");
    assert!(close3(w, (5.0, 5.0, 5.0)) && close3(nameplate(line), (10.0, 10.0, 10.0)));
    let per_running_day = nameplate(line).1 / w.1;
    assert!(close(per_running_day, 2.0));
    assert!(close(per_running_day * w.1, nameplate(line).1));
}
```

**Entry** `duty_cycle` · **Rule** `checks/derived_slack_over_a_window`

### A clearance is not a duration

```text
time slack (filed)   = clearance = max(n - d, 0)         a quantity in the layer's unit
the wait it implies  = q / clearance                     a duration, where q is a count
```

`timeSlack` holds how much demand survives being held, as a quantity in the layer's unit, because it
is compared against holder shares in that unit. The wait a late unit has is a different figure in a
different dimension describing the same supply. Filed as a `clearance` derivation, the slack is the
clearance, and dividing a quantum by it gives a duration only when the quantum is a count and the
clearance a rate; two figures in one unit divide to a pure number.

On a belt with a hundred slots an hour carrying ninety-five muffins the slack is 5 muffins an hour,
and a late muffin waits 1 over 5 of an hour, 12 minutes. `every-absence`'s oven files its time slack
as a `clearance` derivation: its clearance at the mode is 2160 less 2000, 160 muffins a day, and its
quantum of 12 muffins a day over that is 0.075, a ratio and not a duration.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let (slots, muffins) = (100.0, 95.0);
    let slack_per_hour = slots - muffins;
    assert!(close(slack_per_hour, 5.0));
    let wait_minutes = 1.0 / slack_per_hour * 60.0;
    assert!(close(wait_minutes, 12.0));

    let bakery = filing("fixtures/every-absence.xml");
    let oven = layer(&bakery, "oven");
    assert_eq!(derivation(&oven.time_slack), Some(&IdentityType::Clearance));
    let (n, d) = (nameplate(oven), demand(oven));
    assert!(close(n.1, 2160.0) && close(d.1, 2000.0));
    let clearance = (n.1 - d.1).max(0.0);
    assert!(close(clearance, 160.0));
    let q = quantum(oven).expect("lumpy").1;
    assert!(close(q, 12.0));
    assert_eq!(unit(&oven.supply.nameplate.amount), unit(&oven.demand.amount));
    assert!(close(q / clearance, 0.075));
}
```

**Entry** `clearance_is_not_a_duration` · **Rule** `checks/derived_slack_over_a_window`

### A slack observed as a duration

```text
wait × slack = q          so          slack = q / wait
```

A buffer's size is naturally observed as a duration, and filed as a quantity in the layer's unit,
so the filer owes the conversion before filing. The quantum that waits, over the wait, is the slack.
And the conversion does not survive a duty cycle the other way round: averaging a clearance over the
whole period gives a wait that happens nowhere.

The belt's twelve-minute wait for one muffin is a slack of 5 an hour. The schema's line makes 2160
muffins a day in three hours against a demand of 2000, a clearance of 160 a day: spread over the
whole day that is one every 9 minutes, inside the window one every 67.5 seconds, and outside the
window a missed order waits 21 hours. Nine minutes occurs nowhere on that line.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let (q, wait_hours) = (1.0, 12.0 / 60.0);
    let slack = q / wait_hours;
    assert!(close(slack, 5.0) && close(wait_hours * slack, q));

    let clearance = 2160.0 - 2000.0;
    assert!(close(clearance, 160.0));
    let over_the_day_minutes = 24.0 * 60.0 / clearance;
    assert!(close(over_the_day_minutes, 9.0));
    let inside_the_window_seconds = 3.0 * 3600.0 / clearance;
    assert!(close(inside_the_window_seconds, 67.5));
    let outside_the_window_hours = 24.0 - 3.0;
    assert!(close(outside_the_window_hours, 21.0));
}
```

**Entry** `slack_from_duration` · **Law** `none`

### The queue settles at its patience

```text
patience W = time slack / service rate μ
equilibrium depth = μ W                      departure rate = λ - μ = the unserved shares' sum
```

A queue whose customers leave after a patience is stable whatever the load: the backlog grows until
the wait reaches the patience, and from then on demand leaves at the rate the excess arrives. That
result is cited below; the arithmetic around it is checked here. The departure rate is the demand
less the service rate at the mode, which is the remainder's magnitude, so the sum rule and the
queueing equilibrium must agree.

`merge-holding-composition`'s `shift-line` serves 10 shifts a week against a demand whose mode is
12.7, with a time slack whose mode is 2.5 shifts. The patience is 2.5 over 10, a quarter of a week,
the equilibrium depth is 10 times that, 2.5, and the departure rate is 2.7 a week: exactly the
`customer` share of 1.7 and the `unrealised` share of 1.0 the holding files.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let holding = composition("corpus/merge-holding-composition.xml");
    let line = layer(&holding.process_modulus, "shift-line");
    let mu = nameplate(line).1;
    let lambda = demand(line).1;
    let slack = claim(&line.time_slack).expect("stated").1;
    assert!(close(mu, 10.0) && close(lambda, 12.7) && close(slack, 2.5));

    let patience = slack / mu;
    assert!(close(patience, 0.25));
    assert!(close(mu * patience, 2.5));
    let departing = lambda - mu;
    assert!(close(departing, 2.7));

    let unserved: Vec<f64> = holders(line)
        .into_iter()
        .filter(|(k, _)| matches!(k, HolderKindType::Customer | HolderKindType::Unrealised))
        .map(|(_, s)| s.expect("stated").1)
        .collect();
    assert!(close(unserved[0], 1.7) && close(unserved[1], 1.0));
    assert!(close(unserved.iter().sum::<f64>(), departing));
}
```

**Entry** `queue_arithmetic` · **Rule** `checks/shares_do_not_sum`

### Cited, not proven

Two queueing results the entries above rely on and do not prove:

- A multi-server queue with customers who abandon after an exponential patience is stable at any
  load, including one above capacity. Garnett, Mandelbaum and Reiman, "Designing a Call Center with
  Impatient Customers", *Manufacturing & Service Operations Management* 4(3), 2002.
- In the fluid limit of such a queue under overload, the queue settles where the wait equals the
  patience and customers abandon at the rate the excess arrives. Whitt, "Fluid Models for
  Multiserver Queues with Abandonments", *Operations Research* 54(1), 2006.

## 8. Counting

### The twelvefold way

```text
f: N -> X, |N| = n, |X| = x          any              injective          surjective
labelled                             x^n              x!/(x-n)!          x! S(n, x)
up to the balls (N unlabelled)       C(x+n-1, n)      C(x, n)            C(n-1, x-1)
up to the boxes (X unlabelled)       Σ_k≤x S(n, k)    [n <= x]           S(n, x)
up to both                           p_≤x(n)          [n <= x]           p_x(n)
```

Every classification a query makes is a function from its rows to a set of classes, and these
twelve counts are how many such functions there are, depending on whether the rows and the classes
are told apart and whether the function must be injective or onto. `GROUP BY` reads a function up to
its rows, a kernel reads it up to its classes, and a profile reads it up to both, so the four rows of
the table are four things a relation can report. The table is Stanley's twelvefold way, in
*Enumerative Combinatorics*, volume 1, chapter 1; the block counts every cell by brute force and
checks it against the formula.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    fn binomial(n: i64, k: i64) -> i64 {
        if k < 0 || k > n {
            return 0;
        }
        (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1))
    }
    fn stirling2(n: i64, k: i64) -> i64 {
        match (n, k) {
            (0, 0) => 1,
            (_, 0) | (0, _) => 0,
            _ => k * stirling2(n - 1, k) + stirling2(n - 1, k - 1),
        }
    }
    // Partitions of n into exactly k parts.
    fn parts(n: i64, k: i64) -> i64 {
        match (n, k) {
            (0, 0) => 1,
            _ if n <= 0 || k <= 0 => 0,
            _ => parts(n - 1, k - 1) + parts(n - k, k),
        }
    }
    let factorial = |n: i64| (1..=n).product::<i64>();

    for n in 0..=4_i64 {
        for x in 0..=4_i64 {
            // Every function from n rows to x classes, as a tuple of images.
            let mut functions: Vec<Vec<i64>> = vec![vec![]];
            for _ in 0..n {
                functions = functions
                    .into_iter()
                    .flat_map(|f| (0..x).map(move |c| [f.clone(), vec![c]].concat()))
                    .collect();
            }
            let injective = |f: &Vec<i64>| {
                let mut seen = f.clone();
                seen.sort();
                seen.dedup();
                seen.len() == f.len()
            };
            let surjective = |f: &Vec<i64>| (0..x).all(|c| f.contains(&c));
            // Up to the balls: the multiset of images. Up to the boxes: images renamed in order
            // of first appearance. Up to both: the sorted sizes of the non-empty classes.
            let balls = |f: &Vec<i64>| {
                let mut v = f.clone();
                v.sort();
                v
            };
            let boxes = |f: &Vec<i64>| {
                let mut names: Vec<i64> = Vec::new();
                f.iter()
                    .map(|c| match names.iter().position(|m| m == c) {
                        Some(i) => i as i64,
                        None => {
                            names.push(*c);
                            names.len() as i64 - 1
                        }
                    })
                    .collect::<Vec<i64>>()
            };
            let both = |f: &Vec<i64>| {
                let mut sizes: Vec<i64> =
                    (0..x).map(|c| f.iter().filter(|&&i| i == c).count() as i64).filter(|&k| k > 0).collect();
                sizes.sort();
                sizes
            };
            let count = |keep: &dyn Fn(&Vec<i64>) -> bool, key: &dyn Fn(&Vec<i64>) -> Vec<i64>| {
                let mut keys: Vec<Vec<i64>> = functions.iter().filter(|f| keep(f)).map(|f| key(f)).collect();
                keys.sort();
                keys.dedup();
                keys.len() as i64
            };
            let any = |_: &Vec<i64>| true;
            let same = |f: &Vec<i64>| f.clone();
            let fits = if n <= x { 1 } else { 0 };

            assert_eq!(count(&any, &same), x.pow(n as u32));
            assert_eq!(count(&injective, &same), if n <= x { factorial(x) / factorial(x - n) } else { 0 });
            assert_eq!(count(&surjective, &same), factorial(x) * stirling2(n, x));
            assert_eq!(count(&any, &balls), if x == 0 { if n == 0 { 1 } else { 0 } } else { binomial(x + n - 1, n) });
            assert_eq!(count(&injective, &balls), binomial(x, n));
            assert_eq!(count(&surjective, &balls), if n == 0 && x == 0 { 1 } else { binomial(n - 1, x - 1) });
            assert_eq!(count(&any, &boxes), (0..=x).map(|k| stirling2(n, k)).sum::<i64>());
            assert_eq!(count(&injective, &boxes), fits);
            assert_eq!(count(&surjective, &boxes), stirling2(n, x));
            assert_eq!(count(&any, &both), (0..=x).map(|k| parts(n, k)).sum::<i64>());
            assert_eq!(count(&injective, &both), fits);
            assert_eq!(count(&surjective, &both), parts(n, x));
        }
    }
}
```

**Entry** `twelvefold` · **Law** `none`

### A self-join's size is fixed by its group sizes

```text
on a key whose groups have sizes k:
    ordered pairs, reflexive kept      Σ k²
    ordered pairs, reflexive dropped   Σ k(k-1)
    unordered pairs                    Σ C(k, 2)        = Σ k(k-1) / 2
```

Joining a relation to itself on a key pairs every row with every row of its group, so the size of
the result is decided by the group sizes alone, whatever else the rows carry. Which of the three a
relation computes is a choice about whether a row pairs with itself and whether a pair is counted in
both orders, and a relation that gets it wrong reports a plausible count.

Across every composition loaded, a part is named by some number of fusions. `every-absence`'s oven is
named by two, `every-elimination`'s `baking` and `every-local-part`'s `as-filed`, so it contributes 4
to the first sum, 2 to the second and 1 to the third: the one pair of composed layers that would
count its supply twice if anybody added them.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let documents = [
        "corpus/merge-group-composition.xml",
        "corpus/merge-holding-composition.xml",
        "fixtures/every-elimination.xml",
        "fixtures/every-local-part.xml",
        "fixtures/every-partial-elimination.xml",
        "fixtures/every-inverting-elimination.xml",
        "fixtures/every-nested-conversion.xml",
        "fixtures/every-unit-cycle.xml",
        "fixtures/every-unsized-conversion.xml",
    ];
    // How many fusion entries name each part, keyed by the part's notation and layer.
    let mut named: std::collections::BTreeMap<(String, String), i64> = Default::default();
    for d in documents {
        let c = composition(d);
        for f in &c.fusion {
            for p in &f.part {
                *named.entry((p.layer.filing.notation.clone(), p.layer.filing.id.clone())).or_default() += 1;
            }
        }
    }
    let k: Vec<i64> = named.values().cloned().collect();
    let squares: i64 = k.iter().map(|k| k * k).sum();
    let ordered: i64 = k.iter().map(|k| k * (k - 1)).sum();
    let unordered: i64 = k.iter().map(|k| k * (k - 1) / 2).sum();
    assert_eq!(squares, k.iter().sum::<i64>() + ordered);
    assert_eq!(2 * unordered, ordered);

    let oven = named
        .iter()
        .find(|((notation, id), _)| notation.ends_with("every-absence") && id == "oven")
        .map(|(_, k)| *k)
        .expect("the oven is a part");
    assert_eq!((oven * oven, oven * (oven - 1), oven * (oven - 1) / 2), (4, 2, 1));
    assert_eq!(unordered, 1);

    // On every list of group sizes up to a small bound, the three sums keep their relation.
    for a in 0..=5_i64 {
        for b in 0..=5_i64 {
            for c in 0..=5_i64 {
                let k = [a, b, c];
                let sq: i64 = k.iter().map(|k| k * k).sum();
                let ord: i64 = k.iter().map(|k| k * (k - 1)).sum();
                let unord: i64 = k.iter().map(|k| k * (k - 1) / 2).sum();
                assert_eq!(sq, k.iter().sum::<i64>() + ord);
                assert_eq!(2 * unord, ord);
            }
        }
    }
}
```

**Entry** `self_join_sizes` · **Law** `none`

### The excess of a sum over its image

```text
Σ_rows w(f(row)) = Σ_class |f⁻¹(class)| · w(class)        excess over the image = Σ (k - 1) · w
k - 1 = C(k, 2) only where k is 1 or 2
```

Summing a weight over rows counts each class once per row that lands in it, so a class reached k
times contributes its weight k times, and the excess over counting each class once is `(k - 1) · w`.
That excess is the elimination `e` in `x_composed = Σ x_parts - e`: it is why a query may compose a
child twice and a fusion may not reach one layer twice. Under an idempotent fold, a union, a `max`
or an `EXISTS`, the multiplicity vanishes and there is no excess. The excess is not the number of
pairs: `k - 1` and `C(k, 2)` agree only where k is 1 or 2, and at 3 a class is overcounted twice and
forms three pairs.

Adding `every-elimination`'s `baking` to `every-local-part`'s `as-filed` counts `every-absence`'s oven
twice: its nameplate of 2160 muffins a day enters the sum as 4320, an excess of 2160.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let bakery = filing("fixtures/every-absence.xml");
    let w = nameplate(layer(&bakery, "oven")).1;
    assert!(close(w, 2160.0));
    let k = 2.0;
    assert!(close(k * w, 4320.0) && close((k - 1.0) * w, 2160.0));

    for k in 0..=12_i64 {
        let pairs = k * (k - 1) / 2;
        assert_eq!(k - 1 == pairs, k == 1 || k == 2);
    }
    assert_eq!((3 - 1, 3 * 2 / 2), (2, 3));

    // The identity on every assignment of four rows to three classes with weights 1, 10, 100.
    let weights = [1_i64, 10, 100];
    for code in 0..81 {
        let rows: Vec<usize> = (0..4).map(|i| (code / 3_i64.pow(i)) as usize % 3).collect();
        let by_row: i64 = rows.iter().map(|&c| weights[c]).sum();
        let by_class: i64 = (0..3)
            .map(|c| rows.iter().filter(|&&r| r == c).count() as i64 * weights[c])
            .sum();
        let image: i64 = (0..3).filter(|c| rows.contains(c)).map(|c| weights[c]).sum();
        let excess: i64 = (0..3)
            .map(|c| (rows.iter().filter(|&&r| r == c).count() as i64 - 1).max(0) * weights[c])
            .sum();
        assert_eq!(by_row, by_class);
        assert_eq!(by_row - image, excess);
    }
}
```

**Entry** `excess` · **Law** `none`

### The kernel of a fold is its excess

```text
f: N -> X a function, F its incidence with one 1 per column, Phi a positive diagonal
  rank(F Phi)    = |image f|
  dim ker(F Phi) = |N| - |image f| = the sum over boxes of (fibre size - 1)
```

The excess a sum carries over its image is the entry above, and read as a matrix that same number
is a DIMENSION. A ball moved from one box-mate to another, scaled by their two factors, changes
nothing the fold can see. So the excess at a weight is a magnitude and the excess at weight one is
the dimension of the space of moves the fold is blind to, and the two are one sum.

The dimension cannot depend on the factors. `Phi` scales each column by a positive number, which
moves no column into or out of the span of the others, so the rank is settled by the incidence
alone. The DIRECTION of a move is not settled by it: a generator is one unit at one ball against
one unit at another, which in their own units is the reciprocal of each factor, and it carries
whatever width the factors have. The dimension is whole and the direction is metered.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Rank by elimination with partial pivoting. No decomposition and no magnitudes: the answer
    // must depend only on which balls share a box.
    fn rank(mut a: Vec<Vec<f64>>, rows: usize, cols: usize) -> usize {
        let mut r = 0;
        for c in 0..cols {
            if r == rows {
                break;
            }
            let p = (r..rows)
                .max_by(|&i, &j| a[i][c].abs().partial_cmp(&a[j][c].abs()).expect("finite"))
                .expect("r < rows");
            if a[p][c].abs() < 1e-9 {
                continue;
            }
            a.swap(r, p);
            let piv = a[r][c];
            for i in 0..rows {
                if i != r && a[i][c].abs() > 0.0 {
                    let f = a[i][c] / piv;
                    for j in c..cols {
                        a[i][j] -= f * a[r][j];
                    }
                }
            }
            r += 1;
        }
        r
    }

    // Every function from n labelled balls into x labelled boxes.
    let mut seen = 0;
    for n in 1..=5usize {
        for x in 1..=4usize {
            let mut assign = vec![0usize; n];
            loop {
                // One 1 per column, scaled by a positive factor that differs column by column.
                let mut f = vec![vec![0.0; n]; x];
                for (j, &i) in assign.iter().enumerate() {
                    f[i][j] = 1.0 + (j as f64) * 0.75;
                }
                let image: std::collections::BTreeSet<usize> = assign.iter().copied().collect();
                let excess: usize = image
                    .iter()
                    .map(|&i| assign.iter().filter(|&&a| a == i).count() - 1)
                    .sum();

                // The rank is the image, so the nullity is the excess.
                assert_eq!(rank(f.clone(), x, n), image.len());
                assert_eq!(n - rank(f.clone(), x, n), excess);

                // And the factors moved none of it: the same incidence, every entry at one.
                let mut bare = vec![vec![0.0; n]; x];
                for (j, &i) in assign.iter().enumerate() {
                    bare[i][j] = 1.0;
                }
                assert_eq!(rank(bare, x, n), rank(f, x, n));
                seen += 1;

                let mut k = 0;
                while k < n {
                    assign[k] += 1;
                    if assign[k] < x {
                        break;
                    }
                    assign[k] = 0;
                    k += 1;
                }
                if k == n {
                    break;
                }
            }
        }
    }
    assert!(seen > 0);
}
```

**Entry** `kernel_is_the_excess` · **Law** `none`

### Decimal figures do not add exactly in floating point

```text
10.0 - 10.4 = -0.40000000000000036 in f64
```

A `Claim` holds `f64`, and most one-decimal figures have no exact binary form, so a sum computed
from them can miss the figure written for the sum. Every comparison this repository makes between a
computed figure and a filed one therefore allows 1e-9. Of the ordered pairs of one-decimal values
from 0.1 to 19.9, 39,601 of them, 7,168 fail an exact equality against their own sum, and none
misses it by as much as that tolerance.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    assert_eq!(format!("{}", 10.0_f64 - 10.4), "-0.40000000000000036");
    let (mut pairs, mut inexact) = (0, 0);
    for i in 1..=199 {
        for j in 1..=199 {
            let (a, b, written) = (i as f64 / 10.0, j as f64 / 10.0, (i + j) as f64 / 10.0);
            pairs += 1;
            if a + b != written {
                inexact += 1;
            }
            assert!(close(a + b, written));
        }
    }
    assert_eq!((pairs, inexact), (39601, 7168));
    assert!(close(0.1 * 1.0, 0.1) && close(19.9, 199.0 / 10.0));
}
```

**Entry** `float_sums` · **Law** `none`

### The pieces a composed figure is linear on

```text
P parts, each folding where its own remainder passes zero:  2^P pieces, and depth does not move it
  the count is 2^P because each part files its own n and its own d, so the P folds are independent
  parts constrained to share a figure leave some sign patterns unreachable, and the count falls
```

A composed figure is a sum over its parts, each converted, and a part's conversion changes slope
only where that part's own remainder passes zero. The folds are therefore the `P` coordinate
hyperplanes through the origin, one per part, and they cut the space of part remainders into its sign
orthants. The figure is one linear function on each, and no coarser division will do, because
crossing a single fold changes exactly one part's slope and so changes the function.

⭐ The count is fixed by the number of parts and not by how deeply the composition nests. A path of
conversions collapses into one conversion, entry `conversion_collapses`, so a composition of any
depth carries the folds of its leaves and no others. An operator whose folds could be placed away
from the origin would multiply its pieces with depth instead; this one cannot, because a positive
factor cannot move a sign.

⚠️ **The exponent is a consequence and not a given.** `P` folds cut a space into `2^P` pieces only
where the folds are independent, and here they are because each part files its own nameplate and
its own demand, so the space the folds live in has room for every sign pattern. Parts constrained
to share a figure would leave some patterns unreachable and the count would fall below `2^P`. The
independence is a fact about what a filing may say, so it is worth naming rather than assuming.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A composed figure's low bound over P parts: each part converted at the corner its own sign
    // picks, then summed.
    let low = |rs: &[f64], los: &[f64], his: &[f64]| -> f64 {
        rs.iter()
            .zip(los)
            .zip(his)
            .map(|((r, lo), hi)| (r * lo).min(r * hi))
            .sum()
    };

    for p in 1..=6usize {
        let (los, his) = (vec![2.0; p], vec![5.0; p]);
        let mut pieces = std::collections::BTreeSet::new();
        for mask in 0..(1u32 << p) {
            let rs: Vec<f64> =
                (0..p).map(|i| if mask >> i & 1 == 1 { 3.0 } else { -3.0 }).collect();
            // The slope pattern this orthant uses IS the piece.
            let taken: Vec<bool> = rs.iter().map(|r| *r < 0.0).collect();
            pieces.insert(taken.clone());
            // And on this orthant the sum really is that one linear function.
            let expect: f64 = rs
                .iter()
                .zip(&taken)
                .map(|(r, negative)| if *negative { r * 5.0 } else { r * 2.0 })
                .sum();
            assert_eq!(low(&rs, &los, &his), expect);
        }
        assert_eq!(pieces.len(), 1usize << p);
    }

    // No coarser division will do: crossing one fold changes the function, so two orthants that
    // differ in a single sign are never the same piece.
    let (los, his) = (vec![2.0; 3], vec![5.0; 3]);
    let a = [3.0, 3.0, 3.0];
    let b = [3.0, -3.0, 3.0];
    assert!(low(&a, &los, &his) != low(&b, &los, &his));

    // ⛔ And the exponent rests on the folds being independent. Tie two parts to one figure and
    // two of the four sign patterns become unreachable, so the pieces fall from four to two.
    let mut tied = std::collections::BTreeSet::new();
    for mask in 0..4u32 {
        let first: f64 = if mask & 1 == 1 { 3.0 } else { -3.0 };
        let second: f64 = if mask >> 1 & 1 == 1 { 3.0 } else { -3.0 };
        // The constraint a shared figure imposes: the two remainders are the same number.
        if (first - second).abs() > 1e-9 {
            continue;
        }
        tied.insert(vec![first < 0.0, second < 0.0]);
    }
    assert_eq!(tied.len(), 2);
    assert!(tied.len() < 1usize << 2);
}
```

**Entry** `orthants` · **Law** `none`

## 9. Set algebra

### A difference and its semijoin partition the left side

```text
|A| = |A ∖ B| + |A ⋉ B|
```

Every row of `A` either has a match in `B` or does not, so the rows a difference keeps and the rows
a semijoin keeps are the whole of `A`, with nothing in both. A difference that is wrong still returns
a plausible table, so this identity is what the laws on `algebra/roster.sqlc` assert for every set
difference in the tree. It holds for a bag only when the difference keeps duplicates, as an anti-join
does; `EXCEPT` removes them, and on a bag the two sides then stop adding up.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every pair of subsets of a five-element universe, as bit masks.
    for a in 0..32_u32 {
        for b in 0..32_u32 {
            let difference = (a & !b).count_ones();
            let semijoin = (a & b).count_ones();
            assert_eq!(a.count_ones(), difference + semijoin);
            assert_eq!((a & !b) & (a & b), 0);
        }
    }

    // A bag with a duplicate: the anti-join keeps it and the partition holds; EXCEPT drops it.
    let a = [1, 1, 2, 3];
    let b = [3];
    let anti: Vec<i32> = a.iter().cloned().filter(|x| !b.contains(x)).collect();
    let semi: Vec<i32> = a.iter().cloned().filter(|x| b.contains(x)).collect();
    assert_eq!(a.len(), anti.len() + semi.len());
    let mut except = anti.clone();
    except.dedup();
    assert_eq!(except, vec![1, 2]);
    assert_ne!(a.len(), except.len() + semi.len());
}
```

**Entry** `difference_partition` · **Law** `algebra/owed_equality`

### A selection accumulates

```text
σ_p(σ_q(A)) = σ_{p ∧ q}(A)
```

Filtering a filtered relation is filtering once by both conditions, so a rule that composes a
population inherits every filter inside it, including ones its author never wrote. The population a
rule examines is decided in the files it composes, not only in its own.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every relation over a five-element universe, against every pair of predicates on it.
    for a in 0..32_u32 {
        for p in 0..32_u32 {
            for q in 0..32_u32 {
                assert_eq!((a & q) & p, a & (p & q));
            }
        }
    }
}
```

**Entry** `selection_accumulates` · **Law** `none`

### A projection does not distribute over a difference

```text
π(A ∖ B) ≠ π(A) ∖ π(B)        in general
```

Projecting first and subtracting after compares fewer attributes, so two rows that differ only in a
column the projection drops cancel each other. A difference has to be taken on the key and projected
afterwards.

With `A = {(1, x)}` and `B = {(1, y)}`, the difference keeps `(1, x)` and projects to `{1}`, while the
projections are both `{1}` and subtract to nothing.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    let a = [(1, 'x')];
    let b = [(1, 'y')];
    let difference: Vec<(i32, char)> = a.iter().cloned().filter(|r| !b.contains(r)).collect();
    let projected_after: Vec<i32> = difference.iter().map(|r| r.0).collect();
    let pa: Vec<i32> = a.iter().map(|r| r.0).collect();
    let pb: Vec<i32> = b.iter().map(|r| r.0).collect();
    let projected_first: Vec<i32> = pa.iter().cloned().filter(|k| !pb.contains(k)).collect();
    assert_eq!(projected_after, vec![1]);
    assert!(projected_first.is_empty());
}
```

**Entry** `projection_counterexample` · **Law** `none`

### A pin answers for the whole relation on two conditions

```text
σ_{c = v}(A) answers for A   ⟺   v reaches every key  ∧  u is constant on the key
```

Pinning one value of a column and dropping the column is how a relation at a fine grain gets read at
a coarse one. It answers for the relation it sliced when the keys are the same, each carries one
payload, and that payload is the one the whole relation carries. Both conditions are needed and
neither implies the other: a key with no row at `v` is dropped by the slice and kept by the
aggregate, and a key carrying two payloads is answered with one of the two.

This is the one case where a `σπ` and a `γ` are the same relation. Everywhere else they have the
same key, the same arity and one row per key, and no cardinality law separates them.

`units/conversions.sqlc` reads the whole conversion graph off `quantity = 'nameplate'`. The unit it
puts on an edge is the layer's unit only while a layer names one unit across its quantities, and the
edge exists at all only while every part with a stated factor files a nameplate.
`algebra/layer_units` is those two conditions, one subject each.

The search below is every relation over two keys, two values of the pinned column and two payloads,
which is 256 of them. It counts the relations satisfying one condition and failing the other, so
neither half is vacuous over the universe it was proved on.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every relation over two keys, two values of the pinned column and two payloads: the subsets
    // of the eight cells (key, column, payload), as bit masks.
    let holds = |r: u32, k: u32, c: u32, u: u32| r & (1 << (k * 4 + c * 2 + u)) != 0;
    let (mut reach_only, mut constant_only) = (0, 0);
    for r in 0..256_u32 {
        let keys: Vec<u32> =
            (0..2).filter(|&k| (0..2).any(|c| (0..2).any(|u| holds(r, k, c, u)))).collect();
        // The slice pins the column at v = 0 and drops it. The aggregate keeps every payload.
        let slice = |k: u32| (0..2).filter(|&u| holds(r, k, 0, u)).collect::<Vec<u32>>();
        let whole =
            |k: u32| (0..2).filter(|&u| (0..2).any(|c| holds(r, k, c, u))).collect::<Vec<u32>>();

        let reaches = keys.iter().all(|&k| !slice(k).is_empty());
        let constant = keys.iter().all(|&k| whole(k).len() == 1);
        let answers_for_it = keys.iter().all(|&k| slice(k) == whole(k) && whole(k).len() == 1);

        assert_eq!(answers_for_it, reaches && constant);
        constant_only += i32::from(reaches && !constant);
        reach_only += i32::from(constant && !reaches);
    }
    // Neither half implies the other, so a law holding one of them passes on relations the
    // other rejects.
    assert!(reach_only > 0 && constant_only > 0);

    // The two failures in the terms the tree uses, one per condition.
    let absent_nameplate = [("demand", "hours")];
    let two_units = [("demand", "hours"), ("nameplate", "shifts")];
    let at_the_pin = |rows: &[(&str, &str)]| {
        rows.iter().filter(|r| r.0 == "nameplate").map(|r| r.1.to_string()).collect::<Vec<String>>()
    };
    let every_unit = |rows: &[(&str, &str)]| {
        let mut u = rows.iter().map(|r| r.1.to_string()).collect::<Vec<String>>();
        u.sort();
        u.dedup();
        u
    };
    // No nameplate: the pin has nothing to read and the layer still names a unit.
    assert!(at_the_pin(&absent_nameplate).is_empty());
    assert_eq!(every_unit(&absent_nameplate), vec!["hours"]);
    // Two units: the pin reads one of them and reports no disagreement.
    assert_eq!(at_the_pin(&two_units), vec!["shifts"]);
    assert_eq!(every_unit(&two_units), vec!["hours", "shifts"]);
}
```

**Entry** `pin_is_the_whole_relation` · **Law** `algebra/layer_units`

### A CASE is a partition whatever its arms say

```text
Σ |classes| = |candidates|        for any CASE, overlapping arms or not
```

A `CASE` assigns each row to the first arm that holds, so every row lands in exactly one class and
the classes always add up to the candidates. That is why the count cannot show two arms that overlap:
the overlap has to be probed on the predicates, counting the rows where two hold at once. The fit's
`clearance` and `interference` arms overlap at a point nameplate equal to a point demand, and the
arm order decides that row, which the entry `fit_criteria` proves.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Two overlapping predicates on the numbers 0 to 9, tested in order as a CASE would.
    let p1 = |x: i32| x >= 3;
    let p2 = |x: i32| x <= 6;
    let rows: Vec<i32> = (0..10).collect();
    let class = |x: i32| if p1(x) { 1 } else if p2(x) { 2 } else { 3 };
    let sizes: Vec<usize> = (1..=3).map(|c| rows.iter().filter(|&&x| class(x) == c).count()).collect();
    assert_eq!(sizes.iter().sum::<usize>(), rows.len());
    // The count cannot see the overlap; the predicates can.
    let both = rows.iter().filter(|&&x| p1(x) && p2(x)).count();
    assert_eq!(both, 4);
}
```

**Entry** `case_partition` · **Law** `algebra/arithmetic_class`

### A disjoint union adds

```text
|A ⊎ B| = |A| + |B|          |A ∪ B| = |A| + |B| - |A ∩ B|
```

A `UNION ALL` keeps every row of both sides, so its size is the sum of theirs; a `UNION` removes the
rows the two share, and its size falls by the intersection. A relation that means the first and
writes the second loses rows it cannot report.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    for a in 0..32_u32 {
        for b in 0..32_u32 {
            let disjoint_union = a.count_ones() + b.count_ones();
            let union = (a | b).count_ones();
            let intersection = (a & b).count_ones();
            assert_eq!(union, disjoint_union - intersection);
            assert_eq!(disjoint_union, union + intersection);
        }
    }
}
```

**Entry** `disjoint_union` · **Law** `algebra/searches`

## 10. The incidence matrix, its subspaces and its Laplacian

### The two rules are orthogonal complements

```text
B is m x n over a graph with c components: one row per edge, one column per node
  in the edge space, and complements there:  (n - c) + (m - n + c) = m
    cut space   = column space of B   = the gradients      dim  n - c
    cycle space = left nullspace of B = the circulations   dim  m - n + c
  in the node space, and complements there:  (n - c) + c = n
    row space of B                    = the potentials     dim  n - c
    nullspace of B                    = the constants      dim  c
```

⛔ **`B` is `m x n` here and everywhere in this repository**: one row per edge, one column per
node, `-1` at the tail and `+1` at the head. Every one of those four names depends on that choice
and nothing else does, so it is declared once, here, and the rest of the repository points at this
entry rather than restating it. Using both conventions is how *the row space plus the left
nullspace* gets written down, which decomposes nothing: under either orientation those two
summands sit in different spaces. This is Gilbert Strang's orientation, whose graph chapter every
header here cites, and it is the one under which `BᵀB` is the graph Laplacian.

This model has two graphs and two rules, and the rules are those two subspaces.

The **fusion rule** is a balance AT A NODE: what a composed layer files equals the sum over its
parts, each converted, less what was eliminated. A balance at a node is a cut-space condition, which
is Kirchhoff's current law, and the elimination is its source term.

The **conversion rule** is a sum ROUND A LOOP: the factors multiply to one, so `log phi` telescopes
to zero and a potential exists, an absolute log-size per unit whose differences are the filed
factors. A sum round a loop is a cycle-space condition, which is Kirchhoff's voltage law.

⭐⭐ They are orthogonal complements, so a filing can satisfy one and break the other, and the two
graphs need two rules rather than one. `checks/jagged_layer` accuses on the cut side and
`checks/conversion_cycle_does_not_close` on the cycle side.

⛔ **The dimensions are measured and are not written here.** `assets/sqlc/rank/cycle_space.sqlc`
prints them per graph; a count on this page would rot. What the block proves is the arithmetic those
numbers obey, and it needs no matrix: a spanning forest has exactly `n - c` edges, every edge it
rejects closes exactly one cycle, and the two counts fill `m`. Gilbert Strang's graph chapter is the
reference.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every graph on four labelled nodes: each of the six possible edges present or absent.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;
    let up = |root: &[usize; N], mut x: usize| {
        while root[x] != x {
            x = root[x];
        }
        x
    };

    for mask in 0..64u32 {
        let edges: Vec<(usize, usize)> =
            (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect();
        let m = edges.len();

        // A spanning forest, by union-find. What it accepts is the forest; what it rejects is a chord.
        let mut root = [0usize, 1, 2, 3];
        let (mut forest, mut chords) = (0usize, 0usize);
        for &(a, b) in &edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra == rb {
                chords += 1;
            } else {
                root[ra] = rb;
                forest += 1;
            }
        }
        let c = (0..N).filter(|&x| up(&root, x) == x).count();

        // A spanning forest has exactly n - c edges, which is the cut space's dimension.
        assert_eq!(forest, N - c);
        // Every edge it rejected closes one cycle, which is the cycle space's dimension.
        assert_eq!(chords, m + c - N);
        // And the two fill the edge space, so nothing lies outside them.
        assert_eq!(forest + chords, m);
    }

    // Orthogonality is the telescoping: a potential difference summed round a closed walk is zero,
    // so no gradient has a cycle component and no circulation is a potential difference.
    let potential = [7.0, 2.0, 5.0, 11.0];
    for walk in [
        vec![(0usize, 1usize), (1, 2), (2, 0)],
        vec![(0, 1), (1, 3), (3, 2), (2, 0)],
    ] {
        let round: f64 = walk.iter().map(|&(a, b)| potential[b] - potential[a]).sum();
        assert!(close(round, 0.0));
    }
}
```

**Entry** `incidence_subspaces` · **Law** `none`

### The Laplacian is a join with a group

```text
BtB = D - W           degree on the diagonal, negative adjacency off it
  entry (a, b)  =  sum over e of  B[e,a] * B[e,b]    a join on the EDGE index, a group per pair
  rows before the group  =  sum of k_e squared  =  4m
  trace                  =  sum of the degrees   =  2m
  every row sums to zero, so the constants are in the kernel
```

Nothing is transposed to get there, because there is nothing to form. A sparse matrix held
column-wise IS its coordinate form, which is a relation, so `B'` is two column names swapped and no
data moves. `examples/matrices/README.md` says the same of `D'`, where the transpose is the
relabelling and not an operation. What is left is a self-join on the edge index with a group by the
pair of nodes, which is entry `product_is_join` arriving at a second product.

⭐⭐ **The join's size is fixed before it runs.** Every edge has exactly two endpoints, so every
fibre of the edge index is two and the self-join returns `4m` rows, which is entry
`self_join_sizes`. A join returning anything else means the incidence is not an incidence, and that
is checkable before any dimension is computed.

⛔ **The group is a SUM and not a maximum, and that is what makes the off-diagonal a multiplicity.**
Two parallel edges between one pair contribute twice; an idempotent fold would report them once.
Entry `excess` is the rule that decides it, and `examples/columns` is where this product is formed
over the compose graph.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every graph on four labelled nodes, and then one multigraph the simple ones cannot reach.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;

    let mut cases: Vec<Vec<(usize, usize)>> = (0..64u32)
        .map(|mask| (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect())
        .collect();
    // Two parallel edges, so the off-diagonal has to count multiplicity rather than presence.
    cases.push(vec![(0, 1), (0, 1), (1, 2)]);

    for edges in cases {
        let m = edges.len();

        // B, m x n: one row per edge, -1 at the tail and +1 at the head.
        let mut b = vec![vec![0.0_f64; N]; m];
        for (e, &(tail, head)) in edges.iter().enumerate() {
            b[e][tail] -= 1.0;
            b[e][head] += 1.0;
        }

        // The product as written: one sum over the edges for each pair of nodes.
        let mut written = vec![vec![0.0_f64; N]; N];
        for a in 0..N {
            for d in 0..N {
                for e in 0..m {
                    written[a][d] += b[e][a] * b[e][d];
                }
            }
        }

        // The same thing as a join on the edge index and a group by the node pair. The join visits
        // only the non-zeros, which are the two endpoints of each edge.
        let mut triples: Vec<(usize, usize, f64)> = Vec::new();
        for (e, &(tail, head)) in edges.iter().enumerate() {
            triples.push((e, tail, -1.0));
            triples.push((e, head, 1.0));
        }
        let mut joined = 0usize;
        let mut grouped = vec![vec![0.0_f64; N]; N];
        for &(e, a, v) in &triples {
            for &(f, d, w) in &triples {
                if e == f {
                    grouped[a][d] += v * w;
                    joined += 1;
                }
            }
        }

        // Every fibre of the edge index is two, so the join is 4m rows before the group.
        assert_eq!(joined, 4 * m);
        for a in 0..N {
            for d in 0..N {
                assert!(close(grouped[a][d], written[a][d]));
            }
        }

        // Degree on the diagonal, negative adjacency off it, counting multiplicity.
        for a in 0..N {
            let degree = edges.iter().filter(|&&(x, y)| x == a || y == a).count();
            assert!(close(written[a][a], degree as f64));
            for d in 0..N {
                if d != a {
                    let parallel = edges
                        .iter()
                        .filter(|&&(x, y)| (x, y) == (a, d) || (x, y) == (d, a))
                        .count();
                    assert!(close(written[a][d], -(parallel as f64)));
                }
            }
        }

        // The handshake, and the constants in the kernel.
        let trace: f64 = (0..N).map(|a| written[a][a]).sum();
        assert!(close(trace, 2.0 * m as f64));
        for a in 0..N {
            assert!(close((0..N).map(|d| written[a][d]).sum::<f64>(), 0.0));
        }
    }
}
```

**Entry** `laplacian_is_a_join` · **Law** `none`

### The Laplacian composes, and so does its kernel

```text
L = sum over the edges of L_e        each term rank one, and the sum owes no correction
  x' L x   =  sum over e of (x_head - x_tail) squared   =  the energy, which is ||Bx|| squared
  ker L    =  ker B  =  the constants                   so rank L = rank B = n - c
  L(G - e) =  L(G) - L_e                                decomposition is subtraction
```

The Laplacian of a union of graphs is the sum of the Laplacians, one rank-one term per edge, and
the sum owes no correction. **That is the exact contrast with the layer graph.** There the fold is
additive over a conserved carrier, the excess over the image is entry `excess`'s `sum of (k - 1) w`,
and that excess IS the elimination. Here each edge contributes its own term whatever else is
present, so composing two graphs is adding and decomposing one is subtracting, with nothing to
correct.

⭐⭐ **And the kernel composes with it.** `x' L x` is the sum of the squared differences along the
edges, so it is `||Bx||` squared; a sum of squares is zero only when every term is, so `L x = 0`
says exactly `B x = 0`, which says `x` is constant along every edge. The kernel is therefore the
constants, one dimension per component, and adding an edge either closes a cycle and leaves the
kernel alone or joins two components and drops it by one.

⭐ **That is what licenses measuring the rank on the Laplacian at all.** `rank L = rank B = n - c`,
so a program may eliminate on the `n` by `n` Laplacian instead of the `m` by `n` incidence and get
the cut space's dimension. `examples/columns` does exactly that and holds the answer against a walk
that shares no code with it.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Every graph on four labelled nodes: each of the six possible edges present or absent.
    const E: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
    const N: usize = 4;

    // One edge's own Laplacian, the outer product of its row of B with itself.
    let term = |tail: usize, head: usize| {
        let mut l = vec![vec![0.0_f64; N]; N];
        for (a, sa) in [(tail, -1.0_f64), (head, 1.0_f64)] {
            for (d, sd) in [(tail, -1.0_f64), (head, 1.0_f64)] {
                l[a][d] += sa * sd;
            }
        }
        l
    };

    for mask in 0..64u32 {
        let edges: Vec<(usize, usize)> =
            (0..6).filter(|i| mask >> i & 1 == 1).map(|i| E[i]).collect();

        // The sum of the per-edge terms, against degree minus adjacency built directly.
        let mut summed = vec![vec![0.0_f64; N]; N];
        for &(tail, head) in &edges {
            let l = term(tail, head);
            for a in 0..N {
                for d in 0..N {
                    summed[a][d] += l[a][d];
                }
            }
        }
        let mut written = vec![vec![0.0_f64; N]; N];
        for &(tail, head) in &edges {
            written[tail][tail] += 1.0;
            written[head][head] += 1.0;
            written[tail][head] -= 1.0;
            written[head][tail] -= 1.0;
        }
        for a in 0..N {
            for d in 0..N {
                assert!(close(summed[a][d], written[a][d]));
            }
        }

        // Dropping an edge subtracts exactly that edge's term, so decomposition is subtraction.
        for &(tail, head) in &edges {
            let rest: Vec<(usize, usize)> = {
                let mut r = edges.clone();
                let at = r.iter().position(|&x| x == (tail, head)).unwrap();
                r.remove(at);
                r
            };
            let l = term(tail, head);
            for a in 0..N {
                for d in 0..N {
                    let without: f64 = rest
                        .iter()
                        .map(|&(t, h)| term(t, h)[a][d])
                        .sum();
                    assert!(close(summed[a][d] - l[a][d], without));
                }
            }
        }

        // The components, by union-find, so the kernel below has something to be constant on.
        let components = {
            let mut root = [0usize, 1, 2, 3];
            let up = |root: &[usize; N], mut x: usize| {
                while root[x] != x {
                    x = root[x];
                }
                x
            };
            for &(tail, head) in &edges {
                let (rt, rh) = (up(&root, tail), up(&root, head));
                if rt != rh {
                    root[rt] = rh;
                }
            }
            (0..N).map(|x| up(&root, x)).collect::<Vec<usize>>()
        };

        // The energy identity: x L x is the sum of the squared differences along the edges.
        for x in [
            vec![1.0, 2.0, 3.0, 4.0],
            vec![0.0, 0.0, 1.0, 1.0],
            vec![5.0, 5.0, 5.0, 5.0],
        ] {
            let quadratic: f64 = (0..N)
                .map(|a| (0..N).map(|d| x[a] * summed[a][d] * x[d]).sum::<f64>())
                .sum();
            let energy: f64 = edges
                .iter()
                .map(|&(tail, head)| (x[head] - x[tail]) * (x[head] - x[tail]))
                .sum();
            assert!(close(quadratic, energy));

            // A sum of squares is zero only when every term is, so a non-zero energy forbids L x = 0.
            // That is ker L = ker B, and the rank of the two follows.
            let l_x: Vec<f64> = (0..N)
                .map(|a| (0..N).map(|d| summed[a][d] * x[d]).sum())
                .collect();
            if energy > 0.0 {
                assert!(l_x.iter().any(|v| !close(*v, 0.0)));
            }
        }

        // A vector constant on each component has zero energy and is in the kernel. The indicators
        // have disjoint supports, so there are c of them and they are independent.
        for class in 0..N {
            let indicator: Vec<f64> = (0..N)
                .map(|a| if components[a] == class { 1.0 } else { 0.0 })
                .collect();
            if !indicator.iter().any(|v| *v > 0.0) {
                continue;
            }
            let energy: f64 = edges
                .iter()
                .map(|&(tail, head)| {
                    (indicator[head] - indicator[tail]) * (indicator[head] - indicator[tail])
                })
                .sum();
            assert!(close(energy, 0.0));
            for a in 0..N {
                assert!(close((0..N).map(|d| summed[a][d] * indicator[d]).sum::<f64>(), 0.0));
            }
        }
    }
}
```

**Entry** `laplacian_decomposes` · **Law** `none`

### A fusion adds no cycle, however many parts it has

```text
a fusion is one new node and one edge per part
  k parts from k distinct components   dn=+1  dm=+k  dc=-(k-1)   d(m-n+c) =  0
  two parts already in one component   dn=+1  dm=+2  dc= 0       d(m-n+c) = +1
```

A fusion adds the composed layer as a node and one edge per part, so **every part is a chord waiting
to happen**. Where the parts come from `k` distinct components the new node knits them into one, `c`
falls by `k - 1`, and the dimension does not move: the fusion adds no cycle at any arity. Where two
of its parts already sit in one component the second edge closes a loop and the dimension rises by
one.

⭐⭐ That loop is two paths arriving at one leaf under one fold, which is exactly what
`checks/jagged_layer` accuses, and it is why that rule is about a partition and not about a count:
*a fusion's parts partition what they compose*. So no legitimate filing can move this dimension, and
the measurement is a rule rather than a description. `algebra/cycle_space` is that rule read as a law:
it holds the layer graph's dimension against what `checks/jagged_layer` found, on zero versus nonzero,
and the two instruments share no code.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // m - n + c over an explicit edge list on `n` labelled nodes.
    let dim = |n: usize, edges: &[(usize, usize)]| -> i64 {
        let up = |root: &Vec<usize>, mut x: usize| {
            while root[x] != x {
                x = root[x];
            }
            x
        };
        let mut root: Vec<usize> = (0..n).collect();
        for &(a, b) in edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra != rb {
                root[ra] = rb;
            }
        }
        let c = (0..n).filter(|&x| up(&root, x) == x).count();
        edges.len() as i64 - n as i64 + c as i64
    };

    // k parts, each its own component. Fusing them adds the composed node and one edge per part.
    for k in 1..=5usize {
        assert_eq!(dim(k, &[]), 0);
        let fused: Vec<(usize, usize)> = (0..k).map(|p| (k, p)).collect();
        assert_eq!(dim(k + 1, &fused), 0);
    }

    // Two parts that already share a component: node 0 composes node 1 one level down.
    assert_eq!(dim(2, &[(0, 1)]), 0);
    // Fuse both of them into a new node 2. The second edge closes a loop and the dimension rises.
    assert_eq!(dim(3, &[(0, 1), (2, 0), (2, 1)]), 1);
}
```

**Entry** `fusion_adds_no_cycle` · **Law** `algebra/cycle_space`

### The composition map's kernel is what a fusion declared immaterial

```text
F the part incidence, Phi the factors, every part in exactly one fusion
  dim ker(F Phi) = m - |fusions|
  where the cycle space is zero, m = n - c, so it is also |leaves| - c
```

A part is a column of `F` and an edge of the layer graph at once, and it belongs to one fusion, so
folding the parts onto their fusions gives fibres whose sum is the edge count and whose box count
is the rank. The null space is what is left over. Where the cycle space is zero the internal nodes
are exactly the fusions, and the dimension is the leaf count less the number of components.

⭐⭐ A generator of it moves one unit of composed supply out of one part of a fusion and into
another, and the composed figure does not move. That invisibility is not a by-product of the
arithmetic: it is the claim the fusion makes. `pm:Layer` defines a layer as a place whose remainder
is held independently of every other layer's, and `asrt:Fusion` turns that into **fuse only what is
fungible**. Fusing is quotienting, and this dimension is how much was quotiented away.

⛔ The sibling pairs are not the generators. A fusion of `k` parts has `k` choose two sibling pairs
and `k - 1` independent moves, and those agree only while no fusion holds three parts, where the
third pair is the sum of the other two. Counting pairs and reporting the total as a dimension is
right on a corpus of binary fusions and wrong at the first fusion with three.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A forest of fusions: `sizes[i]` parts hang under fusion `i`, each part a fresh leaf.
    // Every fusion is its own component, so `c` is the number of fusions.
    let measure = |sizes: &[usize]| -> (i64, i64, i64, i64) {
        assert!(sizes.iter().all(|&k| k >= 1));
        let fusions = sizes.len() as i64;
        let parts: i64 = sizes.iter().map(|&k| k as i64).sum();
        let (n, m, c, leaves) = (fusions + parts, parts, fusions, parts);
        let kernel: i64 = sizes.iter().map(|&k| k as i64 - 1).sum();
        (kernel, m - fusions, leaves - c, n - c - fusions)
    };

    // The dimension, the edge count less the fusions, the leaf count less the components, and
    // the rank read off the graph: four routes, one number.
    for a in 1..=4usize {
        for b in 1..=4usize {
            for d in 1..=4usize {
                let (kernel, by_edges, by_leaves, by_rank) = measure(&[a, b, d]);
                assert_eq!(kernel, by_edges);
                assert_eq!(kernel, by_leaves);
                assert_eq!(kernel, by_rank);
            }
        }
    }

    // The sibling pairs are not the generators. They agree while no fusion holds three parts.
    let pairs = |k: i64| k * (k - 1) / 2;
    let generators = |k: i64| k - 1;
    for k in 1..=2i64 {
        assert_eq!(pairs(k), generators(k));
    }
    for k in 3..=6i64 {
        assert!(pairs(k) > generators(k));
    }
}
```

**Entry** `composition_kernel` · **Law** `algebra/composition_kernel`

### The fold has four subspaces and only one of them is ever a claim

```text
F Phi : R^P -> R^X, every part in exactly one fusion, every factor strictly positive
  dim ker(F Phi)      =  |P| - |X|      the offsets a fusion declared immaterial
  dim row(F Phi)      =  |X|            one positive functional per fusion
  dim col(F Phi)      =  |X|            the whole fusion space
  dim ker((F Phi)^T)  =  0
  row(F Phi) + ker(F Phi) = R^P, block by block over the same fibres
  v in ker(F Phi) and v >= 0  =>  v = 0
```

A part belongs to one fusion, so the row for a fusion is `Phi` on that fusion's own parts and zero
everywhere else and the rows have pairwise disjoint supports. Vectors with disjoint supports and
none of them zero are independent, because the coefficient of one is read off any coordinate the
others do not touch. So the rank is simply the number of rows, and that settles both subspaces on
the fusion side at once: nothing is left over, so the left null space is empty and the column space
is everything.

⭐⭐ Which is why a declared fungibility has exactly one side of this map to live on. A null space
on the part side is the claim a fusion makes, that supply moved between its parts leaves the
composed figure where it was. A null space on the fusion side would be the opposite kind of fact, a
combination of composed figures that no assignment to the parts can reach, and there is none. One
map, two null spaces, and only one of them is ever something a document asserts.

⭐⭐ And supply cannot hide in the one that exists. A fusion's row space block is spanned by `Phi`
restricted to its parts, every entry strictly positive, so the row space meets the non-negative
orthant. The null space does not: `Phi . v = 0` with `Phi` positive forces any non-zero `v` to
carry a plus and a minus. An offset takes from one part exactly what it gives another, which is the
conserved carrier written as a subspace rather than as a rule.

⛔ The dimensions do not depend on the factors and the directions do. Scaling a column by a
positive number cannot change which columns are independent, so every dimension above survives any
conversion factor whatever. A generator does not: a part whose factor is a typed absence leaves its
block pointing somewhere nobody has stated, with the dimension still exact.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // Rank by elimination with partial pivoting. Nothing below may read a magnitude, so the
    // factors are deliberately unequal and every assertion has to survive that.
    let rank = |mut a: Vec<Vec<f64>>| -> usize {
        let (rows, cols) = (a.len(), a.first().map_or(0, Vec::len));
        let mut r = 0;
        for c in 0..cols {
            let pivot = (r..rows)
                .max_by(|&i, &j| a[i][c].abs().total_cmp(&a[j][c].abs()))
                .filter(|&i| a[i][c].abs() > 1e-9);
            if let Some(p) = pivot {
                a.swap(r, p);
                for i in (r + 1)..rows {
                    let f = a[i][c] / a[r][c];
                    for j in c..cols {
                        a[i][j] -= f * a[r][j];
                    }
                }
                r += 1;
            }
        }
        r
    };
    let transpose = |a: &[Vec<f64>]| -> Vec<Vec<f64>> {
        (0..a[0].len()).map(|j| a.iter().map(|row| row[j]).collect()).collect()
    };

    // `F Phi` for a fibre profile: one row per fusion, one column per part, the factors strictly
    // positive and no two alike.
    let fold = |sizes: &[usize]| -> Vec<Vec<f64>> {
        let mut m = vec![vec![0.0; sizes.iter().sum()]; sizes.len()];
        let mut col = 0;
        for (row, &k) in sizes.iter().enumerate() {
            for t in 0..k {
                m[row][col] = 0.25 * (col + 1) as f64 * (t + 2) as f64;
                col += 1;
            }
        }
        m
    };

    for a in 1..=4usize {
        for b in 1..=4usize {
            for d in 1..=4usize {
                let sizes = [a, b, d];
                let m = fold(&sizes);
                let (rows, cols) = (m.len(), m[0].len());
                let r = rank(m.clone());

                // Full row rank, so the left null space is empty and the column space is whole.
                assert_eq!(r, rows);
                assert_eq!(rows - r, 0);
                // Row rank is column rank, which is the row space on the part side.
                assert_eq!(r, rank(transpose(&m)));
                // And the null space is the rest of the part space.
                assert_eq!(cols - r, sizes.iter().map(|&k| k - 1).sum::<usize>());

                // Block by block, over the same fibres: one direction the figure reads,
                // `k - 1` it does not, and nothing of the row outside its own fusion's columns.
                let mut col = 0;
                for (row, &k) in sizes.iter().enumerate() {
                    let block: Vec<Vec<f64>> = vec![m[row][col..col + k].to_vec()];
                    assert_eq!(rank(block.clone()), 1);
                    assert_eq!(k - rank(block), k - 1);
                    assert!(m[row]
                        .iter()
                        .enumerate()
                        .all(|(j, &x)| (col..col + k).contains(&j) || x == 0.0));
                    col += k;
                }
            }
        }
    }

    // A positive generator, and a null space that misses the non-negative orthant: every
    // non-negative offset a fusion cannot see is zero.
    let phi = [0.25, 2.0, 40.0];
    assert!(phi.iter().all(|&x| x > 0.0));
    for i in 0..4 {
        for j in 0..4 {
            for k in 0..4 {
                let v = [f64::from(i), f64::from(j), f64::from(k)];
                let dot: f64 = phi.iter().zip(v).map(|(a, b)| a * b).sum();
                assert_eq!(dot == 0.0, v.iter().all(|&x| x == 0.0));
            }
        }
    }
    // And a generator of the null space carries both signs, which is what an offset is.
    let g = [phi[1], -phi[0], 0.0];
    let dot: f64 = phi.iter().zip(g).map(|(a, b)| a * b).sum();
    assert_eq!(dot, 0.0);
    assert!(g.iter().any(|&x| x > 0.0) && g.iter().any(|&x| x < 0.0));
}
```

**Entry** `fold_subspaces` · **Law** `algebra/composition_row_space`, `algebra/composition_image`

### The null space of a descent is the sum of the null spaces in it

```text
Psi = A_1 ... A_d, each A_i onto
  dim ker(Psi) = Σ dim ker(A_i)
under one root whose descent is a tree, with L leaves and F fusions in it
  parts = L + F - 1     so    Σ (parts_x - 1) = parts - F = L - 1 = dim ker(Psi)
a second path to a leaf adds a part and no leaf, so the sum rises and L - 1 does not
```

Every level of the fold is onto, so the composite from the leaf layers under a root to that root's
single figure is onto as well, and its null space is everything but one dimension. Counting the
other way, each fusion in the closure contributes its own block once. On a tree the two agree by
edge counting, and the identity is what makes a composed figure's null space computable level by
level instead of only as a whole.

⭐⭐ So the content of the identity is not the arithmetic, it is that the descent IS a tree. A leaf
reached through two paths adds a part to the closure and no leaf to it, so the blocks sum higher
while the composite's own dimension stays where it was. A cycle takes leaves away without taking
blocks. Both land on the same comparison, from opposite sides.

⛔ And it is the fold's kernel that closes this way, never the row space. The row spaces run the
other direction: each level composed on top can only narrow what survives to the top, so the chain
descends while the kernels ascend. Reading one chain's direction off the other is how a closure
gets built that grows where it should shrink.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A descent as a parent per layer: layer 0 is the root and layer `i` hangs under a lower
    // index, which is every rooted tree on `n` labelled layers and nothing that is not one.
    let measure = |parent: &[usize], n: usize| -> (usize, usize, usize) {
        let mut children = vec![0usize; n];
        for &p in parent {
            children[p] += 1;
        }
        let fusions = children.iter().filter(|&&c| c > 0).count();
        let blocks: usize = children.iter().filter(|&&c| c > 0).map(|&c| c - 1).sum();
        (blocks, n - fusions, fusions)
    };

    let mut trees = 0;
    for n in 2..=6usize {
        let total: usize = (1..n).product();
        for code in 0..total {
            let mut c = code;
            let mut parent = vec![0usize; n - 1];
            for (j, slot) in parent.iter_mut().enumerate() {
                *slot = c % (j + 1);
                c /= j + 1;
            }
            let (blocks, leaves, fusions) = measure(&parent, n);
            // The composite is onto one figure, so its null space is the leaves less one, and
            // the blocks below the root sum to the same number.
            assert_eq!(blocks, leaves - 1);
            // The edge count is what forces it: on a tree every layer but the root is one part.
            assert_eq!(parent.len(), leaves + fusions - 1);
            trees += 1;
        }
    }
    assert!(trees > 0);

    // A second path is what parts the two routes. A root over two fusions, and one leaf reached
    // through both: four layers, four parts, and no tree.
    let edges = [(1usize, 0usize), (2, 0), (3, 1), (3, 2)];
    let mut children = vec![0usize; 4];
    for &(_, p) in &edges {
        children[p] += 1;
    }
    let fusions = children.iter().filter(|&&c| c > 0).count();
    let blocks: usize = children.iter().filter(|&&c| c > 0).map(|&c| c - 1).sum();
    let leaves = 4 - fusions;
    assert_eq!(edges.len(), leaves + fusions);
    assert!(blocks > leaves - 1);
}
```

**Entry** `kernel_closes` · **Law** `algebra/composition_closure`

### An elimination is a removal, and no flow can produce one

```text
B the incidence, y any edge vector, 1 the all-ones node vector
  1' B' y = (B 1)' y = 0        so a divergence sums to zero on every component
  e >= 0 and somewhere positive  =>  e is not a divergence
```

Every row of `B` holds one `-1` and one `+1`, so `B` sends the all-ones vector to zero and the
divergence of any flow sums to zero on each component. The node space splits into the row space,
which is every divergence a flow can produce, and the constants, one per component. An elimination
is non-negative and not everywhere zero, so its constants component does not vanish and no
redistribution of supply along the parts can account for it.

⭐ That is the difference between a removal and a rearrangement, written as a subspace. A
correction sitting in the row space would move supply between layers and leave every component's
total where it was. `e` does not, which is why it is subtracted rather than carried, and why
`asrt:Elimination` asks what it was removed `against`.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // B is m x n, one row per edge, -1 at the tail and +1 at the head. Two components.
    let edges: &[(usize, usize)] = &[(0, 1), (1, 2), (3, 4)];
    let component: &[usize] = &[0, 0, 0, 1, 1];
    let sizes = [3.0, 2.0];
    let n = component.len();

    let divergence = |y: &[f64]| -> Vec<f64> {
        let mut d = vec![0.0; n];
        for (e, &(tail, head)) in edges.iter().enumerate() {
            d[tail] -= y[e];
            d[head] += y[e];
        }
        d
    };
    let per_component = |v: &[f64]| -> Vec<f64> {
        let mut t = vec![0.0; sizes.len()];
        for (i, &x) in v.iter().enumerate() {
            t[component[i]] += x;
        }
        t
    };

    // Any flow at all: B times the all-ones vector is zero, so its divergence sums to zero.
    for y in [[1.0, 2.0, 3.0], [-4.0, 0.5, 7.25], [0.0, 0.0, 0.0]] {
        for total in per_component(&divergence(&y)) {
            assert!(close(total, 0.0));
        }
    }

    // An elimination is non-negative and somewhere positive, so it is no flow's divergence.
    let e = [0.0, 1.5, 0.0, 2.0, 0.0];
    assert!(e.iter().all(|&x| x >= 0.0));
    let totals = per_component(&e);
    assert!(close(totals[0], 1.5) && close(totals[1], 2.0));
    assert!(totals.iter().all(|&t| t > 0.0));

    // Split it: the constants carry each component's total, and what is left IS a divergence.
    let constants: Vec<f64> = (0..n).map(|i| totals[component[i]] / sizes[component[i]]).collect();
    let row_part: Vec<f64> = (0..n).map(|i| e[i] - constants[i]).collect();
    for total in per_component(&row_part) {
        assert!(close(total, 0.0));
    }
    assert!(constants.iter().any(|&x| x > 0.0));
}
```

**Entry** `elimination_leaves` · **Law** `none`

### A path product needs there to be one path

```text
one path to a node   ->  Phi along it is the product of the factors, and it is the only one
two paths to a node  ->  two products, and the arithmetic chooses neither
```

Entry `conversion_collapses` shows that a path of conversions is one conversion, the product of its
factors. That result is about A path. It is usable only where there is THE path, and that condition
is exactly that the cycle space is zero: in a forest each node is reached one way, so the product
above it is a single number.

⛔ Where two paths arrive, the flattening has two answers and the arithmetic has none. A diamond does
it with the smallest factors there are.

⭐ So the flattening in `composition/derived_quantities.sqlc` and `composition/settled_remainders.sqlc`
rests on a graph measurement and not on a property of multiplication.
`assets/sqlc/rank/cycle_space.sqlc` is where that measurement lives.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // m - n + c over an explicit edge list on `n` labelled nodes.
    let dim = |n: usize, edges: &[(usize, usize)]| -> i64 {
        let up = |root: &Vec<usize>, mut x: usize| {
            while root[x] != x {
                x = root[x];
            }
            x
        };
        let mut root: Vec<usize> = (0..n).collect();
        for &(a, b) in edges {
            let (ra, rb) = (up(&root, a), up(&root, b));
            if ra != rb {
                root[ra] = rb;
            }
        }
        let c = (0..n).filter(|&x| up(&root, x) == x).count();
        edges.len() as i64 - n as i64 + c as i64
    };

    // A diamond: the leaf is reached from the root two ways, and the two ways scale differently.
    let diamond = [(0usize, 1usize), (0, 2), (1, 3), (2, 3)];
    assert_eq!(dim(4, &diamond), 1);

    // The factor product down each arm, which is what `conversion_collapses` collapses a path to.
    let product = |path: &[f64]| path.iter().product::<f64>();
    assert!(close(product(&[2.0, 1.0]), 2.0));
    assert!(close(product(&[1.0, 3.0]), 3.0));
    // Two answers, and nothing in the arithmetic chooses between them.
    assert!(!close(product(&[2.0, 1.0]), product(&[1.0, 3.0])));

    // Drop either arm and the cycle space is zero again, and the product is the only one there is.
    assert_eq!(dim(4, &[(0, 1), (1, 3)]), 0);
    assert!(close(product(&[2.0, 1.0]), 2.0));
}
```

**Entry** `path_product_needs_one_path` · **Law** `none`

### A unit conversion scales the rows, and only the column space notices

```text
D a positive diagonal, A -> DA        each row scaled by its own factor
  rank(DA)      = rank(A)
  null(DA)      = null(A)
  rowspace(DA)  = rowspace(A)
  colspace(DA)  = D . colspace(A)     the dimension survives, the subspace MOVES
  (DA)'(DA)     = A' D-squared A      quadratic in the factor, so the Gram moves too
  and a D exists on a graph of factors exactly when they multiply to one round every loop
```

Converting a filing into a common unit multiplies each row by its own positive factor, which is a
positive diagonal `D`. **Three of the four subspaces do not notice.** Scaling a row does not move
the span of the rows and does not change which vectors the rows annihilate, so the row space and
the null space are fixed, and the rank with them. The column space is not fixed: it moves to `D`
times itself. The Gram matrix moves too, and quadratically.

⛔ So a Gram matrix over filed quantities is a statement about the units they were filed in, and
asking a matrix of magnitudes for its column space is asking for a `D` first.

⭐⭐⭐ **That is not the same as having no column space.** A `D` is a potential, an absolute
log-size per unit, and a potential exists exactly when the factors carry nothing round a loop,
which is entry `cycle_closes` and the rule that asks it of every loaded document.

⛔ **Two spaces meet here and they are easy to run together.** The checkable condition is about
`log phi`, an EDGE vector, and it is that `log phi` lies in the unit graph's COLUMN space. The `D`
is the potential that condition buys, a NODE vector in that graph's ROW space, fixed up to one
constant per component. So the geometry is real, it belongs to a graph the matrix does not
contain, and it is known up to the width each filed factor leaves. The graph of compositions asks nothing of that rule, because its
edges carry counts and a count is dimensionless, which is why `examples/columns` puts the question
to that graph first.

```rust
include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));

fn main() {
    // A, three rows by two columns, and a positive factor per row.
    let a = [[1.0_f64, 2.0], [3.0, 6.0], [2.0, 4.0]];
    let d = [2.0_f64, 1.0, 5.0];
    let da: Vec<Vec<f64>> = (0..3).map(|i| (0..2).map(|j| d[i] * a[i][j]).collect()).collect();

    // Rank, by the two-by-two minors. Stacking A on DA keeps them all zero, so one row space.
    let minors = |rows: &[Vec<f64>]| -> Vec<f64> {
        let mut out = Vec::new();
        for i in 0..rows.len() {
            for k in (i + 1)..rows.len() {
                out.push(rows[i][0] * rows[k][1] - rows[i][1] * rows[k][0]);
            }
        }
        out
    };
    let rows_a: Vec<Vec<f64>> = a.iter().map(|r| r.to_vec()).collect();
    let mut stacked = rows_a.clone();
    stacked.extend(da.clone());
    for m in minors(&rows_a).iter().chain(&minors(&da)).chain(&minors(&stacked)) {
        assert!(close(*m, 0.0));
    }

    // The null space does not move: the same vector is annihilated, and one outside stays outside.
    let apply = |rows: &[Vec<f64>], x: [f64; 2]| -> Vec<f64> {
        rows.iter().map(|r| r[0] * x[0] + r[1] * x[1]).collect()
    };
    for v in apply(&rows_a, [2.0, -1.0]).iter().chain(&apply(&da, [2.0, -1.0])) {
        assert!(close(*v, 0.0));
    }
    for v in [apply(&rows_a, [1.0, 0.0]), apply(&da, [1.0, 0.0])] {
        assert!(v.iter().any(|x| !close(*x, 0.0)));
    }

    // The column space DOES move: the first column of DA is no multiple of the first column of A.
    let column = |rows: &[Vec<f64>], j: usize| -> Vec<f64> { rows.iter().map(|r| r[j]).collect() };
    let (u, v) = (column(&rows_a, 0), column(&da, 0));
    let ratio = v[0] / u[0];
    assert!(v.iter().zip(&u).any(|(y, x)| !close(*y, ratio * x)));

    // The Gram is quadratic in the factor, and it is not the Gram of A.
    let gram = |rows: &[Vec<f64>]| -> [[f64; 2]; 2] {
        let mut g = [[0.0_f64; 2]; 2];
        for j in 0..2 {
            for k in 0..2 {
                g[j][k] = rows.iter().map(|r| r[j] * r[k]).sum();
            }
        }
        g
    };
    let scaled = gram(&da);
    let squared = {
        let mut g = [[0.0_f64; 2]; 2];
        for j in 0..2 {
            for k in 0..2 {
                g[j][k] = (0..3).map(|i| a[i][j] * d[i] * d[i] * a[i][k]).sum();
            }
        }
        g
    };
    let plain = gram(&rows_a);
    for j in 0..2 {
        for k in 0..2 {
            assert!(close(scaled[j][k], squared[j][k]));
        }
    }
    assert!(!close(scaled[0][0], plain[0][0]));

    // Where D comes from: a potential on a graph of factors, whose differences are those factors.
    // It exists when the factors multiply to one round the loop.
    let factors = [((0usize, 1usize), 2.0_f64), ((1, 2), 3.0), ((0, 2), 6.0)];
    let potential = [0.0_f64, 2.0_f64.ln(), 6.0_f64.ln()];
    for ((tail, head), phi) in factors {
        assert!(close((potential[head] - potential[tail]).exp(), phi));
    }
    let loop_product = 2.0 * 3.0 / 6.0;
    assert!(close(loop_product, 1.0));

    // Change one factor and the loop no longer closes. The tree already fixed the potential, so
    // the chord has no freedom left and no D reproduces all three.
    let open = 2.0 * 3.0 / 5.0;
    assert!(!close(open, 1.0));
    assert!(!close((potential[2] - potential[0]).exp(), 5.0));
}
```

**Entry** `units_scale_rows` · **Rule** `checks/conversion_cycle_does_not_close`
