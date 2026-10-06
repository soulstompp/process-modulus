Whether each rule has ever been seen to say no.

> **Também disponível em português europeu:** `pt-PT/examples/witnesses/README.md`.

The other programs ask whether the rules are right. This one asks whether they can be wrong. A rule
can examine a thousand rows and pass, and still be unable to fail: a condition true whatever the
data concludes nothing.

A witness is the smallest edit to a real filing that trips exactly one rule. Exactly one, because
an edit that trips six shows that something is checked, not that this rule is. Each witness is a
single substitution in a corpus or fixture document, and the edited document must still validate,
because a document the schema rejects says nothing about a rule the schema never reaches.

A rule with no witness is the finding. The rules that examine no row cannot have one: a rule can
only be seen to fail where it has rows to fail on, so an empty population and a rule nobody can
falsify are one fact seen from two sides.

The edited document replaces its original in the load rather than joining it, so the corpus keeps
its shape: the same filings, the same references, the same parts. Each witness also checks how many
times its anchor occurs, so an edit that would land somewhere else fails here instead of passing.

## Running it

It needs the database:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example witnesses
```
