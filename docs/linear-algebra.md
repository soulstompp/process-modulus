# Note for the linear algebra reviewers — English

**Current as of the 2026-09-01 grain pass**, which added the composition document type, the
three buffer slacks, ISO 286's third fit class and the sign-blindness note that comes with it,
one correction to the decomposition below that a reader of this note would very likely have
caught first, and the grain section before the composition part — which is the open question,
not a settled piece.

Purpose: give someone strong in linear algebra the minimum needed to reconstruct the
model themselves, without reading the README. Ends where the flow network becomes
obvious, on purpose.

---

A document declares a set of **layers**. Each layer ℓ carries three quantities in its own
unit: a demand `d`, a committed supply `n` (the nameplate), and a quantum `q`, the
indivisible unit supply arrives in. Supply comes in whole units, so `n = kq` for integer
`k`; demand does not. The **remainder** is `r = n − d`. Every quantity is a three-point
interval, so this is interval arithmetic throughout, and both the remainder's magnitude and
its **sign** are evaluated across the demand range. ⭐ That uniformity is one pass old. The sign
used to be read at the mode alone, because `Fit` was a two-member enumeration — `clearance |
interference` — and a type taking one value has to be read at one point. ISO 286, which the
vocabulary is borrowed from, defines **three** classes, and the missing one is exactly the
overlap case:

```
clearance     n_low  ≥ d_high     the whole range clears
transition    the ranges overlap  partly each way
interference  n_high ≤ d_low      the whole range interferes
```

Where `n − d` crosses zero the magnitude's low bound is legitimately 0, and the sign now says so
rather than leaving a reader to infer it.

⛔ **One consequence is worth your attention, because it is an interval-arithmetic trap rather
than a modelling choice.** Under a transition fit `|n − d|` is **sign-blind**, so it keeps only
the LARGER of the two sides and the smaller is invisible inside it. `d = [11.0, 13.2, 16.4]`
against `n = 16` gives `[0.0, 2.8, 5.0]` — the clearance side — and the 0.4 of interference lies
inside that interval, indistinguishable from 0.4 of clearance. So the interference exposure is
derived from the inputs and never from the filed magnitude: `max(0, d_high − n_low)`.

⭐ And the two sides must **never be added**. Clearance falls as `d` rises while interference
rises, so a component-wise sum pairs the slack week's spare with the busy week's unserved demand and
reports a state that occurs in no week — the same correlation error as the `Φ` case below, except
the shared driver is `d` itself and the pairing is exactly backwards. The cure is to evaluate at
one corner, where there is one value of each. That is why `quantity` stayed a single Claim.

**The remainder is diagonal.** Nothing about layer *a* enters layer *b*'s remainder. Worth
stating outright, because the rest of the model is matrices and the natural assumption is
that they do the work here. They don't.

## The decomposition, and the correction

With `m = k − ⌊d/q⌋`:

```
r = mq − (d mod q)
```

`mq` is whole quanta and a procurement decision — hold one more unit and it moves.
`(d mod q)` is a residue and no choice of `k` removes it; the closest any decision reaches is
`min(d mod q, q − d mod q)`. Since `n` is a multiple of `q`, `r ≡ −d (mod q)` always:
rounding up leaves `(−d) mod q ∈ [0,q)`, rounding down leaves `−(d mod q) ∈ (−q,0]`,
additive inverses in ℝ/qℝ summing to `q`. Clearance and interference are one division read
from opposite sides. The model's claim is that the residue is conserved and the integer part
is chosen, so the document records who may change each: the quantum's origin (who sets unit
size) and the amount's origin (who sets how many), each one of
`intrinsic`/`contractual`/`policy`.

⛔ **Two things about that identity that a findings pass got wrong and you would not have.**
First, substituting `k = n/q` collapses it: `r = (n/q − ⌊d/q⌋)q − (d − ⌊d/q⌋q) = n − d`. The
floors appear twice with opposite signs and cancel, so `r` is exact for **any** `d` and **any**
`n`, interval or not — a finding claiming the decomposition "assumes point values" was wrong
about the total.

