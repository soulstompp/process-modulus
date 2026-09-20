Which matrix in this repository has a column space, and what lives in the half of it no potential explains?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

## The matrix is the compositions, not the quantities

A matrix of layers by quantities looks like the obvious one to ask about, and it has no column
space worth the name. Its columns mix a count of people with a rate of orders per day, so every
entry of a Gram matrix over it is a sum of products of incommensurable things.
`entries/cross_layer_edges.sqlc` already ships exactly that product, under the column names
`the_unit_that_warns_you` and `the_product_nobody_should_use`.

The obstruction is sharper than a warning, and it is worth stating as an invariance. Converting a
filing into a common unit multiplies each row by its own positive factor, a positive diagonal `D`.
Under `A -> DA`, rank, the null space and the row space do not move, and the column space and the
Gram do.

That is not the magnitude matrix having no column space. It is the magnitude matrix having one
**conditionally**, on a fact that lives in a different graph and is invisible from its own rows.
`D` exists exactly when the unit graph's conversion rule closes: the factors multiplying to one
round every loop says `log φ` carries nothing in the cycle space, which says it is a gradient,
which says a potential exists, an absolute log-size per unit. **That potential is the `D`.** So
the column space is there, fixed by a potential that belongs to a graph the matrix does not
contain, and
`checks/conversion_cycle_does_not_close` is the rule that decides whether it can be reached. The
corpus gives an interval containing one rather than one exactly, so the potential is determined up
to that width, and so is the geometry it fixes.

The compose graph has no such condition to discharge, and that is the whole of its advantage. Its
nodes are the templates under `assets/sqlc/`, its edges are the `:compose` directives between
them, and what an edge carries is a **count**. Counts are dimensionless, so `D` is the identity
and there is nothing to look up elsewhere. This is the matrix whose inner product is canonical
outright, which is why it is the one to ask first.

## The product is a join with a `GROUP BY`

Write `B` for the incidence matrix, one row per edge and one column per template, carrying `-1` at
the parent and `+1` at the child. Then `BᵀB` is the graph Laplacian: degree on the diagonal,
negative adjacency off it.

Nothing is transposed to get there. A sparse matrix held column-wise is its coordinate form, which
is a relation, so `Bᵀ` is two column names swapped and no data moves. `BᵀB` is then a self-join on
the edge index with a `GROUP BY` on the node pair, and the join's size is fixed in advance: every
edge has exactly two endpoints, so every fibre is two and the join returns `4m` rows before
grouping. A join returning anything else means the incidence is not an incidence.

## The four dimensions, and each one checked twice

```text
rank(B)   = n - c          the cut space, the gradients
ker(B)    = c              the constants, one per component
cycle     = m - n + c      the circulations
cut + cycle = m            and the two fill the edge space
```

Every line is computed by two routes that share no code. Components come from a walk; the rank
comes from elimination on the Laplacian; the cycle space comes from the edge count. An identity
with one route is a definition restated, so the program asserts the agreement rather than printing
either number alone.

## A dimension is a number, and only a basis composes

The same walk that counts the components hands back the split that makes the cycle space an
object rather than a size. It accepts an edge when the edge joins two components and rejects it
otherwise, so what it accepts is a spanning forest, `n - c` edges, and what it rejects is a chord.
Each chord closes exactly one cycle: itself, plus the single path through the forest that joins
its ends.

Those vectors are a basis, and independence comes free rather than being argued. Every other edge
of a fundamental cycle is a forest edge, so each basis vector is the only one carrying its own
chord. That is a third route to `m - n + c`, constructive where the other two are arithmetic, and
the program asserts the three agree.

Each one is checked the way a sign error deserves to be checked, by measurement rather than by
reasoning: a cycle vector has zero net at every node, so a vector with a sign wrong somewhere is
not in the cycle space at all and says so.

## What the compose graph is, which the model's own graphs are not

The model puts one rule in each half of this decomposition. A balance at a node is the fusion
rule and lives in the cut space; a sum round a loop is the conversion rule and lives in the cycle
space. The layer graph's cycle space must be zero, because a cycle there is a partition drawn too
fine. The unit graph's may be nonzero and is required to close.

