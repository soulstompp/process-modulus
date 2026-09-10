Does the machinery do what it claims?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

The other examples ask about the arithmetic, the data, the corpus, and what a generated run
can be made to say. This one asks about the **queries themselves**, whether each relation
computes the operation it says it does. It is the only one that can accuse nobody's filing.

⭐⭐⭐ IT EXISTS BECAUSE A SET DIFFERENCE FAILS TO A PLAUSIBLE TABLE, NEVER TO AN ERROR.
`EXCEPT` and `LEFT JOIN … IS NULL` return the right shape, the right column names and a
believable count when they are wrong. Written once with the parentheses misplaced,
`reports/integrity.sqlc` returned 227 rows where 0 was correct, and 227 well-formed rows is
not a thing anybody reads twice.

⭐⭐ AND THE LAW IS CHECKABLE WITHOUT TOUCHING A FILE. |A ∖ B| = |A| − |A ⋉ B|, so a difference
and its semijoin must partition the left operand. As a manual probe that is edit the
template, recompose, observe, revert: a procedure nothing repeats, and one where a `sed`
silently matching nothing reports a false finding. Each law is a query instead.

⛔ THE SECOND ASSERTION IS THE ONE THAT MATTERS MOST. Every set difference in `assets/sqlc/`
must appear on `algebra/roster.sqlc`. A difference nobody declared a law for is
`asrt:Verdict`'s `unclaimed`, a guard believed to be there and never once checked.

⛔⛔ AND ONE OF THE LAWS IS NOT A QUERY, BECAUSE IT COULD NOT BE. §6 asks whether a rule still
reports that it examined NOTHING, and that is visible only where the population is nothing, so
it empties the corpus: a `TRUNCATE` inside a transaction that is rolled back, the idiom
`examples/generation/main.rs` and `assets/sqlc/invariance.sqlc` already use. The database this reads
is the database it leaves.

⛔ IT IS THE ONLY WRITE THIS EXAMPLE MAKES, AND IT TAKES AN `ACCESS EXCLUSIVE` LOCK WHILE IT
RUNS. So this is not an example to point at a database somebody else is reading, which is
part of what it costs to run and not only of what it checks.

# Five places the two algebras genuinely differ

The model is computed twice, as matrices in `examples/matrices/main.rs` and as relations in
`assets/sql/`, and the two are asserted equal on every run. ⚠️ These five are where the
relational side does NOT behave the way the matrix intuition expects, and every one of them
cost somebody a defect here before it was written down.

- `σ` **accumulates.** `σ_p(σ_q(A)) = σ_{p∧q}(A)`, which is why a rule inherits filters it
  never wrote and why its real population lives in files its author did not open.
- `π` does **not** distribute over `∖`. Project first and you subtract on fewer attributes,
  so a difference must be taken on the key.
- **Bags are not sets.** `composition/descent` is a bag on purpose; deduplicating it would
  destroy the very fact `jagged_layer` exists to find.
- ⛔ **`γ` and `σ` followed by `π` are indistinguishable by cardinality, and they answer
  opposite questions.** `S` is keyed `(filing, layer, buffer)` and every rule's subject is
  keyed `(filing, layer)`, so the buffer index has to be collapsed. Aggregating it reads the
  whole row; filtering to one buffer and dropping the column reads one cell. **Both yield the
  same key, the same arity and one row per layer**, so every law on the roster passes on
  either, and no count anywhere separates them. Two rules concluded that demand went unserved
  from a premise about the capacity column alone, which is a statement about one of three
  substitutable buffers. The tell is never in the SQL: it is that the prose quantifies over
  the dimension the query dropped.
- ⛔ **A `CASE` is a partition by construction, so the partition law cannot see overlapping
  predicates.** `Σ|classes| = |candidates|` holds however the arms behave, because every
  tuple lands in exactly one of them whatever `p₁` and `p₂` do. Disjointness has to be probed
  on the **predicates**, by counting the rows where two arms both hold. `Fit` publishes three
  criteria and calls them mutually exclusive; `clearance` and `interference` both hold when a
  point nameplate equals a point demand, and `layers/remainder.sqlc` settles it by arm order.

⚠️ And one cost, measured rather than assumed: **`EXCEPT` is an optimisation barrier.** Asking
`composition/owed_equality` about a single composed layer evaluates the whole tree and discards
all but one row, because a set difference must materialise both sides before it can subtract.
The anti-join it was converted away from pushes the key predicate into all three arms. The
conversion was made for legibility, which is a real gain; this is its price.

Run it with a loaded database:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example soundness
```
