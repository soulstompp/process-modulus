The model drawn as BPMN 2.0, one document per filing, and the checks that the drawing is faithful.

> **Também disponível em português europeu:** `pt-PT/examples/diagramming/README.md`.

This program draws each filing as a BPMN 2.0 document in `assets/bpmn/filings/`, so a process
modeller can lay it beside their own model. It works like a compose step: `assets/bpmn/` is written
fresh on every run and never edited by hand, every document opens on its own, and if a diagram is
wrong, the model is what changes.

A drawing is believed in a way a table is not. A wrong table gets checked again; a wrong diagram
gets put in a deck. So the program checks itself where it cannot be generous:

- **It draws nothing by judgment.** Each relation renders as `diagrams/domain_objects.sqlc` says,
  or with the stated reason it has no element. A mapping that loses something says how: `demoted`,
  where a person can still read the fact and a tool cannot follow it, or `absent`, where the
  drawing does not carry it at all.
- **Its counts are not its own.** Every count is held against `diagrams/expected.sqlc`, worked out
  from the model by queries this program does not write. An emitter that computed its own
  expectation would agree with itself whatever it drew.
- **Every sentence names its source.** Each sentence on the drawing names the relation that states
  it, in the file and on the drawn page. Afterwards the program reads them back out and fails on a
  sentence with no source, a source that is not a relation, or a source it never queried.
- **What could not be drawn is listed**, because a blank diagram and a diagram of nothing look the
  same from outside.

## Running it

It needs the database, and writes `assets/bpmn/filings/`:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example diagramming
```
