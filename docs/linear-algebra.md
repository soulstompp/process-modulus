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
is not a valid three-point interval at all, while `d` is perfectly well formed. **Fifteen of the
twenty-three lumpy layers in `assets/corpus/` are in that state.** The total is an identity; the split is
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
Σ_{j ∉ {customer, unrealised}} H[ℓ,j]  ≤  S[ℓ, A(ℓ)]   wherever r[ℓ] < 0 and S[ℓ,A(ℓ)] is stated
```

⭐ Three things are worth flagging to a reader who will look for structure here. **These were
booleans until this pass**, which made the inequality unstatable — a bit says a buffer exists,
not how much it holds, so any share fitted. **BOTH unserved holders are exempt, because both are
the overflow**: `customer` and `unrealised` each name demand nobody met, which is not a load the
buffer held. Exempting `unrealised` alone summed a customer's borne degradation into the buffer's
load, and `Fit` calls the same pair a violation under a clearance. And the constraint is
one-sided — the slacks bound the interference side only, since under clearance the spare *is* the
remainder and there is nothing to absorb.

⚠️ The comparison is evaluated at the mode, following the `sign` convention above. The strict
reading (worst share against smallest slack) is available and is deliberately left to a
conformance profile, because choosing between them is a policy rather than a fact. On
`shift-line` the two readings diverge sharply, `1.7 ≤ 2.5` at the mode against `2.9 ≤ 1.0`
strictly. ⚠️ Note what that example now is: `shift-line` does not reach this inequality at all,
because both its holders are `customer` and `unrealised` and the left side is therefore empty.
The policy question is real; the corpus has stopped illustrating it.

⛔⛔ **And the left side is empty on EVERY corpus layer that reaches the rule, which is a finding
about the evidence rather than a gap in it.** On every interference layer that sizes its
absorbing buffer, every holder is one of the two unserved kinds: nothing was absorbed at all, the
demand was turned away. `Σ served shares ≤ S` has an empty left side because the served set is
empty, `checks/share_exceeds_slack` reports ⛔ VACUOUS, and `algebra/borne.sqlc` prints
`held = absorbed + unserved` per layer on every run rather than leaving that to a comment.

⛔ **`S` must be in the layer's unit, and its natural measurement is not.** A buffer's size is
observed as a *duration* — how long stock keeps, how long a caller waits — while `H` is in the
layer's unit, so the filer owes `quantity = duration × rate` before filing. Every slack in the
corpus carrying a size above zero was measured as a duration, and one of them appears not to
have been multiplied; `cargo run --example matrices` prints the slack census, sized against
absent, one row per buffer. Whether `[0, S]` is closed is a much smaller question than that, and it is
closed: a buffer exactly full has not failed, the next unit fails. ⭐ The one genuinely
half-open interval in the model is the residue, `(−d) mod q ∈ [0, q)`, half-open for the ISO
8601 reason — at `q` it wraps to 0 rather than meaning "full".

⭐⭐ **`S`'s capacity column also closes an equation, and it is the only place the model measures
something with no instrument behind it.** Everywhere above, a slack bounds shares somebody
already filed. Here it bounds a quantity derived from the inputs:

```
max(0, d_high − n_low)   ≤   Σ_j S[ℓ,j]_high  +  Σ_{j ∈ {customer, unrealised}} H[ℓ,j]_high

                             and only where every S[ℓ,j] is stated
