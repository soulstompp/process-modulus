# `queries/`, the examples' SQL, as templates

**One subdirectory per example, one file per query.** Pulled out so they can be read and run
without Rust; each is a single statement.

| directory | example | the question it asks |
|---|---|---|
| `matrices/` | [`examples/matrices/main.rs`](../../../examples/matrices/main.rs) | does the arithmetic agree with itself? |
| `readiness/` | [`examples/readiness/main.rs`](../../../examples/readiness/main.rs) | may you compute here at all? |
| `observations/` | [`examples/observations/main.rs`](../../../examples/observations/main.rs) | what does the corpus say? |
| `soundness/` | [`examples/soundness/main.rs`](../../../examples/soundness/main.rs) | does the machinery do what it claims? |

⭐ **The directory is the correspondence, rather than something a reader has to remember.** A
query added to `readiness/` and never read by `readiness.rs` shows up as an orphan in
`observations.rs`, which asserts that nothing in `assets/sqlc/` is reached by nothing at all.

⚠️ `matrices/` answers the numbered sections of [`../README.md`](../README.md). The other three
do not map onto it: `readiness/` is a view of `arithmetic/all.sqlc`, `observations/` is a tour of
relations whose product is knowledge rather than a verdict, and `soundness/` is the one that
reads several: the set-algebraic laws in `algebra/all.sqlc`, the roster contracts in
`reports/integrity.sqlc`, and what each roster's population emits when the corpus is empty.

⭐⭐ **`soundness/` is the only one that can accuse nobody's filing.** The other three ask about
the arithmetic, the data and the corpus; that one asks whether the QUERIES compute what they say.
It is where a difference that fails to a plausible table gets caught.

⭐ **Each one composes the same relations the rules do**, rather than restating the joins.
`1-fit-from-ranges` composes `layers/signed.sqlc`, which is also the population the sign rule
examines; `3b-composed-demand` anti-joins `composition/suspended_fusions.sqlc`, which is also
what `matrices.sql` anti-joins. So the example and the checker range over the same rows by
construction rather than by two authors agreeing — and if you want to see what one of these
queries is built from, follow its `:compose()` lines.

These are `.sqlc` templates. `cargo sqlc compose` writes the runnable SQL to
`assets/sql/queries/`, and that is what `psql` and `sqlx` read:

```
cargo sqlc compose --source assets/sqlc --target assets/sql --skip-prepare
psql -d process_modulus_proof -f assets/sql/queries/matrices/1-fit-from-ranges.sql
```

⚠️ **`#` is stripped, `--` is not.** A `#` line is a template comment: it exists for whoever
reads the template and never reaches the database. A `--` line is ordinary SQL and travels
with the query — into the statement Postgres parses, into `pg_stat_statements`, and into the
committed `.sqlx/` cache, which is keyed on the query text. So the argument goes in `#` and
`--` keeps only the `§` marker that names the query on the wire. Before the split, 62% of the
bytes in this directory were prose being sent to the server.

⚠️ **The `!` and `::float8` in the column aliases are for sqlx, not for you.** `AS "layer!"`
asserts to the Rust macro that the column is never NULL, and `::float8` pins a numeric to a
type the macro can map. Postgres treats both as an ordinary alias and an ordinary cast, so
these files run unchanged in `psql` — the column just comes back named `layer!`.

⛔ **Editing one of these files changes a compile-time contract.** `examples/matrices/main.rs`
reads the composed output with `sqlx::query_file!`, which checks the columns and their types
against a live database at build time. After editing a template, recompose and regenerate:

```
cargo sqlc compose --source assets/sqlc --target assets/sql --skip-prepare
cargo sqlx prepare -- --all-targets   # every example reads query_file!; one target prunes the rest
```

⛔ **`assets/sql/` is generated and wiped on every compose.** Nothing hand-written survives
there. `cargo sqlc compose --verify` diffs the committed output against the templates and
exits non-zero on drift.
