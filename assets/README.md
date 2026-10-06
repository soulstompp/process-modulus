# `assets/`: the documents, the queries that read them, and what is generated from both

> **Também disponível em português europeu: [`pt-PT/assets/README.md`](../pt-PT/assets/README.md).**

Two kinds of thing live here, and which kind a directory is decides whether you may edit it.

## Written by hand

| directory | what it holds |
|---|---|
| [`corpus/`](corpus/) | `assets/corpus/`: what a filing looks like, and one layer read end to end |
| [`fixtures/`](fixtures/) | `assets/fixtures/`: one document for each state the schema admits |
| [`sqlc/`](sqlc/) | `assets/sqlc/`: the queries, and the walk from one remainder to the whole structure |

Each entry is that directory's own first line, and the directory says the rest.

`ddl/schema.ddl` is the fourth hand-written thing here. It is the relational schema the documents
are loaded into, kept as close to the XML schema as the two allow, so that what a query shows about
the tables it shows about the model. It is written whole rather than composed.

## Generated

Nothing here is edited by hand, and none of it gets a README of its own. An edit survives until the
next run, then vanishes with nothing to say so.

| directory | written by | what it holds |
|---|---|---|
| `sql/` | `cargo sqlc compose`, from [`sqlc/`](sqlc/) | every query, composed whole and ready to run |
| `dag/` | [`examples/compositions`](../examples/compositions/) | which query composes which, as rows, so the queries' own shape can be queried |
| `bpmn/` | [`examples/diagramming`](../examples/diagramming/) and [`examples/graphs`](../examples/graphs/) | the model drawn as BPMN 2.0: one document per filing, and one per graph |
| `svg/` | [`examples/rendering`](../examples/rendering/) | the drawings, which a reader can check with no tool at all |

`sql/`, `bpmn/` and `svg/` are committed so a reader sees what was produced without running
anything. Committed does not mean editable.
