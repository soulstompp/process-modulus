# process-modulus

> **Também disponível em português europeu: [`pt-PT/README.md`](pt-PT/README.md).**

Supply arrives in whole units. Demand does not.

A business runs as cycles inside cycles. Management decides what is committed, team leads run the
work against those commitments, and the people do the work. Management never sees the people's
load directly. It sees what the team leads committed, and the demand they report.

A platform team lead has four people committed, and the work runs between 4.5 and 6.0 people's
worth, most likely 5.2. At the most likely figure the team is 1.2 people short, and the 1.2 splits
in two. One whole person is a decision: hire one more and it moves. The other 0.2 is not. No
headcount removes it, because four people leave 0.2 short and five leave 0.8 spare.

The people carry the 0.2. They work above their rating, or work waits until it ages out. Neither
leaves a transaction behind, so nothing built from transactions shows it to management. Its size
can still be worked out, from the figures the team lead already gave.

process-modulus is an XML schema for writing that down: what a business committed, what dividing
its demand by the whole unit leaves, and who carries it. The whole unit is the modulus. A document
written against the schema goes to another organisation, which reads it and checks it with nothing
from this repository.

## Check a document

Any XSD 1.0 validator reads the two schemas. With `xmllint`:

```sh
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/coverage-us-gaap.xml
```

A validator checks the shape of each document, and it installs and changes nothing. The rules that
compare one element with another, or one document with another, run in Postgres, further down this
page.

## What a business files

A filing, `pm:processModulus`, is a business describing itself one layer at a time. A layer is a
demand, the supply that meets it, and what the division leaves. The unit is a choice: the same team
counted in people and counted in on-call weeks is two readings of one business, and their remainders
land on different people. So the schema lists no layers. A layer is any part of the business whose
remainder is held apart from every other layer's.

### What was committed, and what happened

Each supply is filed twice over. The nameplate is what was committed, before the work: four people.
The jagged record is what happened, and its draw is what the supply actually served. The draw says
who held the shortfall. Where it sits on the nameplate, the excess went unserved. Where it sits
above, somebody absorbed it. Without this second record, a receiver would read the commitment as
what happened.

The demand is a range, `low`, `mostLikely` and `high`, with its unit, who stands behind it, and
what would narrow it. A single figure would hide whether 5.2 is a measurement or a guess.

### Whole units, and the time they run

A supply divides two ways. In amount, it comes in whole units: four people are four whole people,
and the filing says who could change that unit, nobody, a counterparty or the business itself. In
time, it may run on a period and be live for only part of it. The merge members' shift line is
committed at 10 shifts a week and is live 5 days of each week. Without the window, a receiver
reading 10 shifts a week would assume all seven days. A supply can divide both ways at once, and a
supply with no period says so: four people have none, so their window is `notApplicable`.

### Who carries the remainder

The remainder has a fit. It is `clearance` when the supply covers the demand across the whole
range, `interference` when it falls short across it, and `transition` when it depends on where
demand lands. Its holders say who carries it, each with a share, and there are five kinds:
`booked`, `counterparty`, `customer`, `people` and `unrealised`. Only `booked` leaves a
transaction. The team working above its rating is `people`. The work that waited until it aged out
is `unrealised`.

The slack of each buffer says how far the supply can be driven above its rating, how much output
can be held ahead, and how long demand survives being held.

### A blank says which blank it is

`none` means somebody looked and there is nothing. `unmeasured` means nobody measured it.
`notApplicable` means the question does not arise here. A value the document already determines
is a `derivation`, which names what computes it. So *nobody measured how the people and the waiting
work split the 0.2* is something the business files. A receiver who found an empty cell would have
to guess which of these it meant.

### Documents somebody else signs

A claim about a filing cannot live inside the filing it judges, so four more documents are signed
by somebody other than the business:

| document | filed by | what it says |
|---|---|---|
| `asrt:composition` | a parent | one stack built from its members' filings: which layers are one, and what was removed so nothing counts twice |
| `asrt:dependence` | somebody who read two filings | that a layer in one moves with a layer in the other |
| `asrt:coverage` | a witness | answers to a set of questions, under a named regime |
| `asrt:run` | a witness | one dated run, promoted to evidence a report may cite |