```

Read left to right: what a filing's own demand and nameplate say could have gone unserved is at
most what the supply can absorb plus what the document admits turning away. **The shortfall is
the interesting quantity** — remainder that happened and that nothing recorded, which is this
model's subject stated as arithmetic rather than as an argument. Evaluated at the one corner, for
the anti-correlation reason above.

⛔⛔ **The bound is over the whole ROW of `S`, and it read the capacity column alone until this
pass.** The three buffers are substitutes: an excess above the nameplate can be absorbed by
running hot, by drawing on stock, or by making the demand wait. One column closed is ONE ROUTE
closed, which does not entail that anything went unserved, and two rules drew that conclusion
from it. ⭐ An unstated slack SUSPENDS the inequality rather than contributing zero, because
coalescing an absence to zero turns *nobody looked* into *there is no room* and manufactures a
shortfall out of a gap.

⚠️ Two limits, both worth knowing before you trust it. It is a **transition-fit instrument
only**: under interference the exposure IS `|n − d|`'s high bound and the inequality degenerates
into the share-sum rule, and under clearance it is zero. And it is **silent on almost every
exposed layer, for the reason the model itself predicts**: `layers/exposure_scope.sqlc` sorts
them into the three standings and `algebra/exposure_standing.sqlc` holds those to a partition, so
run it and read the counts. Nearly all of them have a buffer nobody sized, and NOT ONE has a
buffer with room in it. The suspension is never the harmless case; it is always an unmeasured
route, which is the same sentence `people` states about instruments. A bound with nothing to
bound passes loudest, and the coverage table says ⛔ VACUOUS rather than scoring it as covered.

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

⛔ **It is not `e` either, and that one is a type error rather than a confusion of vocabulary.**
`F ∈ {0,1}^{L×P}` carries the fungibility judgement; `e ∈ ℝ^L` carries what two parts counted
twice. `e` is not a function of `F`: a fusion of two disjoint establishments has `e = 0` and is
perfectly fungible, while a fusion of two claimants on one machine has `e` equal to a whole part's
nameplate and is equally fungible. `assets/fixtures/every-partial-elimination.xml` files the
middle of that scale — `e = 3` against parts of 10 — and reconciles under the same rule. Reading
the operation off `e` — pooling here, aggregation there — quantises a magnitude and infers a
judgement from an adjustment. There is no operator-valued
parameter anywhere in `x = F Φ x − e`, and no type tag on a row of `F`; the equation is the same
equation in every case.

⭐ **A layer the composer originated is a zero row of `F`** — a composed layer with no parts, whose
figures are the composer's own. Nothing in the arithmetic forbids it, and the model needs it: a
group-level rota belongs to the parent and came from no member.

## The same model in relational algebra, and why both are computed

Everything above is a matrix formulation. The repository also carries a relational one, and the
two are computed independently and asserted equal on every run. That is not decoration. It is the
only reason either can be trusted, and the relational side can say three things the matrix side
structurally cannot.

⛔⛔ **This document is the only place the two registers are ARGUED together, and that is
deliberate.** The sparse relations do NAME the matrix each is the sparse form of, in their opening
line, because a reader should know which object is in front of them: `entries/holders.sqlc` opens
*"H, THE HOLDER MATRIX"* and `entries/slacks.sqlc` *"S, THE SLACK MATRIX"*. What no `#` header
does is REASON in that register. The one that comes closest, `entries/cross_layer_edges.sqlc`,
says *"a shared index is what a matrix product IS"* and then argues in joins for the rest of the
file, which is the boundary rather than an exception to it. **So the nouns are shared and the
operators are not**, and a reader arriving at a query never has to hold a second formalism to
follow it. This section is where the operators are set side by side, so if you want to move
between the two, it is the dictionary and the rest of the file is one side of it.

### The dictionary

Every object above has a named relation. Cardinalities are live; recount them with
`SELECT count(*)` over the composed `.sql`, and `cargo sqlc compose` regenerates all of them.

| in the note | relation | rows |
|---|---|---|
| `d`, `n`, `draw` | `layers/demand`, `layers/nameplate`, `layers/drawn` | 43, 39, 16 |
| `r = n − d` | `layers/remainder` | 39 |
| `F` (incidence) | `composition/parts` | 23 |
| `Φ x` (converted parts) | `composition/converted` | 23 |
| `F Φ x − e` | `composition/fused` | 11 |
| `e` | `eliminations/filed` | 15 |
| `H`, `S`, `C` | `entries/holders`, `entries/slacks`, `entries/couplings` | 54, 129, 5 |
| `D`, `N` | `entries/draws`, `entries/inductions` | 4, 2 |

### The operations, which are the part worth the reviewer's attention

**A matrix-vector product is a join with a `GROUP BY`.** Not by analogy. `F Φ x` is computed in
two files and the difference between them is the whole of the difference between a diagonal
matrix and a general one:

```
Φ x    composition/converted.sqlc    parts ⋈ demand, times a scalar     23 rows in, 23 out
F (·)  composition/fused.sqlc        the same join, plus γ_sum          23 rows in, 11 out
```

⭐⭐⭐ **A diagonal matrix is a join without aggregation. A general matrix is the same join with
it.** `Φ` cannot mix rows, so it needs no `GROUP BY`; `F` sums parts into a composed layer, so it
is exactly a `γ` over the incidence. Everything else about the two is identical.

The rest of the operator set maps as plainly:

| operation | relational | note |
|---|---|---|
| transpose `Dᵀ` | `ρ`, rename | no data moves; `Dᵀ` is `D` with two columns renamed |
| `−e` | `⟕` then a guarded `coalesce` | the fill is sound only after `σ` removes the rows owing nothing |
| a zero row of `F` | a composed layer with no part row | an anti-join, `composition/leaves` in shape |
| `DᵀN` | a join on the shared operation index | the patterns compose; the quantities do not, for units |

