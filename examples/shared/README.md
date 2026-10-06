# Shared modules, not programs

> **Também disponível em português europeu: [`pt-PT/examples/shared/README.md`](../../pt-PT/examples/shared/README.md).**

Nothing here is an example. These are the modules the programs one level up share. The directory
holds no `main.rs`, which keeps cargo from building a program from it and keeps `build.rs` from
listing it in the table in [`../README.md`](../README.md).

| module | what it is | used by |
|---|---|---|
| `simulation/` | a small simulated business on a discrete-event scheduler, and the writer that turns a run into a filing this schema admits | `generation`, `resolution`, `strain` |
| `tree/` | the one reader of `assets/sqlc/`, which follows the `:compose()` lines | `combinatorics`, `compositions`, `graphs`, `observations`, `soundness` |
| `sources/` | the one reader of `examples/` itself, asking which relations a program names | `compositions`, `observations` |
| `database/` | the one way a program opens its database, with the just-in-time compiler off, because a plan this deep costs more to compile than to run | `combinatorics`, `diagramming`, `generation`, `graphs`, `observations`, `probes`, `readiness`, `soundness`, `witnesses` |

A program reaches in by path, because a module in a sibling directory is not a child of the
program that uses it:

```rust
#[path = "../shared/tree/mod.rs"]
mod tree;
```

One reader of `assets/sqlc/`, shared, is the point. `compositions` writes which query composes
which, `soundness` works it out again to check the written copy is current, and `observations` asks
what nothing reads. Two readers of the same files could disagree, and nothing here would see it.
