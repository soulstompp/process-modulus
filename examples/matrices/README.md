The second witness: the same arithmetic, computed a different way.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

`assets/sql/matrices.sql` computes each matrix in the database, with joins and
`GROUP BY`. This program pulls the same rows out and computes with `nalgebra`, where a
matrix product is a matrix product. Then it asserts the two agree.

⭐⭐ THAT ASSERTION IS THE POINT, AND IT IS THIS REPOSITORY'S OWN STANDARD APPLIED TO
ARITHMETIC. `tests/independence.rs` argues that corroboration between two things sharing
a code path is worth nothing. A query that computes a number and a README that says "look,
it is right" is ONE WITNESS ASSERTING. Recomputing it by a different route and comparing
is two, and the claim `assets/sqlc/README.md` makes — that a matrix product IS a join with
a `GROUP BY` — stops being something the author said and becomes something that was
checked.

⚠️ The two sides share the ingest, and that is fine: the ingest is not what is being
proved. What is being proved is the arithmetic on top of it.

# The model, for a reader who wants the matrices

Enough to reconstruct it without reading the README, which is written for somebody else.
It ends where the flow network becomes obvious, on purpose.

A document declares a set of **layers**. Each layer ℓ carries three quantities in its own
unit: a demand `d`, a committed supply `n` (the nameplate), and a quantum `q`, the
indivisible unit supply arrives in. Supply comes in whole units, so `n = kq` for integer
`k`; demand does not. The **remainder** is `r = n − d`. Every quantity is a three-point
interval, so this is interval arithmetic throughout, and both the remainder's magnitude
and its **sign** are evaluated across the demand range. §1 recomputes both.

**The remainder is diagonal.** Nothing about layer *a* enters layer *b*'s remainder. Worth
stating outright, because the rest of the model is matrices and the natural assumption is
that they do the work here. They don't.

⛔ **There is no norm, spectrum or eigenvalue here** until somebody chooses a scaling per
layer, which is a modelling act rather than a mathematical one. What pins the direct-sum
decomposition is the units, not an inner product. Spectral vocabulary brought to this model
describes a model nobody is building.

# The dictionary, because the same objects are computed twice

Everything above has a named relation, and this is the only place the two registers are set
side by side. ⛔ The `.sqlc` headers NAME the matrix each relation is the sparse form of —
`entries/holders.sqlc` opens *"H, THE HOLDER MATRIX"* — and then argue in joins. So the
nouns are shared and the operators are not, and a reader arriving at a query never has to
hold a second formalism to follow it. This is the dictionary; every other file is one side
of it.

| here | relation |
|---|---|
| `d`, `n`, `draw` | `layers/demand`, `layers/nameplate`, `layers/drawn` |
| `r = n − d` | `layers/remainder` |
| `F` (incidence) | `composition/parts` |
| `Φ x` (converted parts) | `composition/converted` |
| `F Φ x − e` | `composition/fused` |
| `e` | `eliminations/filed` |
| `H`, `S`, `C` | `entries/holders`, `entries/slacks`, `entries/couplings` |
| `D`, `N` | `entries/draws`, `entries/inductions` |

⛔ Row counts are deliberately not written here: a count in prose is right until the corpus
next moves and silent about it afterwards. Run a relation and read the count off psql's own
footer, or run this program, which prints every figure it uses.

⭐⭐⭐ **A MATRIX-VECTOR PRODUCT IS A JOIN WITH A `GROUP BY`.** Not by analogy. `F Φ x` is
computed in two files and the difference between them is the whole of the difference between
a diagonal matrix and a general one: `composition/converted.sqlc` is `parts ⋈ demand` times a
scalar, and `composition/fused.sqlc` is the same join plus a `γ` sum. **A diagonal matrix is
a join without aggregation. A general matrix is the same join with it.** `Φ` cannot mix rows,
so it needs no `GROUP BY`; `F` sums parts into a composed layer, so it is exactly a `γ` over
the incidence. Everything else about the two is identical.

The rest of the operator set maps as plainly:

| operation | relational | note |
|---|---|---|
| transpose `Dᵀ` | `ρ`, rename | no data moves; `Dᵀ` is `D` with two columns renamed |
| `−e` | `⟕` then a guarded `coalesce` | the fill is sound only after `σ` removes the rows owing nothing |
| a zero row of `F` | a composed layer with no part row | an anti-join, `composition/leaves` in shape |
| `DᵀN` | a join on the shared operation index | the patterns compose; the quantities do not, for units |

⭐ **Running both and asserting agreement is how a claim here earns the word "checked".** A
matrix formulation is easy to reason about and easy to be wrong in silently, because every
shape error still produces a number. A relational formulation is harder to read and fails
loudly. `checks/fusion_sum_disagrees` then makes the agreement a conformance rule rather
than a test in an example somebody has to remember to run.

Run it with a loaded database:

```text
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example matrices
```

⛔ There is no silent skip. No database means it fails to run, because a proof that
passes when it did not execute is the vacuity trap this repository keeps naming.
