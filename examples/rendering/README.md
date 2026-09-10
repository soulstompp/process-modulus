The layered SVG, which is the `.sqlx` of this pipeline.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ IT READS THE BPMN AND NEVER THE MODEL, AND THAT IS THE WHOLE DESIGN. `.sqlx` is metadata
extracted from the GENERATED `.sql`, not from the `.sqlc`, because a cache derived from the
source could agree with the source while disagreeing with the artifact it claims to describe,
which is the definition of a stale cache. So this program opens `assets/bpmn/*.bpmn` and
nothing else. **It has no database connection**, and that is not a convenience: it is what
makes "derived from the artifact" structural rather than a promise.

⭐⭐ *PROPERLY LAYERED* IS THE ENTIRE SPECIFICATION. `.sqlx` lets a build verify with no
database present; this lets a reader verify with no BPMN tool present, and it can only do that
if the structure survives the trip. Every lane becomes its own `<g class="lane">` carrying the
layer's name in `data-layer`. ⛔ A flattened SVG is a `.sqlx` that lost its column types: it
still renders, and it verifies nothing.

⭐⭐⭐ AND *LAYERED* IS ONLY HALF OF IT: THE ALPHABET IS THE BPMN ICON SET AND NOTHING ELSE.
BPMN says which kind an activity is with its BORDER, so the glyph is the discriminator and not
decoration: a `task` is thin, a `callActivity` is THICK because it is the element that
substitutes, a `subProcess` carries the ⊞ marker, and a `participant` with no `processRef` is
an EMPTY POOL, which is the notation for *what they do is not in this diagram*.

⛔⛔ THIS PROGRAM DREW 65 IDENTICAL RECTANGLES FOR 38 TASKS, 17 CALL ACTIVITIES AND 10
SUB-PROCESSES, AND EVERY LAW IN IT PASSED. The kind was matched and dropped at the parse site,
three lines above the pen. Both laws here count, and a glyph collapse preserves cardinality by
construction, so `65 == 65` was true throughout. ⭐ The repair is attribution rather than a
bigger count, which is the same repair `diagrams/ungoverned.sqlc` made on the model side.

⛔⛔ THE LAW IS CHECKED AGAINST THE BPMN, NOT AGAINST `diagrams/expected.sqlc`. A cache is
verified against the thing it caches. `examples/diagramming/main.rs` already checked the BPMN
against the model, so the two together carry the SVG back to the corpus by transitivity, and
each link is checked where it can actually be seen.

```text
cargo run --example rendering        # no DATABASE_URL needed, on purpose
```
