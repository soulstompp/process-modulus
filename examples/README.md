# The examples, and the question each one puts to the model

> **Também disponível em português europeu: [`pt-PT/examples/README.md`](../pt-PT/examples/README.md).**

Each program here asks the model one question and prints the answer. One directory per program,
and each one's `README.md` is its header: `main.rs` opens with

```rust
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/<name>/README.md")]
```

so the page you read here, the page `cargo doc --examples` renders, and the page a reader of the
source sees are the same files, in both languages.

[`shared/`](shared/) holds the modules several programs share. It is not a program, and holds no
`main.rs`.

| example | the question it answers | database |
|---|---|---|
| [`combinatorics`](combinatorics/) | Where does every row land, and does each law read what it is trusted to? | yes |
| [`compositions`](compositions/) | Which query composes which, and whether every name resolves, nothing composes itself, and every expansion ends. | no |
| [`diagramming`](diagramming/) | The model drawn as BPMN 2.0, one document per filing, and the checks that the drawing is faithful. | yes |
| [`generation`](generation/) | Does a simulated run of a business file at all? | yes |
| [`graphs`](graphs/) | The three graphs the filings make, each drawn as the lanes of a pool of its own. | yes |
| [`observations`](observations/) | What the corpus actually says, and whether anything is looking. | yes |
| [`probes`](probes/) | Whether each law has ever been seen to fail, and each correct filing seen to survive an edit that must not accuse it. | yes |
| [`readiness`](readiness/) | Before the arithmetic: may you compute here at all? | yes |
| [`rendering`](rendering/) | The drawings as layered SVG, read from the BPMN and never from the model. | no |
| [`resolution`](resolution/) | What does a lossy instrument cost, in the units the schema files? | no |
| [`soundness`](soundness/) | Do the queries do what they claim? | yes |
| [`strain`](strain/) | What does the model have to be bent to say? | no |
| [`witnesses`](witnesses/) | Whether each rule has ever been seen to say no. | yes |

A program marked `yes` fails to run without a database rather than skipping, because a check that
passes by not running has checked nothing. The root [`README.md`](../README.md) shows how to load
one.

```text
cargo run --example soundness         # one of them
cargo doc --examples --open           # all of their pages, rendered
```

`build.rs` writes the same table onto the crate's front page from the programs' own first lines,
and `tests/examples.rs` holds this table to them, in each language.