A composition is itself a filing, so compositions nest the way a business does. A group composes
its members, and a holding composes the group.

### Beside your process model

The schema carries no sequence, gateways or events, because BPMN carries those. An operation in a
filing names its place in your BPMN model by position, so nothing is added to the BPMN. If it names
no place, it says why: it is in no process model, nobody has located it yet, or there is no process
model to point into. The repository also draws each filing as BPMN, so the two can sit side by
side.

### Regimes

A document says what it reports under, as three separate answers: the jurisdiction, the framework
and the chart of accounts. A borrowed code travels with the authority that defines it, because
`6250` is one account in Spain's PGC and another in Sweden's BAS. The buffers are Hopp and
Spearman's, from *Factory Physics*, and the fit classes are ISO 286's, both adopted as published.

[`assets/corpus/README.md`](assets/corpus/README.md) reads one layer of a filing, element by
element.

## The math, in SQL

The rules a validator cannot reach are queries. Postgres reads the corpus itself, with no extension
and no superuser. From the repository root:

```sh
createdb process_modulus
psql -d process_modulus -f assets/ddl/schema.ddl \
                        -f assets/sql/ingest.sql \
                        -f assets/sql/rules.sql
```

`rules.sql` prints every row that breaks a rule, and on the corpus that table is empty. It then
prints the referrals, things a query can find and only a person can settle, and how many rows each
rule examined.

Every query reads only what the documents filed. Like management, it never digs: what it knows of
the people's load, it works out from the team leads' figures. The first step is the platform team's
remainder:

```sql
SELECT layer, d_unit AS unit,
       n_low  - d_high AS at_worst,
       n_mode - d_mode AS most_likely,
       n_high - d_low  AS at_best,
       CASE WHEN n_low  - d_high >= 0 THEN 'clearance'
            WHEN n_high - d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS fit
FROM (
    SELECT * FROM layers_figures
) f
WHERE filing = 'enterprise-contract'
  AND d_low IS NOT NULL
  AND n_low IS NOT NULL;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/1-what-the-division-leaves.sql
```

Read the `labour` row. The worst case pairs the smallest supply with the largest demand, and the
best case pairs them the other way round, so the remainder's range is as wide as both ranges
together. All three figures are below zero, so the team is short wherever demand lands, and the
fit is `interference`.

The walk goes on in [`assets/sqlc/README.md`](assets/sqlc/README.md), one query at a time, each
built on the one before. It splits the 1.2 into the whole person and the 0.2. Then it takes in the
shares and the slack, a parent's composition and what it removes, conversions between units,
windows, counting, and the graphs the filings make. It ends with the whole structure:

```sql
SELECT r.rule,
       count(c.rule)                      AS examined,
       count(*) FILTER (WHERE c.violates) AS broken
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT * FROM checks_all
) c ON c.rule = r.rule
GROUP BY r.rule;

SELECT relation, class, standing, reason
FROM (
    SELECT * FROM epistemics_class_domain
) d;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/12-every-rule.sql
psql -d process_modulus -f assets/sql/queries/walk/12b-every-class.sql
```

The first query gives every rule the schema states, how many rows it examined, and how many broke
it. A rule that examined nothing still has its row, so an empty `broken` column means something.
The second gives every class of every classification. Each class is either `exercised`, reached by
a document, or `open`, with the reason no document reaches it yet.

## The pages

| | |
|---|---|
| [`schema/`](schema/) | the deliverable itself, and the five documents it lets anybody write |
| [`assets/`](assets/) | the documents, the queries that read them, and what is generated from both |
| [`conformance/`](conformance/) | what a profile may narrow, and which rules no validator reaches at all |
| [`examples/`](examples/) | The examples, and the question each one puts to the model |

The Rust crate generates its types from the two schemas. `cargo doc --open` shows the schemas' own
annotations, and `cargo test` reads every document in `assets/corpus/` with the generated types.
Reading is not validating: the types accept documents a validator refuses, so validate with a
validator.

The schemas are complete enough to write real documents against. The namespace URIs stay
`https://example.invalid/…` until the hosting domain is settled, and no conformance profile ships
yet.

## Licence

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in this work by you, as defined in the Apache-2.0 licence, shall be dual
licensed as above, without any additional terms or conditions.
