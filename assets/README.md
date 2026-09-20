# `assets/`: the evidence, the machinery that reads it, and what is generated from both

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

Two kinds of thing live here, and which kind a directory is decides whether you may edit it.

## Written by hand, and each one argues for itself

| directory | what it answers |
|---|---|
| [`corpus/`](corpus/) | `assets/corpus/`: what a filing looks like, and the one layer the whole model exists for |
| [`fixtures/`](fixtures/) | `assets/fixtures/`: one document per state, and NOT a second corpus |
| [`sqlc/`](sqlc/) | The same model, twice: as tables and as matrices |

Each entry above is that directory's own first line. The directory is where it is authoritative,
and this table is a way in rather than a second copy.

`ddl/schema.ddl` is the fourth hand-written thing here and has no directory of its own. It is the
relational schema, following the XML schema as closely as the two formalisms allow, so that a
claim proved against it is a claim about the model rather than about a translation. It is
deliberately not composed: `sqlc` composes statements and CTEs, and a `CHECK` expression is
neither.

## Generated, and wiped by whatever produces them

⛔⛔ **NONE OF THESE IS EDITED BY HAND, AND NONE OF THEM GETS A README**, because none has an
argument that is not its producer's. An edit here survives until the next run and then vanishes
with nothing to tell you.

| directory | written by | and it holds |
|---|---|---|
| `sql/` | `cargo sqlc compose`, from [`sqlc/`](sqlc/) | every template as a complete runnable query |
| `dag/` | [`examples/compositions`](../examples/compositions/) | the compose graph as rows, so the tree's own shape is queryable |
| `bpmn/` | [`examples/diagramming`](../examples/diagramming/) and [`examples/graphs`](../examples/graphs/) | the model translated into BPMN 2.0, one document per filing and one per graph |
| `svg/` | [`examples/rendering`](../examples/rendering/) | the layered picture, which is a proof a reader can check with no tool at all |

⚠️ `bpmn/` and `svg/` are generated **and** committed, for the same reason `sql/` is: a reader
browsing the repository should see what the pipeline produced without running it first. Committed
is not the same as editable.
