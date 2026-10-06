Do the queries do what they claim?

> **Também disponível em português europeu:** `pt-PT/examples/soundness/README.md`.

The other programs ask about the documents. This one asks about the queries: whether each relation
does what its header says it does. Its laws accuse no filing, with one exception at the end.

It exists because a wrong set difference fails to a plausible table, never to an error. `EXCEPT` and
`LEFT JOIN … IS NULL` give the right shape, the right columns and a believable count when they are
wrong. One misplaced pair of parentheses can produce hundreds of well-formed rows where the right
answer is none, and nothing about them invites a second look.

## What it checks

- **Every difference keeps what it drops.** The rows a difference keeps and the rows it drops add
  back to what it started from. Each difference is checked by a law that runs as a query, not by
  editing the file and looking.
- **Every difference has a law.** Every set difference in `assets/sqlc/` is on
  `algebra/roster.sqlc`. A difference nobody wrote a law for is a check believed to be there and
  never made, so this assertion matters most.
- **Every conversion reads a range the same way.** Wherever a factor multiplies a range, each place
  says how it pairs the low and the high, and the list in this program is held against the files
  in both directions. A place that starts multiplying fails until it says which reading it takes.
- **Every recomputed figure matches.** A value law works a figure out again from the filed totals
  and holds the relation that computes it to the result: the remainder, its size and fit, the worst
  case, the split of a lumpy remainder, a fusion's sum per quantity, the composed whole unit and
  the composed remainder.
- **The loop count of the layers agrees with the rule.** `rank/graph_measures` counts the layers'
  loops, and `checks/jagged_layer` finds layers reached twice. They share no code and cannot
  disagree, so they are held to each other on zero against nonzero.
- **The corpus obeys its own rules.** `algebra/conforms` asks every rule on `checks/roster.sqlc`
  whether a loaded document breaks it, and the run fails if one does. This is the one law about the
  documents rather than the queries.
- **A rule with nothing to examine still says so.** That is visible only where there is nothing to
  examine, so one section empties the documents with a `TRUNCATE` inside a transaction that is
  rolled back, and checks that every rule reports it examined nothing.

## Running it

It needs the database. The `TRUNCATE` is the only write it makes, it is rolled back, and it takes an
`ACCESS EXCLUSIVE` lock while it runs, so do not point it at a database somebody else is reading:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example soundness
```
