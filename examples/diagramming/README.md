The model, translated into BPMN 2.0, and the laws that say the translation was faithful.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ THIS IS A COMPOSE STEP, NOT A DRAWING PROGRAM. Modulus is the `.sqlc`, BPMN is
`assets/sql/`, and this is `cargo sqlc compose`. So `assets/bpmn/` is GENERATED AND WIPED on
every run and must never be hand edited, every emitted document is complete and openable
ALONE, and provenance survives INTO the artifact the way the `--` line survives into generated
SQL. If you found a diagram you want to change, change the model.

⛔⛔ THE READER OF THE OUTPUT IS THE RDBMS OF THIS PIPELINE. Postgres executes a broken
difference and returns a plausible table; a brilliant analyst reads a broken diagram and
reaches a confident conclusion. Neither tells you that you were wrong, and the diagram is the
worse of the two, because a wrong table gets re-checked and a wrong diagram gets believed and
put in a deck. `assets/sqlc/diagrams/roster.sqlc` is why the laws below exist at all.

⭐⭐ THE EMITTER HAS NO JUDGMENT IN IT, AND THE EXPECTED COUNTS ARE NOT ITS OWN. Every
`pm.*` object renders as whatever `diagrams/domain_objects.sqlc` says, and every count is
checked against `diagrams/expected.sqlc`, which is computed from the model by relations this
program does not write. An emitter that computed its own expectation would agree with itself
whatever it did.

⛔ WHAT COULD NOT BE DRAWN IS ENUMERATED, because a blank diagram and a diagram of nothing are
indistinguishable from outside. That list is the boundary claim performed instead of asserted.

```text
DATABASE_URL=... cargo run --example diagramming
```
