Which query composes which, and whether every name resolves, nothing composes itself, and every expansion ends.

> **Também disponível em português europeu:** `pt-PT/examples/compositions/README.md`.

There are two kinds of thing here, and they are not two readings of one thing. The relations in
`assets/ddl/schema.ddl` hold what the documents filed. The queries in `assets/sqlc/` are built on
them, and each one refers to another by name, never by repeating its SQL.

This program reads every `.sqlc` file, writes which query composes which, and how often, to
`assets/dag/edges.sql`, and holds the result to three conditions: every name resolves to a query,
no query composes itself, and every expansion has a start and an end.

## A query twice, and a layer twice

The same picture means opposite things in two places. A query composed twice under one root is
the ordinary case and costs nothing, because reading a relation twice gives the same rows. A layer
reached twice under one parent's composition is a violation, `checks/jagged_layer`, because a
supply added twice is counted twice. Same shape, opposite verdicts: what decides is whether the
thing being composed can be counted twice.

## Where a composition stops

A parent's composition nests: a group composes its members, and a holding composes the group.
Walking down it, a sum stops at the layers nothing composes, since below them there is nothing
left to add. A remainder stops earlier, at the first layer whose demand and nameplate were not both
converted by one factor that is a range. There the layer's own two figures can be compared
directly, and they are a claim its composer stands behind. Walking past them would throw that claim
away, with every correction the composer applied. `composition/descent` is the first stop, and `composition/remainder_frontier` the
second.

## Running it

It needs no database, because which query composes which is a fact about the files:

```text
cargo run --example compositions
```