### Sparsity, and the one thing the matrix cannot say

`F` is **14 × 22**. Dense that is 308 entries; the relation stores **23**. Seven and a half per
cent.

⛔⛔⛔ **In the matrix, a zero entry and an absent entry are the same value. In the relation they
are a row that says zero and no row at all, and the difference between those two is this model's
entire subject.** A `0` in `F` says the composer considered these two layers and judged them not
fungible. A missing row says nothing whatever. Linear algebra has one symbol for both.

The same gap runs through every quantity. A matrix entry is drawn from `ℝ`. A relation's cell here
is drawn from

```
ℝ  ⊎  {none, unmeasured, notApplicable, derived}
```

a coproduct, not a number with a sentinel. And the right-hand set is not fixed: at a
`pm:StatedClaim` position it narrows to the three-member subset without `none`, because a measured
zero carries a unit, an observer and a provenance and the absence arm has a home for none of them.
A zero there is a claim of `[0, 0, 0]`. That distinction is unrepresentable in `ℝ`, it is the
reason `NULL` is refused throughout, and nine `CHECK` constraints hold it in the database.

### The composition rule is inclusion-exclusion

```
x_composed = Σ x_parts − e            |A ∪ B| = |A| + |B| − |A ∩ B|
```

They are the same identity, with `e` in the place of `|A ∩ B|`. That framing answers the question
the note leaves open above, which is why `e` has to be filed at all:

⛔ **From `|A|` and `|B|` nothing recovers `|A ∩ B|`.** A layer carries a magnitude, never the set
the magnitude counts, so the correction is not a function of the operands. That is the whole
argument for `asrt:Elimination` being an observation with an `unmeasured` arm.

⭐⭐ **Unless you pivot to an incidence whose elements carry measures of their own, and `F`'s do.**
A part IS a layer, and a layer carries its own demand and nameplate. So express an overlap in the
part basis and the correction falls out complete, with nothing filed: `eliminations/derived.sqlc`
computes it. The test is whether the incidence's elements are themselves measured objects. `F`'s
are; `D`'s and `N`'s are not, and the same pivot buys nothing there.

⛔ What the pivot cannot name is the residue: an overlap that is a slice of a part rather than a
whole one has no element in the pivoted basis either. That case, and only that case, is what the
filed element is for.

### The quantum, and the arithmetic of divisibility

Supply arrives in whole units, so `n mod q = 0`. Two consequences the matrix formulation has no
way to state.

**A composed quantum exists, and it is the greatest common divisor.** If parts carry `q₁` and `q₂`
in the same unit then `n₁ = a q₁` and `n₂ = b q₂`, and `{a q₁ + b q₂}` is exactly the set of
multiples of `g = gcd(q₁, q₂)` by Bézout. So `g` divides every achievable sum and is the largest
number that does. Asking for a "best" `q` within a single layer is the wrong question: there the
quantum is observed, and choosing the largest divisor of `n` would infer the physics from the
number.

⭐⭐⭐ **And therefore the elimination must itself be a whole multiple of the composed quantum.**
`n_composed = n₁ + n₂ − e`, and `g` divides the sum, so `g | n_composed` requires `g | e`. **You
cannot eliminate half a machine.** It holds in every corpus case where it is checkable:
`every-local-part/both-views` eliminates 2160 against `q = 12`, which is 180 whole ovens.

⛔ **Across units there is no composed quantum at all, and the reason is narrower than it sounds.**
`gcd` is a same-unit operation. `merge-holding-composition/compute` fuses `720 GPU-hour` with
`8 GPU` and no number divides both. That is not awkward data; it is the same wall as `Φ`, which is
what crosses units, and a conversion factor multiplies a quantum too. `g = 1` is the other
degenerate case, where lumpiness dissolves and the composed supply is effectively continuous.

### Identity elements, and where an absence can impersonate one

Every quantity in this model enters either a sum or a product. The three buffer slacks are
substitutes and they add: `inventory + capacity + time`, identity 0. A duty cycle multiplies:
`delivered = rate × window ÷ period`, identity 1. A conversion factor and a quantum multiply too.

Where a grammar admits both a value and a typed absence at one position, and the absence can be
read as that operation's identity, the two are two spellings of one fact. The absence is the
lossy spelling. It carries no unit, no author for the exactness, and no origin, so a receiver
cannot compare it as arithmetic with the filers who reached for a number.

