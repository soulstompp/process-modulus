What does a lossy instrument cost, in the units the schema files?

> **Também disponível em português europeu:** `pt-PT/examples/resolution/README.md`.

The other programs ask whether the queries are right and what the corpus says. This one asks how
much of the answer a recording throws away, and whether what is left is still true.

It can be answered here and nowhere else. In the wild you hold a log, and the history that produced
it is gone. In a simulation you hold both, so running one history through two instruments and
comparing their readings turns what the log fails to pin down into a figure, under conditions
anybody can reproduce.

The test is that the lossy reading contains the true one, never that it equals it. An instrument
that returned the truth exactly would have lost nothing, and this one plainly has.

The two losses it prints are not the same kind of loss:

- **Dropping the size of a refusal widens a range and keeps the truth inside it.** The field is
  still filed, as a range, with `pm:Narrowing/kind = instrument` saying a better instrument would
  tighten it.
- **Losing the ability to tell one unserved holder from another fixes their total and leaves the
  split free.** No range can say that, so both shares are filed `unmeasured`, and the total stands
  on the remainder.

## Running it

It needs no database:

```text
cargo run --example resolution
```