Second, and worse: `d mod q` is a **sawtooth**, so evaluated at an interval's three points it
need not be ordered. `d = (4.5, 5.2, 6.7)` at `q = 1` gives residues `(0.5, 0.2, 0.7)`, which
is not a valid three-point interval at all, while `d` is perfectly well formed. **Ten of the
twenty lumpy layers in `assets/corpus/` are in that state.** The total is an identity; the split is
not representable as two intervals in general. The schema happens to carry only the total, so
nothing is broken — but read the decomposition as a derivation of `r`, never as a filing
instruction for its two halves.

## Operations, and why `DᵀN` is not what it looks like

A document also declares **operations**. Each draws on a layer, or induces a commitment on
another, giving two P×L matrices over operations × layers: `D` for draws, `N` for inductions.
They are deliberately different types — a draw is consumption that happened, an induction is
a commitment that creates a future draw on a *different* supply.

So there is genuine cross-layer structure, and `DᵀN` is the obvious way to collect it. Two
things stop it being what it looks like. The units: each layer carries its own — people, GPU,
launches per quarter — so entries come out in people·launches rather than launches per
person. The incidence *patterns* compose and give you reachability; the quantities do not.
And there is no firing count per operation, deliberately, because sequence and timing are
BPMN's job — so what you have is a rate structure, not a flow.

That matters because of what it is not. `DᵀN`'s off-diagonal says *work drawn here commits
work there*. **Coupling** is a different object: `C`, L×L, says *relieving this layer's
constraint measurably moves that layer's remainder*. The model assumes `C = 0` — that's what
makes the layers separable in the first place — and requires any nonzero entry to carry a
prose observation of how it was seen. The two cannot be connected without exactly the firing
counts that aren't there, so `C` is observed and never derived. **Zero couplings is the
assumption, not a result**; a document with none is one where nobody looked. This is also
where the basis question lands: a direct-sum decomposition isn't unique, and what pins this
one is the units, not an inner product — there is no norm, spectrum or eigenvalue here until
someone chooses a scaling per layer, which is a modelling act rather than a mathematical one.

## Holders, and the three slacks that bound them

Each remainder is borne by one or more of exactly five **holders** — `booked`,
`counterparty`, `customer`, `people`, `unrealised` — each with a share in the layer's unit,
shares summing to `|r|`. That is `H`, L×5, a distribution rather than a selection. Four of
the five have no transaction behind them; the substantive claim concerns `people`, where
absorbed work creates no instrument and so no accounting system can see it.

Each layer also carries three **slacks**, one per buffer, in the layer's unit: `capacitySlack`
(how far supply runs above its rating), `inventorySlack` (how much output is held ahead) and
`timeSlack` (how much demand survives being held). Call that `S`, L×3. Each remainder names
one buffer as its `absorber`, so there is a selection `A: L → {1,2,3}`, and the rule is

```
Σ_{j ≠ unrealised} H[ℓ,j]  ≤  S[ℓ, A(ℓ)]        wherever r[ℓ] < 0 and S[ℓ,A(ℓ)] is stated
```

⭐ Three things are worth flagging to a reader who will look for structure here. **These were
booleans until this pass**, which made the inequality unstatable — a bit says a buffer exists,
not how much it holds, so any share fitted. **`unrealised` is exempt because it is the
overflow**: demand that no buffer took. And the constraint is one-sided — the slacks bound the
interference side only, since under clearance the spare *is* the remainder and there is nothing
to absorb.

⚠️ The comparison is evaluated at the mode, following the `sign` convention above. The strict
reading (worst share against smallest slack) is available and is deliberately left to a
conformance profile, because choosing between them is a policy rather than a fact. On
`shift-line` that choice is not cosmetic: `1.7 ≤ 2.5` at the mode, `2.9 ≤ 1.0` at the strict
reading. Same filing, opposite verdicts.

