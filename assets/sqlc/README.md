# `assets/sqlc/`: the queries, and the walk from one remainder to the whole structure

> **Também disponível em português europeu: [`pt-PT/assets/sqlc/README.md`](../../pt-PT/assets/sqlc/README.md).**

Every rule a validator cannot reach is a query here, and every query is built from smaller ones,
each of which runs on its own. This page walks through them one step at a time: from the platform
team's remainder to the whole structure, every rule with what it examined and every class with
where it stands.

Each step reads only what the documents filed. Like management, the queries never dig: what they
know of the people's load, they work out from the team leads' figures.

## Loading the documents

Postgres reads the documents itself, with no extension and no superuser. From the repository root:

```sh
createdb process_modulus
psql -d process_modulus -f assets/ddl/schema.ddl \
                        -f assets/sql/ingest.sql \
                        -f assets/sql/rules.sql
```

`ingest.sql` reads `assets/corpus/` and `assets/fixtures/` from wherever `psql` was started.
Each step below is a file of its own under `assets/sql/queries/walk/`. Its statement names every
relation it reads once, at its head, so the file runs on its own and nothing is created on the
database.

## The walk

### 1. What the division leaves

How short is each layer, and is it short wherever demand lands?

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

Read the `labour` row: the platform team. The worst case pairs the smallest supply with the largest
demand, and the best case pairs them the other way round. All three figures are below zero, so the
team is short wherever demand lands, and the fit is `interference`. The next step takes the most
likely shortfall, 1.2 people, and splits it.

### 2. Whole units, and the residue

How much of the shortfall is a decision, and how much is left over whatever anyone decides?

```sql
SELECT layer, quantum_mode AS whole_unit,
       round(n_mode / quantum_mode, 2) AS units_committed,
       floor(d_mode / quantum_mode)    AS units_asked,
       mod(d_low,  quantum_mode)       AS residue_low,
       mod(d_mode, quantum_mode)       AS residue_mode,
       mod(d_high, quantum_mode)       AS residue_high
FROM (
    SELECT * FROM layers_lumpy
) l
WHERE filing = 'enterprise-contract'
  AND d_low IS NOT NULL;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/2-whole-units-and-the-residue.sql
```

Read `labour` again. Four people are committed, and the most likely demand asks for five whole
people and a residue of 0.2. The one whole person is the decision. The 0.2 stays whatever the
headcount. The residues at the three points are 0.5, 0.2 and 0.0, which do not run low to high.
That is why a filing carries the remainder whole and never its residue as a range: the receiver
works the split out, figure by figure.

Who carried the shortfall is what the next steps ask, starting with what actually happened.

### 3. What happened

What did each supply actually serve, against what was committed?

```sql
SELECT layer, n_mode AS committed, draw_low, draw_mode, draw_high
FROM (
    SELECT * FROM layers_drawn
) d
WHERE filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/3-what-happened.sql
```

Read `capability`. Three launches a quarter were committed and three were served: the draw sits on
the nameplate, so the excess went unserved. `labour` has no row at all, because its draw is
`unmeasured`. Nobody records hours absorbed above the establishment, and nothing here turns that
blank into a zero.

### 4. Who carries the gap

The draw says whether the excess was served or not. The holders say who carried it, and how much.

```sql
SELECT r.layer,
       r.m_low, r.m_mode, r.m_high,
       h.shares_low, h.shares_mode, h.shares_high,
       h.unstated
FROM      (
    SELECT * FROM layers_remainder
) r
LEFT JOIN (
    SELECT * FROM entries_holder_totals
) h USING (filing, layer)
WHERE r.filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/4-who-carries-the-gap.sql
```

`m_low` to `m_high` is the gap, worked out from the team lead's own figures. The shares are what
the holders say they carried. For `capability`, `compute` and `support-cover` the two agree. For
`capability` the holders are `customer` and `unrealised`, as its draw said. For `labour` the gap is
0.5 to 2.0 people and both shares are unstated: the size is known, and the split between the people
and the work that waited is not. This is how management learns how busy the people are, never
directly, always through the team lead's figures. The rule `shares_do_not_sum` holds the two
together wherever every share is stated.

### 5. The slack, and the worst case

Can the shortfall at its worst go anywhere?

```sql
SELECT e.layer, e.exposure,
       s.high          AS capacity_slack,
       u.unserved_high
FROM      (
    SELECT * FROM layers_exposure_scope
) e
LEFT JOIN (
    SELECT * FROM entries_slacks
) s ON s.filing = e.filing AND s.layer = e.layer AND s.buffer = 'capacity'
LEFT JOIN (
    SELECT * FROM entries_unserved_totals
) u ON u.filing = e.filing AND u.layer = e.layer
WHERE e.filing = 'enterprise-contract';
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/5-the-slack-and-the-worst-case.sql
```

