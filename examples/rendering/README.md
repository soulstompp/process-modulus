The drawings as layered SVG, read from the BPMN and never from the model.

> **Também disponível em português europeu:** `pt-PT/examples/rendering/README.md`.

This program turns `assets/bpmn/*.bpmn` into `assets/svg/`, so a reader can check a drawing with no
BPMN tool at all. It opens the BPMN and nothing else, and it has no database connection. A picture
taken from the model could agree with the model while disagreeing with the BPMN it claims to show,
so it is drawn from the BPMN itself.

**The layers survive.** Every lane becomes its own `<g class="lane">`, carrying the layer's name in
`data-layer`. A flattened picture would still render and would let nobody check anything.

**The shapes are BPMN's own.** BPMN tells an activity's kind by its border, so the shape is the
information, not decoration. A `task` has a thin border. A `callActivity` has a thick one, because
it is the element that stands for another process. A `subProcess` carries the ⊞ marker. A
`participant` with no process is an empty pool, BPMN's way of saying what they do is not in this
drawing.

**It is checked against the BPMN, not against the model.** `examples/diagramming` already checked
the BPMN against the model, so the two checks together carry the SVG back to the documents, each
link checked where it can be seen. The checks attribute each shape to its kind rather than only
counting shapes, because a drawing that turned every kind into one rectangle would keep every
count right.

## Running it

It needs no database:

```text
cargo run --example rendering
```