⛔ **`S` must be in the layer's unit, and its natural measurement is not.** A buffer's size is
observed as a *duration* — how long stock keeps, how long a caller waits — while `H` is in the
layer's unit, so the filer owes `quantity = duration × rate` before filing. All three sized or
described slacks in the corpus were measured as durations; one of the three appears not to have
been multiplied. Whether `[0, S]` is closed is a much smaller question than that, and it is
closed: a buffer exactly full has not failed, the next unit fails. ⭐ The one genuinely
half-open interval in the model is the residue, `(−d) mod q ∈ [0, q)`, half-open for the ISO
8601 reason — at `q` it wraps to 0 rather than meaning "full".

⭐⭐ **`S`'s capacity column also closes an equation, and it is the only place the model measures
something with no instrument behind it.** Everywhere above, a slack bounds shares somebody
already filed. Here it bounds a quantity derived from the inputs:

```
max(0, d_high − n_low)   ≤   S[ℓ, capacity]_high  +  Σ_{j ∈ {customer, unrealised}} H[ℓ,j]_high
```

Read left to right: what a filing's own demand and nameplate say could have gone unserved is at
most what the supply can absorb plus what the document admits turning away. **The shortfall is
the interesting quantity** — remainder that happened and that nothing recorded, which is this
model's subject stated as arithmetic rather than as an argument. Evaluated at the one corner, for
the anti-correlation reason above.

⚠️ Two limits, both worth knowing before you trust it. It is a **transition-fit instrument
only**: under interference the exposure IS `|n − d|`'s high bound and the inequality degenerates
into the share-sum rule, and under clearance it is zero. And it is **unexercised** — not one
layer in `assets/corpus/` files a numeric capacity slack, so it is silent on nineteen of twenty-one.
A bound with nothing to bound passes loudest, and the repository says so at the test rather than
scoring itself as covered.

## Three grains, of which the model files two

⚠️ Added 2026-09-01, and it is the part most likely to be worth your time, because it is a
question about what the intervals *mean* rather than about what is done to them.

Three timescales bear on any quantity here. The **transaction grain** is the quantum `q` — the
indivisible unit supply arrives in, filed with an origin saying who sets it. The **reporting
grain** is the denominator of the unit: `per quarter`, `per week`. The **variation grain** — the
timescale on which the quantity actually moves — is filed nowhere.

The first is the model's own subject: `r = mq − (d mod q)` is a statement about it. The third
matters because two operations quietly depend on it:

- A **duty cycle** folds into a rate and vanishes. A line running 02:00–05:00 at one unit per
  five seconds has a nameplate of 2160/day; against 2000/day of demand the clearance is 160/day
  whatever the schedule. But the *duration* that clearance corresponds to does not survive: the
  naive `q / clearance` gives 9 minutes, while the real wait is 68 seconds inside the window or
  21 hours outside it. Nine minutes occurs nowhere. So a slack must be filed as a quantity, and
  the model's own worked example filed the duration until this pass.
⛔ **A second consequence was claimed here and is withdrawn, and the withdrawal is worth more
than the claim was.** It ran: a queue absorbs a transient and never a standing excess, so at
`ρ > 1` the backlog grows without bound, so `shift-line`'s demand of `[11.0, 12.7, 14.4]` against
a 10-shift line needs the variation reading to be coherent. **`ρ > 1` gives an unbounded backlog
only with infinite patience**, and `timeSlack` IS a patience — *"before the caller goes
elsewhere"*, filed `contractual`. A reneging queue is stable at any `ρ`: the backlog grows until
the wait reaches the patience, then demand departs at the rate the excess arrives. Nothing here
needs the variation reading.

⭐ And the arithmetic is exact, which is the part to check: patience `2.5 shifts = 0.25 week` at
`μ = 10/week` puts the equilibrium depth at `μW = 2.5` shifts — the queue sits AT the patience —
while the departure rate is `λ − μ = 2.7/week` and the filed holders are `customer 1.7 +
unrealised 1.0 = 2.7`. The sum rule and the queueing equilibrium agree.

⭐ `Claim` still reads as epistemic throughout — "most likely", "the value an estimator can
honestly state", and `narrowsWhen`, which means *this range is what we do not know*. Genuine
variation does not narrow when you measure harder, and the two readings are not distinguished.
That ambiguity is real; what it is NOT is the thing that makes a time buffer work.