`exposure` is the shortfall at its worst. For `capability` it is five launches. The supply cannot
be driven past its rating at all, and the unserved shares come to at most five, so the worst case
is accounted for. For `labour` the capacity slack is `unmeasured`, so the worst case cannot be
checked, and the blanks say so. The rule `exposure_unaccounted` holds this wherever it can be read.

### 6. A parent's composition

The group, one cycle up, builds its own layers from its members' filings. What does it add up, and
what does it take out?

```sql
SELECT f.composed_layer, f.quantity,
       f.sum_low, f.sum_mode, f.sum_high,
       e.low  AS removed_low,
       e.mode AS removed_mode,
       e.high AS removed_high,
       f.filed_low, f.filed_mode, f.filed_high
FROM      (
    SELECT * FROM composition_fused
) f
LEFT JOIN (
    SELECT * FROM eliminations_filed
) e USING (composition, composed_layer, quantity)
WHERE f.composition = 'merge-group-composition'
  AND f.composed_layer IN ('labour', 'shift-line');
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/6-a-parents-composition.sql
```

Read `labour`'s demand. The members' demand added up is the first range. Some work was commissioned
by one member from the other, so both filed it, honestly, and the group removes it once. What is
left is the group's own demand. Then read `shift-line`'s nameplate. Both members counted the same
physical line, so the group removes one whole line. The rule `fusion_sum_disagrees` holds every
composed figure to its parts less what was removed.

### 7. Conversions between units

The holding, one cycle further up, composes layers that count in different units. How do they meet?

```sql
SELECT p.part_layer, p.factor_low, p.factor_mode, p.factor_high,
       c.quantity, c.low, c.mode, c.high
FROM (
    SELECT * FROM composition_parts
) p
JOIN (
    SELECT * FROM composition_converted
) c ON c.composition = p.composition AND c.composed_layer = p.composed_layer
   AND c.part_filing = p.part_filing AND c.part_layer = p.part_layer
WHERE p.composition = 'merge-holding-composition'
  AND p.composed_layer = 'compute'
ORDER BY c.quantity, p.part_layer;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/7-conversions-between-units.sql
```

The US member counts GPUs, and the holding counts GPU-hours. A month is 672 to 744 hours, so the
factor is a range, and so is every converted figure. The Portuguese member already counts
GPU-hours, so its part has no factor. The rule `unit_crossing_without_a_factor`
makes a part that changes units say what converts it. The rule `conversion_cycle_does_not_close`
holds a round trip of conversions to come back where it started, in the fixture whose units run
from GPU to GPU-hour to node-hour and back.

### 8. Windows

The shift line is live 5 days of each week. What happens to that when the line is composed?

```sql
SELECT filing, layer, window_mode, window_unit, amount_unit
FROM (
    SELECT * FROM layers_windows
) w
WHERE layer IN ('shift-line', 'linha-partilhada')
  AND window_mode IS NOT NULL;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/8-windows.sql
```

Each member's line is live 5 days a week, and so are the group's and the holding's. A window is
carried through a composition and never added up: 5 days and 5 days would say the line runs 10 days
a week. The rule `window_lost_or_summed` holds it.

### 9. Counting what lands where

Every remainder has a fit. Where did they all land?

```sql
SELECT relation, class, subject, balls
FROM (
    SELECT * FROM epistemics_classes
) c
WHERE relation = 'layers/remainder.sqlc'
ORDER BY ord;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/9-counting-what-lands-where.sql
```

Each layer with a remainder lands in exactly one fit, and each fit has its row, even one nothing
lands in. `epistemics/classes.sqlc` does this for every classification the queries make, which is what
the last step reads.

### 10. What is kept, and what is left

A parent sets each part's figure beside its own figure of the same kind, where it files one. Does
anything fall through?

```sql
SELECT count(*) FILTER (WHERE c.layer IS NULL)     AS not_composed,
       count(*) FILTER (WHERE c.layer IS NOT NULL) AS set_beside,
       count(*)                                    AS all_part_quantities
FROM (
    SELECT * FROM composition_parts
) p
JOIN (
    SELECT * FROM layers_quantities
) q ON q.filing = p.part_filing AND q.layer = p.part_layer
LEFT JOIN (
    SELECT * FROM layers_quantities
) c ON c.filing = p.composition AND c.layer = p.composed_layer AND c.quantity = q.quantity;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/10-what-is-kept.sql
```

