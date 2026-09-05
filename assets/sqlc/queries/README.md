# `queries/` — the example's SQL, as SQL

One file per query in [`../../examples/matrices.rs`](../../examples/matrices.rs), pulled out
so they can be read and run without Rust. Each is a single statement and each answers one
numbered section of [`../README.md`](../README.md).

```
psql -d process_modulus_proof -f assets/sql/queries/1-fit-from-ranges.sql
```

⚠️ **The `!` and `::float8` in the column aliases are for sqlx, not for you.** `AS "layer!"`
asserts to the Rust macro that the column is never NULL, and `::float8` pins a numeric to a
type the macro can map. Postgres treats both as an ordinary alias and an ordinary cast, so
these files run unchanged in `psql` — the column just comes back named `layer!`.

⛔ **Editing one of these files changes a compile-time contract.** `examples/matrices.rs`
reads them with `sqlx::query_file!`, which checks the columns and their types against a live
database at build time. The committed `.sqlx/` cache is keyed on the query text, so after
editing, regenerate it:

```
cargo sqlx prepare -- --example matrices
```
