# The examples, and the question each one puts to the model

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

Every claim this repository makes about its own arithmetic is made inside a program that
evaluates it. This directory is those programs. One directory per program, and each one's
`README.md` **is** its header: `main.rs` opens with

```rust
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]
```

so the page you read here, the page `cargo doc --examples` renders and the page a reader of the
source sees are the same files, in both languages. A program with no header does not compile, and
neither does one with no Portuguese header.

`shared/` is not a program. It holds the modules several of these import, and it deliberately
holds no `main.rs`, which is exactly how cargo decides what is an example and how `build.rs`
decides what belongs in the table below.

| example | the question it answers | database |
|---|---|---|
| [`compositions`](compositions/) | The compositions this repository has, and the three preconditions that make them an algebra. | no |
| [`diagramming`](diagramming/) | The model, translated into BPMN 2.0, and the laws that say the translation was faithful. | yes |
| [`generation`](generation/) | Does a run of the model file at all? | yes |
| [`graphs`](graphs/) | The three graphs this model composes, as the lane sets of one pool. | yes |
| [`matrices`](matrices/) | The second witness: the same arithmetic, computed a different way. | yes |
| [`observations`](observations/) | What the corpus actually says, and whether anything is looking. | yes |
| [`readiness`](readiness/) | Before the arithmetic: may you compute here at all? | yes |
| [`rendering`](rendering/) | The layered SVG, which is the `.sqlx` of this pipeline. | no |
| [`resolution`](resolution/) | What does a lossy instrument cost, in the units the schema files? | no |
| [`soundness`](soundness/) | Does the machinery do what it claims? | yes |
| [`strain`](strain/) | What does the model have to be bent to say? | no |
| [`witnesses`](witnesses/) | Whether each rule has ever been SEEN TO SAY NO. | yes |

A `yes` there is not a suggestion. None of these programs skips when the database is absent: a
proof that passes because it did not execute is the vacuity this repository keeps naming, so they
fail to run instead. The root [`README.md`](../README.md) has the steps that build the database.

```text
cargo run --example matrices          # one of them
cargo doc --examples --open           # all of their headers, rendered
```

This table is not maintained by hand. `build.rs` reads the same directory on every build and
generates the copy that appears on the crate's front page, and `tests/examples.rs` fails if a
row here and a program's own first line disagree, if a program has no row, or if a row names no
program. Both tables are checked the same way, one per language.
