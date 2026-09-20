What does the model have to be bent to say?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

Every other example asks whether the machinery is right. This one assumes it is and goes
looking for the places it cannot reach: ordinary situations, from ordinary businesses, that the
schema has no honest way to express. A field that has to be bent to take a fact is a finding
about the field, and it is worth more than another document that fits.

⭐⭐⭐ THE METHOD IS TO GENERALISE ONE ASSUMPTION AT A TIME AND SEE WHAT SURVIVES. Each probe
below changes exactly one thing the model takes for granted, keeps everything else, and reports
what the filing then has to claim. Two of the three assumptions turn out to be load-bearing in
ways the annotations do not say.

⛔ NOTHING HERE ACCUSES A FILING. These are questions about the SCHEMA, so they run without a
database and print rather than assert, except where an arithmetic claim can be checked against
a sieve.

# Three grains, of which the model files two

⚠️ The part most likely to be worth a reviewer's time, because it is a question about what the
intervals MEAN rather than about what is done to them.

Three timescales bear on any quantity here. The **transaction grain** is the quantum `q`, the
indivisible unit supply arrives in, filed with an origin saying who sets it. The **reporting
grain** is the denominator of the unit: `per quarter`, `per week`. The **variation grain**,
the timescale on which the quantity actually moves, is filed nowhere.

The first is the model's own subject: `r = mq − (d mod q)`, which §6 of `examples/matrices/main.rs`
evaluates. The third matters because two operations quietly depend on it.

**A duty cycle folds into a rate and vanishes.** A line running 02:00–05:00 at one unit per
five seconds has a nameplate of 2160/day; against 2000/day of demand the clearance is 160/day
whatever the schedule. But the *duration* that clearance corresponds to does not survive: the
naive `q / clearance` gives 9 minutes, while the real wait is 68 seconds inside the window or
21 hours outside it. Nine minutes occurs nowhere. So a slack is filed as a quantity in the
layer's unit, never as the duration it was observed as, and the filer owes the conversion.
Probe 3 and probe 4 are that assumption generalised.

⛔ **A second consequence looks to follow here and does not, and why it fails is worth more
than the claim would have been.** It runs: a queue absorbs a transient and never a standing
excess, so at `ρ > 1` the backlog grows without bound, so `shift-line`'s demand of
`[11.0, 12.7, 14.4]` against a 10-shift line needs the variation reading to be coherent.
**`ρ > 1` gives an unbounded backlog only with infinite patience**, and `timeSlack` IS a
patience — *"before the caller goes elsewhere"*, filed `contractual`. A reneging queue is
stable at any `ρ`: the backlog grows until the wait reaches the patience, then demand departs
at the rate the excess arrives. Nothing here needs the variation reading.

⭐ And the arithmetic is exact, which is the part to check: patience `2.5 shifts = 0.25 week`
at `μ = 10/week` puts the equilibrium depth at `μW = 2.5` items — the wait sits AT the
patience — while the departure rate is `λ − μ = 2.7/week` and the filed holders are
`customer 1.7 + unrealised 1.0 = 2.7`. The sum rule and the queueing equilibrium agree.

⛔⛔ THAT LAST PARAGRAPH IS THE ONE CLAIM IN THIS FILE NOTHING EVALUATES. Its four figures are
all in `assets/corpus/merge-holding-composition.xml`; `entries/borne.sqlc` carries the
`1.7 + 1.0` half as a comment and no relation computes `μW` against `λ − μ`. It is exactly the
shape this repository refuses elsewhere: an identity a reader reconstructs the model from,
standing on somebody's arithmetic rather than on a run.

⭐ `Claim` still reads as epistemic throughout — "most likely", "the value an estimator can
honestly state", and `narrowsWhen`, which means *this range is what nobody knows*. Genuine
variation does not narrow when you measure harder, and the two readings are not distinguished.
That ambiguity is real; what it is NOT is the thing that makes a time buffer work.

⭐⭐ **The duty cycle half of this is a second axis and not a third value.** `Divisibility`'s
choice is `lumpy | continuous`, and read as functions of the amount asked for, `continuous` is
a line and `lumpy` is a staircase `q·floor(x/q)`. A duty cycle is the same staircase on the
*time* axis, a square wave. It is not a third member of the choice, because eight-GPU nodes
available only 02:00–05:00 are lumpy in amount **and** intermittent in time, so the type is a
sequence: the choice, then an optional `window`. Its size is a `LumpyQuantum`, and the
*period* comes free from the denominator rule above.

`window` obeys one rule nothing else here obeys: **it is carried through a fusion and never
summed.** Two members naming one machine file one calendar between them; `F Φ` would give ten
days a week. It is a property rather than a quantity, which is also why the elimination vector
`e_x` ranges over demand, nameplate and draw and has no fourth component. `checks/window_lost_or_summed`
is the rule; probe 3 is the reason it exists.

⛔ **The variation grain itself still has no element, and this is the open question.** A
`period` on `Claim` touches every site that reads a claim's width; an `ignorance | variation`
flag is a false
choice, since the honest answer is usually both; and either is a time axis entering a model
that deliberately carries none. **If you see a fourth option, that is the most useful thing
you could send back.**
