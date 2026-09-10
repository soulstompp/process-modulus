The compositions this repository has, and the three preconditions that make them an algebra.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ THERE ARE TWO LAYERS AND THEY ARE NOT TWO READINGS OF ONE THING. The DOMAIN OBJECTS are
the relational objects, `pm.*` in `assets/ddl/schema.ddl`. The COMPOSITIONS are the queries,
`assets/sqlc/**.sqlc`, and they are ad-hoc views this repository never builds: `CREATE VIEW`
appears in the schema zero times. Everything else here refers to a composition by NAME, the
way a `.sqlc` refers to another `.sqlc` and never repeats its SQL.

⭐⭐ AND THE COMPOSE DAG IS A CALL GRAPH. `sql-composer`, BPMN 2.0 and this model are the
reachability algebra of a well-founded binary relation on names, which is a claim with three
preconditions: every name resolves, no name expands to itself, the expansion has a start and
an end. This example ASSERTS all three on the real tree rather than restating them.

⛔⛔ THE ONE THAT IS WORTH THE MOST IS THE CONTRAST AT THE END. A layer reached twice inside
one fusion is `checks/jagged_layer`, a violation, because the carrier is CONSERVED and one
total closes over both occurrences. A composition reached twice inside one root is the NORMAL
CASE and costs nothing, because a query is idempotent and the planner reads the relation once.
Same substitution algebra, same graph shape, opposite verdicts. The difference is the carrier,
and it is the whole of what this model adds to its two neighbours.

# And the model's own compositions nest, which is where the analogy stops paying

`examples/matrices/main.rs` §3 builds `F`, the incidence that carries part layers into composed
ones. Compositions nest, so `F` composes — and the document-scoped uniqueness constraint does
not. At one level "no part used twice" is a key; at two it must become "no leaf reachable by
two paths", which no validator can see, because the second path runs through a document the
first does not contain. That is the rule `assets/sqlc/README.md` names as the one no validator
reaches, and it is the same substitution algebra this file asserts three preconditions on.

⭐⭐ **A nested composition has two different bottoms, one per quantity, on the same graph.** A
SUM over parts bottoms out at the layers `F` cannot descend from, because below those there is
nothing left to add. A REMAINDER bottoms out earlier: at the first layer whose own demand and
nameplate were not both scaled by one conversion factor with width. There `n − d` is legitimate
and the filed pair is a claim its composer stands behind, so descending past it discards that
claim and every correction the composer already applied, which must then be rebuilt from below
and can fail for reasons the filed figure had settled. A layer with no parts satisfies the
second condition trivially, which is why the two bottoms are easy to mistake for one.
`composition/descent` is the first; `composition/remainder_frontier` is the second.

⛔ **The terminal of the graph therefore moves with the quantity being folded**, which is not
true of either composition system this repository is otherwise analogous to. A call graph's
terminals are its terminals; a query's leaves are its leaves whatever you select. Here an
intermediate node carries a figure somebody signed, and that is what makes it a place to stop.
⭐ Which is the contrast below stated from the other side: same graph shape, and what decides
the verdict is the carrier rather than the shape.

⭐ It needs no database. The compose DAG is a fact about the source tree.

```text
cargo run --example compositions
```
