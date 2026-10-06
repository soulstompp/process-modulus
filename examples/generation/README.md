Does a simulated run of a business file at all?

> **Também disponível em português europeu:** `pt-PT/examples/generation/README.md`.

This program runs a small simulated business on a discrete-event scheduler written by other people
for other reasons, and knowing nothing about accounting. It writes each run out as a
`pm:processModulus` filing. Then it puts every filing through the two gates every document in
`assets/corpus/` goes through: `xmllint` against the schema, and the rules the queries run.

The point is not that a generated file validates. It is that a run nobody shaped for this schema
fills its fields without bending them. A field that has to be bent to take a simulated fact is a
finding about the field.

Every run is filed twice. One filing knows the whole history. The other knows only what a
stock-and-flow log records, so it files `unmeasured` where the first files a figure. The second is
not a worse document but an honest report of less. If a rule accused it, the rule would be accusing
a filer for not owning an instrument. No violation on either filing is the typed blanks doing their
job.

## Running it

It needs the database. Its documents are loaded inside a transaction that is rolled back, so the
database is left as it was:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example generation
```
