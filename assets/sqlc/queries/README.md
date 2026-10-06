# `queries/`: the SQL the example programs read

> **Também disponível em português europeu: [`pt-PT/assets/sqlc/queries/README.md`](../../../pt-PT/assets/sqlc/queries/README.md).**

One directory per program and one file per query, each a single statement that names every relation
it reads at its head, so it runs in `psql` on its own.

| directory | read by | the question it asks |
|---|---|---|
| `readiness/` | [`examples/readiness`](../../../examples/readiness/) | may you compute here at all? |
| `observations/` | [`examples/observations`](../../../examples/observations/) | what does the corpus say? |
| `soundness/` | [`examples/soundness`](../../../examples/soundness/) | do the queries do what they claim? |
| `combinatorics/` | [`examples/combinatorics`](../../../examples/combinatorics/) | where does every row land, and does each law read what it is trusted to? |
| `walk/` | [the walk](../README.md) | each step of the walk, from one remainder to the whole structure |

Each query composes the same relations the rules read, rather than restating the joins, so a
program and a rule range over the same rows. To see what a query is built from, follow its
`:compose()` lines. A query that nothing reads fails `examples/observations`.

`cargo sqlc compose` writes the runnable SQL to `assets/sql/queries/`:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with --skip-prepare
psql -d process_modulus -f assets/sql/queries/readiness/1-sites.sql
```

`#` lines are the header, and they never reach the database. `--` lines are ordinary SQL: they
travel with the statement into Postgres and into the committed `.sqlx/` cache, which is keyed on the
query text. So the explanation goes in `#`, and `--` keeps only the line that names the query.

The `!` and `::float8` in the column names are for the Rust programs. `AS "layer!"` tells sqlx the
column is never NULL, and `::float8` gives a numeric a type it can map. Postgres reads both as an
ordinary alias and an ordinary cast, so the files run unchanged in `psql`, and the column comes back
named `layer!`.

The programs read these files with `sqlx::query_file!`, which checks the columns and their types
against a database when the program is built. After editing one, recompose and regenerate the
cache:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with --skip-prepare
cargo sqlx prepare -- --all-targets
```

The same compose line with `--verify` compares the committed `assets/sql/` with the `.sqlc` files
and fails on any difference.
