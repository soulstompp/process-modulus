Whether each law has ever been SEEN TO FAIL, and each correct filing seen to survive an edit that must not accuse it.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

The `soundness` example asserts that every law holds, and `witnesses` that every rule can say no.
A law is a guard as well, and a guard nobody has seen fail may be true by construction. This
program edits what a law governs and requires the law to notice.

Every probe is one edit, made inside a transaction that is rolled back, so the loaded corpus is
untouched and the whole battery is a single psql run. There are four kinds.

- **A law probe** edits the text of a composed relation as it sits inside the law's own
  statement, and names the subjects that must then fail. Most are the smallest wrong version of
  the relation: a crossed pairing read bound by bound, a divisor replaced by a maximum, a
  partition missing its last arm. A few edit the loaded rows instead, where the law's job is to
  watch the data. It reads the law from the inline composition, `target/sql-inline/`, where every
  relation the law composes is in its text; the tracked `assets/sql/` names a shared relation by
  its view, so there is nothing there to edit.
- **An acquittal** edits a correct document and names every verdict it must still get: exactly
  these rules fire, exactly these laws fail. It is the other half of a witness. A witness shows a
  rule can accuse; an acquittal shows the model does not accuse where it must not, which is where
  a suspension or a lifted figure does its work.
- **A refusal** edits a document into a state the grammar forbids and requires the validator to
  reject it, so no reader is ever asked to judge it.
- **The plans.** Every statement a program reads with `query_file!` is checked when it compiles,
  and sqlx reads its plan back as JSON through a decoder that refuses nesting past a fixed depth.
  This program measures each plan and fails before that ceiling does.

Each edit asserts how many times its anchor occurs, so a relation or a document that moves under
a probe fails here loudly instead of mutating something else and passing.

The report closes with the laws on the roster that no probe has yet seen fail. They are read from
the roster, so a law added tomorrow arrives unprobed rather than unnoticed.

The program reads no statement with `query_file!` itself, so it compiles whatever the state of the
`.sqlx` cache, and it can run after the database is reloaded and before `cargo sqlx prepare`.

Run it with:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
    cargo run --example probes
```