**The rule that follows: wherever the value arm names the degenerate case, the absence arm must
not be able to say the same thing.** A slack of zero is the smallest slack and is filed
`[0, 0, 0]` in the unit it is zero in. A supply that runs continuously has a duty fraction of
one and is filed as one whole period, quoted in the period's own unit, carrying the origin that
says who could shorten it. A remainder of zero is a clearance fit, filed with a sign and a
quantity of `[0, 0, 0]`, because ISO 286's line-to-line case is a clearance whose minimum
clearance is zero.

The residue is the honest case, and it is a third operation rather than an exception. A
selection from a closed set has identity ∅: no buffer absorbed the remainder, nobody sets this
bound, somebody looked for couplings and the layers move independently. Nothing there has a
size, a unit or an author, so nothing is lost by declining the element, and those positions keep
the whole four-member absence vocabulary.

### The laws are asserted, not assumed

`algebra/roster.sqlc` carries one row per set-algebraic law this tree claims, and
`examples/soundness.rs` asserts every one on every run. **A set difference anywhere in the tree
with no law on that roster fails the build.** The laws replace what would otherwise be a hand
probe: `|A| = |A∖B| + |A⋉B|` is checked live rather than argued in a comment.

⚠️ Five places where the two algebras genuinely differ, all of which cost somebody a defect here
before they were written down:

- `σ` accumulates. `σ_p(σ_q(A)) = σ_{p∧q}(A)`, which is why a rule inherits filters it never wrote
  and why its real population lives in files its author did not open.
- `π` does **not** distribute over `∖`. Project first and you subtract on fewer attributes, so a
  difference must be taken on the key.
- Bags are not sets. `composition/descent` is a bag on purpose; deduplicating it would destroy the
  very fact `leaf_reached_twice` exists to find.
- ⛔ **`γ` and `σ` followed by `π` are indistinguishable by cardinality, and they answer opposite
  questions.** `S` is keyed `(filing, layer, buffer)` and every rule's subject is keyed
  `(filing, layer)`, so the buffer index has to be collapsed. Aggregating it reads the whole row;
  filtering to one buffer and dropping the column reads one cell. **Both yield the same key, the
  same arity and one row per layer**, so every law on the roster passes on either, and no count
  anywhere separates them. Two rules concluded that demand went unserved from a premise about the
  capacity column alone, which is a statement about one of three substitutable buffers. The tell
  is never in the SQL: it is that the prose quantifies over the dimension the query dropped.
- ⛔ **A `CASE` is a partition by construction, so the partition law cannot see overlapping
  predicates.** `Σ|classes| = |candidates|` holds however the arms behave, because every tuple
  lands in exactly one of them whatever `p₁` and `p₂` do. Disjointness has to be probed on the
  **predicates**, by counting the rows where two arms both hold. `Fit` publishes three criteria
  and calls them mutually exclusive; `clearance` and `interference` both hold when a point
  nameplate equals a point demand, and `layers/remainder.sqlc` settles it by arm order.

⚠️ And one cost, measured rather than assumed: `EXCEPT` is an optimisation barrier. Asking
`composition/owed_equality` about a single composed layer evaluates the whole tree and discards
ten of eleven rows, because a set difference must materialise both sides before it can subtract.
The anti-join it was converted away from pushes the key predicate into all three arms. The
conversion was made for legibility, which is a real gain; this is its price.

### Both are computed, and the agreement is the claim

`examples/matrices.rs` builds `F`, `Φ` and `x` in `nalgebra` and evaluates three matrix products.
`assets/sql/` evaluates the same expression as joins and `GROUP BY`s. Neither is derived from the
other, and the example asserts they agree to `1e-9` over the eleven composed layers that owe the
equality. `checks/fusion_sum_disagrees` then makes it a conformance rule rather than a test.

⭐ That is the point of carrying both. A matrix formulation is easy to reason about and easy to be
wrong in silently, because every shape error still produces a number. A relational formulation is
harder to read and fails loudly. Running both and asserting agreement is how a claim in this
repository earns the word "checked".

## Checking it

`assets/corpus/enterprise-contract.xml` has L=3, P=2. Two of its three layers reproduce
`r = n − d` exactly, bound reversal included, so the arithmetic checks mechanically.
`assets/corpus/refutation.xml` files a nonzero `C` entry with the observation that produced it.
`assets/corpus/merge-holding-composition.xml` exercises `F`, `Φ` and nesting together. Nothing needs
to be built: `xmllint --noout --schema schema/process-modulus.xsd <file>`, and
`--schema schema/assertion.xsd` for the compositions.
