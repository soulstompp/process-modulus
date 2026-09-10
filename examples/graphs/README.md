The three graphs this model composes, as the lane sets of one pool.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ THE BIG POOL IS THE MODEL, AND THE THREE GRAPHS ARE LANE SETS OVER IT. The fifteen
filing-pools `examples/diagramming/main.rs` emits sit INSIDE this one. A `laneSet` is a partition
claimed exhaustive, and three LANES would put every composition in exactly one; measured, 169
of 220 compositions touch more than one graph, because a relation reading a part AND its factor
is in the layer graph and the unit graph and that is what a factor IS. BPMN permits several
lane sets over one process for exactly this reason.

⛔⛔ AND THREE LANE SETS CANNOT ALL BE THE CONTAINMENT. An inclusion tree gives each node ONE
parent, so only one of them can be the nesting a diagram draws. That is why the graph is a
SLOT here rather than a silent pick: `entries/coupling_presence.sqlc` is asked of the corpus by
one caller and of every filing by another, both are right, and a caller supplying no `@scope`
DOES NOT COMPOSE. The choice moves from a habit into the structure.

⭐⭐ THE BPMN WORD FOR A SLOT IS ALREADY IN THE SPEC. A `participant` has an OPTIONAL
`processRef`: supply it and the pool has contents, omit it and you have a BLACK BOX POOL, which
is first-class BPMN for *a party acts here and what they do is not in this diagram*. An
unfilled slot IS a black-box participant, and this example emits one for the graph that has no
edges, rather than pretending it drew something.

```text
DATABASE_URL=... cargo run --example graphs
```
