The three graphs this model composes, as the lane sets of one pool.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ THE BIG POOL IS THE MODEL, AND THE THREE GRAPHS ARE LANE SETS OVER IT. The filing-pools
`examples/diagramming/main.rs` emits, one per loaded filing, sit INSIDE this one. A `laneSet` is a
partition claimed exhaustive, and three LANES would put every composition in exactly one.
Compositions do not sit in exactly one: a relation reading a part AND its factor is in the layer
graph and in the unit graph, and that is what a factor IS. BPMN permits several lane sets over one
process for exactly this reason.

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

⭐⭐⭐ AND WHAT SEPARATES THE THREE GRAPHS IS ONE NUMBER PER GRAPH, NOT THREE DIFFERENT THEORIES.
For an incidence matrix over `n` nodes, `m` edges and `c` components, the edge space splits into
the CUT SPACE at dimension `n − c` and the CYCLE SPACE at dimension `m − n + c`. They are
orthogonal complements and they sum to `m`, so every graph here is one row of the same table, and
a cycle means something different in each because each graph puts its rule in a different half:

| graph | its cycle space | a cycle there is |
|---|---|---|
| **layers** | must be **ZERO** | ⛔ a misfiled partition: the cells were one cell |
| **units** | may be **NONZERO**, and the weights on it must vanish | ⭐ expected, and required to close |
| **claimants** | unknown, because delegation is filed nowhere | ⛔ not "nobody is accountable"; a slot with no filler |

⛔ **So "cyclic, therefore no rank" is a confusion between two senses of one word.** A graph with
cycles has no ORDINAL rank and always has a MATRIX rank.

⛔ **And "cycle" is a second word with two senses, which is the one that bites here.** `m − n + c`
counts UNDIRECTED cycles, so a zero says the graph is a FOREST. Well-foundedness is the DIRECTED
question, whether anything descends forever, and every acyclic digraph has it. A forest is
well-founded and the converse fails: a diamond is four edges over four nodes in one component, so
its cycle space is one, and nothing in it descends forever. A zero cycle space hands you the
ordinal rank; the ordinal rank hands back nothing. **So always say which cycle.** The layer graph
is both at once, and that is `checks/jagged_layer` holding it there rather than an identity: a
diamond in it is a layer composed twice, which is why `composition/descent.sqlc` is right that a
diamond is not a cycle in ITS sense and this table is right that it is one in this one.
`rank/cycle_space.sqlc` prints both dimensions for every graph that has an edge, this program
asserts the layer graph's zero against `checks/jagged_layer` finding no violation, and
`src/proofs/README.md` §10 proves the identities.

```text
DATABASE_URL=... cargo run --example graphs
```