The graph this repository composes obeys neither rule, and the reason is the fold. A query is
idempotent, so composing a relation twice reads it once and multiplicity costs nothing. A supply
is a conserved carrier, so the identical shape in the layer graph is a double count. Same algebra,
opposite verdicts on one fact, and the cycle space is where the difference is visible: here it is
large and free.

That is also why the graph is unweighted and `splices` is an edge vector rather than an edge
weight. Weighting the Laplacian by the splice count would assert the additive rule, which is the
one this graph does not obey.

## A vanishing circulation means a potential exists

Every edge vector splits, orthogonally and exactly, into a gradient and a circulation. The
gradient part is what some single number per template explains, through its differences. The
circulation is what no such number can reach, because it is a fact about pairs rather than about
endpoints.

That is not a new test. `checks/conversion_cycle_does_not_close` asks it of the unit graph, where
the potential is an absolute log-size per unit and the rule is that the factors multiply to one
round every loop. The same question is put here to three vectors: the all-ones vector, which asks
whether the graph is levelled; `splices`, which asks whether composing twice is a property of a
relation; and `inner_joins`, which asks whether the reach of an inner join has a potential.

The third is the one with a consequence. `algebra/dimension_use.sqlc` permits exactly one template
to inner-join the layer dimension, and says in its own header that it cannot see how a permitted
parent uses that dimension, only that it is permitted. The circulation answers the question the
list cannot: run it and read which edge carries the most.

## And the node space splits too, which is the half that was never written out

Every split above is of an EDGE vector. The node space has its own, into the row space of `B`,
which is every net some flow produces, and the nullspace, which is the constants, one per
component. They are orthogonal complements exactly as the cut and cycle spaces are.

What makes the split worth taking is that a net always sums to zero on each component. Every row
of `B` holds one `-1` and one `+1`, so `B` sends the all-ones vector to zero, and therefore a node
vector whose component totals are not zero is the net of no edge vector at all. The degree is such
a vector: the handshake puts its total at twice the edge count, so its constants part cannot
vanish, and no flow along the edges has the degree as its net.

That is the shape an elimination has in the model's own graph. A correction sitting in the row
space would move supply between layers and leave every component's total where it was; an
elimination does not, which is why it is subtracted rather than carried. `src/proofs/README.md`,
entry `elimination_leaves`, is where it is proved.

The gauge above is a pin and this is a projection, and they are different acts. Pinning a node
picks one representative out of a coset, so a potential has no constants part worth reporting.
A vector that arrives from outside has one, and it is a number about the vector rather than about
the choice.

## Running it

```bash
cargo run --example columns          # no DATABASE_URL, on purpose
```

The graph is the filesystem, so this program needs no database. It reads `assets/sqlc/` through
the one scanner `compositions`, `soundness` and `observations` share, and it checks the result
against `assets/dag/edges.sql`, which is the emitter's own copy. A disagreement there means one of
the two is stale rather than that either is wrong.

It writes five relations into `assets/arrow/`, in Arrow IPC, because neither audience for a
matrix runs Rust. `incidence` is `B`, `laplacian` is `BᵀB`, and `cycles` is the basis above, one
row per `(cycle, edge, sign)`. `templates` and `edges` carry what the split leaves on a node and
on an edge: the potential each vector induces, and the gradient and circulation each edge takes.
They join on `node` and `edge`, which is what makes the subspaces composable outside this program
rather than only inside it:

```python
import polars as pl
pl.read_ipc("assets/arrow/laplacian.arrow")
```

```r
arrow::read_ipc_file("assets/arrow/laplacian.arrow")
```

Each one is written twice, once as Arrow IPC and once as parquet. The second is for a reader
holding neither of those, because `duckdb` opens parquet with nothing installed:

```sql
SELECT parent, child, inner_joins_circulation FROM 'assets/arrow/edges.parquet'
ORDER BY abs(inner_joins_circulation) DESC LIMIT 5;
```

## A note on the polars usage

It is accurate and it is not normal. A dataframe engine is holding subspace algebra here: a join
standing in for a matrix product, a group as a fold over fibres, and a coordinate form standing in
for a sparse column. A reader arriving for analytics will find none. The engine was taken for one
property a dense matrix library does not have, which is that a column carries a validity mask
beside its values, so a filed zero and a value nobody filed are not the same bytes.
