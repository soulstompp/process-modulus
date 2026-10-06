Before the arithmetic: may you compute here at all?

> **Também disponível em português europeu:** `pt-PT/examples/readiness/README.md`.

`xmllint` says a filing is well formed, and the rules say it does not contradict the model. Neither
answers the question this program asks: whether the figures in front of you can be put together at
all. Were both stated, and are they figures of the same thing?

`arithmetic/roster.sqlc` names every place the model combines two figures and, beside each, the
rule that checks they are in the same unit. The column that matters is the empty one. The
remainder, nameplate less demand, is one of the places with no such rule: `layers/remainder.sqlc`
carries the demand's unit and the nameplate's unit as two columns and subtracts across them with
nothing checking they agree.

A blank check beside a clean result is not a pass. Every unchecked place is clean in this corpus
today, which is exactly the state that looks safe and is not, so it is printed as `not checked`,
never as `ok`.

`suspended` is a third outcome beside passed and failed. A figure that cannot be computed because
somebody declined to measure one of its parts is neither a defect in the document nor a pass, and a
query that drops the row with a `WHERE` cannot say why it went. `arithmetic/all.sqlc` keeps every
such place as a row, with its verdict.

## Running it

It needs the database, reads it, and writes nothing:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example readiness
```