⭐⭐ **The duty cycle half of this now has a home, and it arrived as a second axis rather than a
third value.** `Divisibility` was `lumpy | continuous` — a choice, and read as functions of the
amount asked for, `continuous` is a line and `lumpy` is a staircase `q·floor(x/q)`. A duty cycle
is the same staircase on the *time* axis, a square wave. It is not a third member of the choice,
because eight-GPU nodes available only 02:00–05:00 are lumpy in amount **and** intermittent in
time, so the type became a sequence: the choice, then an optional `window`. Its size is a
`LumpyQuantum`, and the *period* comes free from the denominator rule above.

`window` obeys one rule nothing else here obeys: **it is carried through a fusion and never
summed.** Two members naming one machine file one calendar between them; `F Φ` would give ten
days a week. It is a property rather than a quantity, which is also why the elimination vector
`e_x` ranges over demand, nameplate and draw and has no fourth component.

⛔ The variation grain itself still has no element. A `period` on `Claim` touches fifteen call
sites; an `ignorance | variation` flag is a false choice, since the honest answer is usually
both; and either is a time axis entering a model that deliberately carries none. **If you see a
fourth option, that is the most useful thing you could send back.**

## Composition: the one place a real linear map appears

A second document type consolidates filings. Given part layers indexed by `p` and composed
layers by `ℓ`, a composition declares an incidence matrix `F` (L×P, entries in {0,1}, each
part used at most once) plus a diagonal `Φ = diag(φ_p)` of strictly positive conversion
factors carrying each part into the composed layer's unit. For each quantity `x ∈ {d, n, draw}`:

```
x_composed = F Φ x_parts − e_x
```

where `e_x` is a vector of **eliminations** — quantities double-counted across parts, filed
individually with prose and the pair of filings they sit between. ⛔ And an absent `e_x` is **not**
`e_x = 0`: a missing vector cannot tell *"we looked for double counting and there is none"* from
*"nobody looked"*, and the two owe opposite arithmetic — the first requires
`x_composed = F Φ x_parts` exactly, the second requires no equality at all. The schema therefore
makes a filer say which, and that is the difference between an exact rule and a warning. Three
notes:

- `Φ`'s entries are themselves three-point intervals ("a month is `[672, 720, 744]` hours"),
  and the product is component-wise, which is sound **only** because a conversion is strictly
  positive. The general four-corner interval product is not implemented and not owed.
- ⛔ `r_composed ≠ n_composed − d_composed` when `Φ ≠ I`, and this is not a defect in either
  figure. One `φ_p` multiplies both `n_p` and `d_p`, so those converted intervals are
  correlated; differencing them with the bound reversal independent quantities require counts
  `φ`'s spread twice. `r` must be converted directly: `r_composed = F Φ r_parts + e_d`. In the
  corpus this reads `(1092.0, 2857.0, 4198.8)` re-derived against `(1414.0, 2857.0, 4085.6)`
  converted, agreeing only at the mode.
- Compositions nest, so `F` composes — and the document-scoped uniqueness constraint does not.
  At one level "no part used twice" is a key; at two it must become "no leaf reachable by two
  paths", which no validator can see because the second path runs through a document the first
  does not contain.

`F` is also where fungibility is asserted: two parts are one composed layer exactly when supply
in one can serve demand in the other. That is a judgement, it is required to carry prose, and
it is emphatically **not** `C` — coupling and fungibility are independent axes, and the corpus
populates both off-diagonal cells.

## Checking it

`assets/corpus/enterprise-contract.xml` has L=3, P=2. Two of its three layers reproduce
`r = n − d` exactly, bound reversal included, so the arithmetic checks mechanically.
`assets/corpus/refutation.xml` files a nonzero `C` entry with the observation that produced it.
`assets/corpus/merge-holding-composition.xml` exercises `F`, `Φ` and nesting together. Nothing needs
to be built: `xmllint --noout --schema schema/process-modulus.xsd <file>`, and
`--schema schema/assertion.xsd` for the compositions.
