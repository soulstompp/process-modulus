Does the machinery do what it claims?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

## What it does

The other examples ask about the arithmetic, the data, the corpus, and what a generated run can
be made to say. This one asks about the **queries themselves**: whether each relation computes the
operation it says it does. Its laws accuse no filing, with one exception at the end: whether the
loaded documents obey the rules at all.

## Why it exists

A set difference fails to a plausible table, never to an error. `EXCEPT` and `LEFT JOIN … IS NULL`
return the right shape, the right column names and a believable count when they are wrong. One
misplaced pair of parentheses in `reports/integrity.sqlc` produces hundreds of well-formed rows
where the correct answer is none, and nothing about them invites a second look.

## What it checks

### Every difference obeys its law

`|A ∖ B| = |A| − |A ⋉ B|`, so a difference and its semijoin must partition the left operand.
Checked by hand, that means editing the template, recomposing, observing and reverting: a
procedure nothing repeats, and one where a `sed` that silently matched nothing reports a false
finding. Here each law is a query.

### Every difference has a law

Every set difference in `assets/sqlc/` must appear on `algebra/roster.sqlc`. A difference nobody
declared a law for is `asrt:Verdict`'s `unclaimed`: a guard believed to be there and never checked.
This is the assertion that matters most.

### Every conversion reads the sign one way

Wherever a conversion factor multiplies something, the operator is the same one:
`least(x · φ_low, x · φ_high)` at the low bound, its `greatest` twin at the high, the mode a plain
product. The operand's sign picks the corner, and `CONVERSIONS` in this program declares what each
site does with it and why. The tree is held against that list in **both** directions, so a template
that starts multiplying fails the build until it says which reading it takes, and a declared site
that stops multiplying fails too.

⛔ A count of sites cannot find a second reading, because each spelling is one site.
`composition/converted.sqlc` read the corner while `algebra/fusion_sum.sqlc`, the law written to
corroborate it by a second route, multiplied bound by bound. Those are two different functions.
They agree on every non-negative operand, no filed operand is negative, and so every law here
stayed green for a whole pass while the law and the relation it checks disagreed about the
arithmetic. **A law that computes the wrong function is not independent of the relation, it is
wrong about it**, and what keeps the two routes apart is what they read rather than how they
multiply.

### Every recomputed figure matches

Some laws compare figures rather than rows. A value law recomputes a figure from the filed totals
and holds the relation that computes it to the result, subject by subject: the crossed remainder,
its magnitude and fit, the exposure, the split of a lumpy remainder, a fusion's sum per quantity,
the composed quantum and the composed remainder. The arithmetic each one relies on is proven on the
proofs page, `src/proofs/README.md`, with the same figures, and the page names the law beside each
entry.

### The layer graph's cycle space agrees with the rule

The composition graph `F` and the unit graph `Φ` sit on opposite sides of one decomposition. A
graph's edge space is its cut space plus its cycle space, and this model puts one rule in each: a
balance at a node is the fusion rule, a sum round a loop is the conversion rule. So `F` must carry
nothing in its cycle half, while the unit graph is expected to carry something in its.

⭐ An undirected cycle in `F` **is** a layer arriving twice under one fold, so `rank/cycle_space` and
`checks/jagged_layer` cannot disagree, and they share no code. The law holds them to each other on
zero versus nonzero and never on the two counts: the cycle space counts independent cycles, the rule
counts violating fusions, and one cycle can accuse more than one. Its own non-vacuity is a column,
because `0 = 0` is true of an empty graph and of a rule that examined nothing.

### The corpus is held to its own rules

`algebra/conforms` asks every rule on `checks/roster.sqlc` whether any loaded document violates it,
and the run fails when one does. The rules report and fail nothing on their own, so this is where a
document in breach stops the build. It is the one law here about the evidence rather than the
machinery, and it is on the same roster because a violation that was printed and passed anyway is
the same green that meant nothing.

### A rule with nothing to examine still says so

One law cannot be a query. Section 6 asks whether a rule still reports that it examined nothing,
which is visible only where the population is empty, so it empties the corpus with a `TRUNCATE`
inside a transaction that is rolled back. `examples/generation/main.rs` and
`assets/sqlc/invariance.sqlc` use the same idiom. The database it reads is the database it leaves.

⚠️ That `TRUNCATE` is the only write this example makes, and it takes an `ACCESS EXCLUSIVE` lock
while it runs. Do not point this example at a database somebody else is reading.

## Five places the two algebras differ

The model is computed twice, as matrices in `examples/matrices/main.rs` and as relations in
`assets/sql/`, and the two are asserted equal on every run. These five are where the relational
side does not behave the way matrix intuition expects, and each has caused a defect here.

### `σ` accumulates

`σ_p(σ_q(A)) = σ_{p∧q}(A)`. That is why a rule inherits filters it never wrote, and why its real
population lives in files its author did not open.

### `π` does not distribute over `∖`

Project first and you subtract on fewer attributes, so a difference must be taken on the key.

### Bags are not sets

`composition/descent` is a bag on purpose. Deduplicating it would destroy the very fact
`jagged_layer` exists to find.

### `γ` and `σπ` look identical and answer opposite questions

`S` is keyed `(filing, layer, buffer)` and every rule's subject is keyed `(filing, layer)`, so the
buffer index has to be collapsed. Aggregating it reads the whole row; filtering to one buffer and
dropping the column reads one cell. Both yield the same key, the same arity and one row per layer,
so every law on the roster passes on either and no count separates them. A rule that concludes
demand went unserved from the capacity column alone has made a statement about one of three
substitutable buffers. The tell is never in the SQL: it is that the prose quantifies over the
dimension the query dropped.

⭐ **One case is legitimate, and it is provable rather than arguable.** Where the dropped dimension
is CONSTANT ON THE KEY, the slice and the aggregate are the same relation, so the whole question is
whether it is constant. `units/conversions.sqlc` reads the entire conversion graph off
`quantity = 'nameplate'`, which is sound exactly while a layer names one unit across its quantities.
`algebra/layer_units` holds that as a functional dependency, `|π(layer, unit)| = |π(layer)|`, which
is what `form = 'dependency'` on the roster means: a licence that runs every time the laws run,
instead of a sentence in the pinning file's header telling a reader to run a query. A dimension
nobody can show constant leaves the `σπ` exactly where the paragraph above leaves it.

### A `CASE` cannot show overlapping arms

A `CASE` is a partition by construction, so `Σ|classes| = |candidates|` holds however the arms
behave: every tuple lands in exactly one arm whatever `p₁` and `p₂` do. Disjointness has to be
probed on the predicates, by counting the rows where two arms both hold. `Fit` publishes three
criteria and calls them mutually exclusive, yet `clearance` and `interference` both hold when a
point nameplate equals a point demand; `layers/remainder.sqlc` settles it by arm order.

## One cost: `EXCEPT` is an optimisation barrier

Asking `composition/owed_equality` about a single composed layer evaluates the whole tree and
discards all but one row, because a set difference must materialise both sides before it can
subtract. The anti-join it replaced pushes the key predicate into all three arms. The conversion
was made for legibility, which is a real gain, and this is its price.

## Running it

It needs a loaded database:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example soundness
```
