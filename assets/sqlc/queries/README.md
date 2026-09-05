# `queries/` — the example's SQL, as templates

One file per query in [`../../../examples/matrices.rs`](../../../examples/matrices.rs),
pulled out so they can be read and run without Rust. Each is a single statement and each
answers one numbered section of [`../README.md`](../README.md).

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
psql -d process_modulus_proof -f assets/sql/queries/1-fit-from-ranges.sql
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

⛔ **Editing one of these files changes a compile-time contract.** `examples/matrices.rs`
reads the composed output with `sqlx::query_file!`, which checks the columns and their types
against a live database at build time. After editing a template, recompose and regenerate:

```
cargo sqlc compose --source assets/sqlc --target assets/sql --skip-prepare
cargo sqlx prepare -- --example matrices
```

⛔ **`assets/sql/` is generated and wiped on every compose.** Nothing hand-written survives
there. `cargo sqlc compose --verify` diffs the committed output against the templates and
exits non-zero on drift.