Every part's figure either sits beside a figure its parent files or meets none, and the two counts
add back to the whole. Nothing is lost, and nothing is counted twice. The law `part_quantities`
holds it, one of the laws the relations rest on.

### 11. The graphs the filings make

Parts compose into layers, and units convert into units. Do any of those paths come round?

```sql
SELECT graph, n_nodes, m_edges, c_components, cycle_space_dim
FROM (
    SELECT * FROM rank_graph_measures
) g
WHERE filing IS NULL;
```

```sh
psql -d process_modulus -f assets/sql/queries/walk/11-the-graphs-the-filings-make.sql
```

Read the last column. For the layers it is 0: no layer is reached two ways, so nothing is counted
twice up the chain of parents. The rule `jagged_layer` holds it, the one rule no validator could
check even in principle. For the units it is 1, the fixture from step 7 whose conversions come
round.

### 12. The whole structure

Does every rule run, and is every class reached?

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

The laws the relations rest on have a roster of their own. `psql -d process_modulus -f
assets/sql/algebra/all.sql` checks every law against the relations it governs, across the whole
tree.

## Reading the queries themselves

`assets/sql/` is generated, and every compose rewrites it whole, so it is never edited. The sources
are the `.sqlc` files here:

```sh
cargo sqlc compose --source assets/sqlc --target assets/sql --with
```

The Portuguese walk keeps its own statements under `pt-PT/assets/sqlc/`, with its columns named in
Portuguese. They compose the relations here, found on the search path, so they are composed again
whenever those relations change:

```sh
cargo sqlc compose --source pt-PT/assets/sqlc --target pt-PT/assets/sql \
                  --search-path assets/sqlc --with
```

Each `.sqlc` file names one relation, and its header says what the relation returns, what it reads,
and why. The queries are laid out by what they are about:

| directory | what it holds |
|---|---|
| `scope/` | which documents are in view: the corpus, the fixtures, or every filing |
| `units/` | which units name a period, and the conversions between units |
| `layers/` | one row per layer: demand, nameplate, remainder, fit and absorber |
| `entries/` | each layer's facts kept apart: draws, inductions, couplings, holders, slacks |
| `composition/` | a parent's parts, their conversion, the walk down, and what each composed figure owes |
| `eliminations/` | what a parent took out, and why: filed, worked out, searched, suspended |
| `epistemics/` | what the documents say about what they know: blanks, searches, widths, and every class |
| `rank/` | the order the queries run in, and the graphs the filings make |
| `algebra/` | one law per set operation the queries use, and the roster that names them |
| `folds/` | a population counted at a coarser grain, once, for every reader |
| `arithmetic/` | every place a figure is computed, with a verdict on whether it may be |
| `diagrams/` | the model drawn as BPMN 2.0, and what a faithful drawing owes |
| `checks/` | one file per rule: every row it examined, with a verdict on each |
| `identities/` | every position a derivation may compute, in each form it may be filed |
| `relabellings/` | what a rule must not notice: the same business, said differently |
| `reports/` | findings a person settles, and the class census |

[`queries/`](queries/) holds the SQL the example programs read, one directory per program.

### The directives

| | |
|---|---|
| `:compose(path)` | put that relation in here. With `--with` it is named once, at the head of the statement, and read here by its name |
| `:compose(shape, @slot = path)` | fill a shape's open slot. A template with a slot left open is not a query, so no file is composed for it |
| `:union(ALL a, b)` | union sources whose columns already line up |
| `:count(a)`, `:count(DISTINCT cols OF a)` | count over the sources |
| `:bind(name)` | a parameter placeholder, numbered for the dialect |
| `# ...` | the header, dropped when composed |
| `-- ...` | kept in the composed SQL, saying what the relation is built from |

Slots do not carry through: a shape composed through two levels is filled at each. A relation
composed with its slots filled, or one that binds a parameter, is written out where it is composed
rather than named at the head, because it differs from one place to the next.

### Which query composes which

`public.compose_edge` holds, as rows, which query composes which and how many times.
`examples/compositions` writes it to `assets/dag/edges.sql` from the `.sqlc` files, and
`ingest.sql` loads it. So adding a `.sqlc` means: compose, run `cargo run --example compositions`,
reload `assets/sql/ingest.sql`, then `cargo sqlx prepare`.
`examples/soundness` fails if the loaded table and the files disagree.

### Said a second way

`assets/sql/invariance.sql` asks whether any rule reads a word the model says it must not. It
rewrites each shortfall a second way, runs every rule again, and prints the verdicts that moved. It
writes to the loaded tables and rolls every rewrite back, so it leaves the database as it found it:

```sh
psql -d process_modulus -f assets/sql/invariance.sql
```
