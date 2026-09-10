# Shared modules, not programs

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

Nothing here is an example. These are the modules the programs one level up import, and this
directory deliberately holds no `main.rs`, which is what keeps cargo from building a target from
it and what keeps `build.rs` from putting a row for it in the table in
[`../README.md`](../README.md).

| module | what it is | imported by |
|---|---|---|
| `simulation/` | a bench on NeXosim: mailboxes, an event queue and a clock, plus the filing writer that turns a run into a document this schema admits | `generation`, `resolution`, `strain` |
| `tree/` | the one scanner over `assets/sqlc/`, which reads `:compose()` directives and walks the term | `compositions`, `observations`, `soundness` |
| `sources/` | the one walk over `examples/` itself, asking which relations a program names | `compositions`, `observations` |

A program reaches in by path, because a module in a sibling directory is not a child of the
target that uses it:

```rust
#[path = "../shared/tree/mod.rs"]
mod tree;
```

⭐ **One scanner, shared, is the point rather than a convenience.** `compositions` emits the
compose DAG, `soundness` re-derives it to check that the emitted copy is current, and
`observations` asks what nothing reaches. A second reader of the same directives could disagree
with the first and no law here would see it.
