The three graphs the filings make, each drawn as the lanes of a pool of its own.

> **Também disponível em português europeu:** `pt-PT/examples/graphs/README.md`.

The filings make three graphs. In the first, parts compose into layers. In the second, units
convert into units. In the third, claimants delegate to claimants. This program writes each graph
as its own BPMN document, `assets/bpmn/graphs/model-<graph>.bpmn`, with one pool, the model, whose
lanes are the graph's nodes. The filing pools from `examples/diagramming` are documents of their
own, and neither contains the other.

## Three sets of lanes, not three lanes

A query can sit in more than one graph. One that reads a part and its conversion factor belongs to
the layers and to the units at once, and that is what a factor is. So each graph is its own set of
lanes, as BPMN allows, rather than one lane of a single set. Only one of them can be the nesting a
drawing shows, so the graph is a slot the caller fills. `entries/coupling_presence.sqlc` is asked
of the corpus by one caller and of every filing by another, and a caller that names no scope does
not compose.

A graph with no edges is drawn as an empty pool. BPMN's word for that is a black-box participant:
a party acts here, and what it does is not in this drawing. Delegation is filed nowhere yet, so the
claimants' graph is drawn that way rather than drawn as if it held something.

## What a loop means in each

| graph | a loop there |
|---|---|
| layers | must not happen: it is a layer reached two ways, counted twice up the chain of parents |
| units | may happen, and converting round it must come back where it started |
| claimants | cannot be read yet, because nobody files delegation |

`rank/graph_measures.sqlc` counts each graph's loops, and this program holds the layers' count at
zero against `checks/jagged_layer` finding no violation. The two share no code, so their agreement
means something.

## Running it

It needs the database, and writes `assets/bpmn/`:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example graphs
```
