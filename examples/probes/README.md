Whether each law has ever been seen to fail, and each correct filing seen to survive an edit that must not accuse it.

> **Também disponível em português europeu:** `pt-PT/examples/probes/README.md`.

`soundness` shows every law holds, and `witnesses` that every rule can say no. A law nobody has
seen fail may be true whatever happens, so this program edits what a law governs and requires the
law to notice. Every edit is made inside a transaction that is rolled back, so the loaded database
is left untouched. There are four kinds of probe:

- **A law probe** edits a relation the law reads and names the subjects that must then fail. Most
  are the smallest wrong version of the relation: a range subtracted low from low where the pairing
  must cross, a divisor replaced by a maximum, a classification missing its last class. A few edit
  the loaded rows instead, where the law's job is to watch the data. It edits the inline
  composition in `target/sql-inline/`, where every relation a law reads is written out in full.
- **An acquittal** edits a correct document and names every verdict it must still get: exactly
  these rules fire, exactly these laws fail. A witness shows a rule can accuse; an acquittal shows
  the model does not accuse where it must not.
- **A refusal** edits a document into a state the schema forbids, and requires the validator to
  reject it, so no query is ever asked to judge it.
- **The plans.** sqlx reads each query's plan back through a decoder that stops at a fixed depth,
  and this program measures every plan and fails before that limit does.

Each edit checks how many times its anchor occurs, so a relation or a document that moves under a
probe fails loudly here instead of changing something else and passing.

The report closes with the laws on the roster no probe has yet seen fail. They are read from the
roster, so a law added tomorrow arrives unprobed rather than unnoticed.

## Running it

It needs the database, and the inline composition:

```text
cargo sqlc compose --source assets/sqlc --target target/sql-inline --skip-prepare
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example probes
```

It reads no query with `query_file!`, so it builds whatever the state of the `.sqlx` cache, and can
run after the database is reloaded and before `cargo sqlx prepare`.
