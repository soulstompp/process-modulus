# The same model, twice: as tables and as matrices

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

One claim, and a query for every part of it.

⛔⛔⛔ **`assets/sql/` IS GENERATED AND WIPED ON EVERY COMPOSE. NEVER EDIT IT.** The sources are
`assets/sqlc/*.sqlc`; `cargo sqlc compose --source assets/sqlc --target assets/sql --views
assets/sqlc/views.sqlc` rewrites the
whole target directory. If you found a query by grepping `assets/sql/`, find its `.sqlc` before
you touch anything, or your edit is gone on the next run and nothing will tell you.

```
../ddl/schema.ddl     the model as relations
ingest.sql            Postgres reading assets/corpus/*.xml itself, with no help
matrices.sql          the matrices, pulled out with joins — a tour, holding no logic
rules.sql             the rules XSD 1.0 cannot reach — an assembly, holding no logic
invariance.sql        each shortfall said a second way, and every rule re-run on it
views.sql             every statement two or more others compose, as a view the composed files read
queries/              one directory per example, one file per section, each runnable in psql
../../examples/matrices/main.rs   the same arithmetic again, in nalgebra, asserting agreement
```

[`queries/`](queries/) is the one line above with a page of its own: `queries/`, the examples'
SQL, as templates.

⭐ **THE TREE'S OWN SHAPE IS A RELATION.** `public.compose_edge (parent, child, splices,
inner_joins)` is which template composes which, how many times, and how many of those are inner
joins. `examples/compositions/main.rs` emits `assets/dag/edges.sql` from the source tree, `ingest`
loads it, `rank/compose_edges.sqlc` reads it. So **adding a `.sqlc` means: compose, then
`cargo run --example compositions`, then reload `assets/sql/ingest.sql` and `assets/sql/views.sql`,
then `cargo sqlx prepare`** — and `examples/soundness/main.rs` fails the build if the loaded DAG and the tree disagree.

**Every one of those is composed from smaller queries, and every smaller query runs alone.**
`assets/sqlc/*.sqlc` are templates; `cargo sqlc compose` turns them into `assets/sql/*.sql`,
which is what psql and `sqlx` read. The point of the split is not to avoid repeating a join.
It is that each file names ONE relational object, says in its `#` comments what that object
IS and what it MEANS, and can be run on its own by somebody who wants to look at the data and
ask a question that has nothing to do with any of the above.

```
scope/         which documents are in view              — corpus, fixtures, everything
units/         which units carry a denominator         — and which denominators, over all claims
layers/        one row per layer, one fact per column  — d, n, r = n − d, the absorber
entries/       the sparse matrices                     — D draw, N induction, C coupling, H holder, S slack
composition/   F and Φ, the walk, and what it owes     — parts, conversion, descent, leaves
eliminations/  e, what a composer took out and why     — filed, derived, searched, suspended
epistemics/    what the documents say about knowing    — absences, searches, widths, edges, roots
rank/          the order, the graphs, and the fold     — evaluation order, cycle space, reach, the subspaces
algebra/       one law per set operation the tree uses — and the roster that declares them
folds/         a population folded to a coarser grain, once, for every reader; views.sql names each
arithmetic/    one site per computation, with a verdict — every interval, every unit
diagrams/      the model rendered into BPMN 2.0        — plus the rosters a translation owes
checks/        one file per rule: every row it examined, with a verdict on each
identities/    every position an identity may compute, in each arm it may be filed
relabellings/  what a rule must not notice: the same system, said differently
reports/       findings a person settles, and the two views of checks/
```

⭐⭐ **The tree is the model's own derivation order.** `layers/remainder.sqlc` composes
`layers/demand.sqlc` and `layers/nameplate.sqlc`, because a remainder IS a difference of two
vectors. `composition/leaves.sqlc` anti-joins `composition/fusions.sqlc`, because a leaf IS a
reached layer that is not a fusion. ⭐ And `composition/unsettled.sqlc` is the other bottom:
a remainder's descent stops earlier than a sum's, at the first layer whose demand and nameplate
were not both scaled by one factor with width, because differencing them is legitimate there.
Reading the `:compose()` edges top-down is reading what this model thinks is built out of what — which is the thing the schemas state in prose, and
this tree is where it is checkable and browsable rather than only readable.

**The claim:** rules in this model are written in the schemas' prose and checked by nothing,
because XSD 1.0 has no `xs:assert` and cannot compare one element against another.
Look at what those rules actually say. *The shares sum to the magnitude. The sign agrees with
the range comparison. No leaf is reachable by two paths.* Those are joins and sums and
comparisons — impossible in a grammar, ordinary in a query language.

**What this is.** A relational schema that follows the XML schema as closely as the two
formalisms allow, so that a claim proved here is a claim about the model rather than about a
translation of it. It is sound and it is performant: the composition nests dozens deep and the
planner pulls every level up, measured rather than assumed.

**What it is not.** Tuned for your workload. The shape is chosen to keep the correspondence with
the XSD visible, not to serve an application's read patterns, and a real deployment will want
indexes, denormalisation and a write path this has no opinion about. Take the model; shape the
storage for the job in front of you.

**Three ways in, and they are the same subject at three depths.** Take whichever one is
already your daily tool — you can read any of them first and the other two refer to it.

| you work in | start at | it will get you |
|---|---|---|
| SQL, data modelling | [from the relational side](#from-the-relational-side) | why an empty table is not a zero |
| **consolidation, audit, reporting** | [from the financial side](#from-the-financial-side) | the consolidation you already do, written as one expression — and the one place your instinct is wrong |
| matrices, optimisation | [from the linear-algebra side](#from-the-linear-algebra-side) | what a range does that a number does not |

## Running it

The SQL half needs a Postgres and nothing else. No Rust, no extensions, no superuser.

```
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/ddl/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/views.sql \
                              -f assets/sql/rules.sql
```

Run it from the repository root — `ingest.sql` reads `assets/corpus/*.xml` from the client
side, so paths are relative to wherever you started `psql`.

`views.sql` loads after the ingest and before any query. Every statement two or more others
compose, and every statement in `folds/`, is a view named `<directory>.<name>`, and the composed
files read it by that name rather than repeating it in every reader. The templates still compose
one another, so the tree is the same; `cargo sqlc compose --source assets/sqlc --target <dir>`
without `--views` writes every statement whole, which is the form for experiments and for tuning
a plan.

### One relation, three presentations

A statement here exists three ways, and the same rows come out of each.

1. **The composition**, the `.sqlc` file. This is what you read, and what every law and rule
   argues about. Composed on its own it is a complete query: `assets/sql/layers/remainder.sql`
   runs against nothing but the schema and the ingest.
2. **The view**, so that `SELECT * FROM layers.remainder` answers in psql and `\d` describes it.
3. **The definition**, `:define(...)` in a statement's own `WITH` clause, used where a program
   reads the columns.

⭐ **The third one exists for a reason worth knowing, because it is a property of Postgres rather
than a habit of this repository.** A column's origin is fixed when the statement is parsed. Read
through a view, the origin *is* the view, and a view's `pg_attribute.attnotnull` is always false;
read through a `WITH` clause or a subquery, Postgres follows the target list down to the base
table, where the `NOT NULL` actually lives. So a view keeps every row and loses the declaration,
and a program that reads `filing` gets `Option<String>` for a column the schema says can never be
absent. The statements `sqlx` reads therefore define their vocabulary instead of borrowing the
name: see the `WITH` clause at the top of `diagrams/calls.sqlc`, which is three definitions long.
**A view is a name for a relation; a definition is where the relation is.**

### The directives

The whole grammar, which is smaller than it looks:

| | |
|---|---|
| `:compose(path)` | splice that relation in here; where it has a name, the name is written instead |
| `:define(path)` | splice its body in here *even where it has a name*, and let the name in front of `AS` stand for it everywhere below |
| `:compose(shape, @slot = path)` | fill a shape's open slot. A template with a slot left open is not a query, so compose emits no file for it |
| `:union(ALL a, b)` | union sources that are already union-compatible |
| `:count(a)`, `:count(DISTINCT cols OF a)` | count over the sources |
| `:bind(name)` | a parameter placeholder, numbered per dialect |
| `# ...` | stripped at compose. The argument, and there is no length limit on it |
| `-- ...` | survives into the composed SQL. The provenance, and in a file of this size the only navigation there is |

Slots do not inherit: a shape composed through two levels must be filled at each one. And a
relation with an open slot or a bind cannot be a view, because a view takes no argument.

`invariance.sql` is a separate run, and it asks a different question: does any rule read a word
the model says it must not? It rewrites each shortfall a second way, re-runs every rule, and
prints the verdicts that moved. ⛔ It writes to the corpus tables and rolls every rewrite back,
so the database it reads is the database it leaves.

```
psql -d process_modulus_proof -f assets/sql/invariance.sql
```

The second half recomputes the same answers a different way and asserts they match:

```
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example matrices
```

---

## The one idea both algebras share

Everything here rests on one sentence, and it is smaller than it sounds.

> **A matrix is a table, and multiplying two matrices is a join with a `GROUP BY`.**

A matrix entry `D[p,l] = 3` is a row `(p, l, 3)`. The textbook definition of a product,

```
(AB)[i,k] = sum over j of A[i,j] * B[j,k]
```

reads in English as *find the pairs that share an index, multiply them, add up the groups.*
Which is:

```sql
SELECT a.i, b.k, sum(a.v * b.v)   -- multiply them, add them up
FROM a JOIN b ON a.j = b.j        -- the pairs that share an index
GROUP BY a.i, b.k;                -- the groups
```

If you have ever written a join with a `SUM` in it, you have multiplied matrices. Nobody told
you that was what it was. → **checked in [§3](#3-fφx--e-as-an-actual-matrix-product)**

⛔ **And the query being legal is not the product being meaningful, which is the one caveat to
carry from here.** The join always runs. Whether its answer means anything depends on whether the
two operands are in a unit that survives being multiplied, and in this model almost none of them
are: each layer carries its own unit, so multiplying a draw by an induction yields `people *
launches`. **`FΦx` is the one product here that composes magnitudes**, because `F` relates layers
to layers and `Φ` puts them in one unit first. → **[`DᵀN` composes, but its quantities do
not](#dᵀn-composes-but-its-quantities-do-not)**

⭐⭐ **And if you have ever consolidated a group you have done it by hand.** Adding members up
along an ownership structure IS `Fx`; the incidence is which member rolls into which line. →
**[from the financial side](#from-the-financial-side)**, which is the shallow end of the same
water and the place to start if the notation is not your daily tool.

The direction that matters more here is the other one. Once you know a matrix is a table you
can ask it questions matrix notation cannot write down — *which of these entries did somebody
actually measure?* — and that turns out to be what this model is about.

---

## Seven kinds of zero

This is the spine. Almost every interesting thing below is a zero, and they are not the same
zero. Telling them apart is the entire subject, on both sides.

| the zero | what it means | where |
|---|---|---|
| **the good zero** | a result that is empty *for a reason worth reading* | `DᵀN` — [§2](#2-dᵀn-the-good-zero) |
| **the bad zero** | two different facts collapsed into one number | densified `C` — [§5](#5-what-densifying-costs) |
| **the dangerous zero** | a rule that examined nothing and looks like a pass | the coverage table |
| **the zero you want** | no violations, from rules that did run | `rules.sql`'s first table |
| **the same zero, twice** | one fact with two spellings | `absent/reason = none` vs a claim of `[0,0,0]` |
| **the boundary zero** | a comparison landing exactly on the line | `n_low = d_high` — a chosen convention |
| **the zero that should NOT be zero** | a table whose emptiness would mean nobody looked | the referrals below |
| **the zero that is now two zeros** | a blank that carried "checked and found nothing" and "nobody checked" at once | `coupling_search`, `elimination_search` — [§8](#8-the-zero-that-turned-out-to-be-two) |

**The good zero is the one to understand first**, because it is the one people delete. `DᵀN`
comes out empty in this corpus. Not because the query is wrong — because the only operation
that both draws and induces has a draw **nobody measured**. The matrix that would show
cross-layer structure is blank *precisely because* the interesting quantity has no instrument,
which is the thing this whole model was built to say. Delete that result as uninteresting and
you have deleted the finding.

**The dangerous zero is the one that gets published.** A rule with nothing to check returns
no violations, which looks identical to a rule that checked everything and found nothing wrong.
This repository already has a name for it: *"a bound with nothing to bound passes loudest."*
That is why `rules.sql` ends with a count of what each rule actually examined, and why the
example asserts on its own sample sizes before asserting on its answers.

---

## From the relational side

Relational algebra is six operations. You use all of them already; here is where each lands.

| operation | what it does | here |
|---|---|---|
| **selection** (σ) | keep the rows matching a test | `WHERE sign = 'transition'` — one layer in the whole corpus |
| **projection** (π) | keep some columns | pulling `(layer, low, mode, high)` out of a filing |
| **rename** (ρ) | call a column something else | how `D` and `Dᵀ` differ; a transpose is a rename |
| **product** (×) | every row against every row | what a join is before you add the condition |
| **union** (∪) | the rows of either | how `rules.sql` folds every check on `checks/roster.sqlc` into one answer |
| **difference** (−) | the rows of one not in the other | **what a rule check IS** |

That last row is the useful one. `rules.sql` never asks *"did this pass?"* It asks for the rows
that **fail**, which is a difference, and an empty answer means every row was in the other set.

**And there is a seventh nobody teaches, which fits this model exactly.** Relational
**division** (÷) answers *"which X relate to ALL of the Y?"* — which layers have all three
buffers measured, which compositions use every part of a member. Matrix notation has nothing
that says "all of", and this model asks it constantly.

⛔⛔ **THE JOIN CONDITION IS WHERE THE ACCOUNTING LIVES, AND IT IS WHY THIS SECTION COMES
FIRST.** Two figures are comparable when they cite the same authority, which is an `ON` clause;
where they do not, the rows simply **fail to join**, and a pair that does not join says something
a NULL cannot. That is one operation doing what a chart of accounts does. → **[from the financial
side](#from-the-financial-side)** for what it costs to get wrong, and **[from the linear-algebra
side](#from-the-linear-algebra-side)** for the arithmetic on top of it. Both refer back here,
because the relational form is the one that can say *nobody looked*.

### Why the tables are shaped as they are

**Two index sets, and everything below is indexed by one or both.** `L` is the LAYERS, keyed
`(filing, layer)` and conformed across the whole corpus, so the same layer in two documents is
one index. `P` is the OPERATIONS, keyed `(filing, label)`. Every shape written `L×3` or `P×L`
below means rows indexed by the first and columns by the second. Nothing here is indexed by a
filing, a buffer name or a unit: those appear as the small fixed dimensions, `3` for the buffers
and `5` for the holder kinds.

**The tables that ARE matrices are tall. The ones holding attributes are wide.**

`slack` has one row per layer per buffer — three rows, not three columns — so the table *is* the
L×3 matrix the note calls `S`. Same for `holder` (L×5), `draw` and `induction` (P×L), `coupling`
(L×L), and `part`, which carries `F` and `Φ` together because a part *is* an incidence entry and
its conversion factor at once. Meanwhile `nameplate` is wide: an amount and a quantum and a
window are facts about one supply, not entries of anything.

**Every tall table is sparse, and sparse means something here.** An entry that is zero is a
row that is not there. So `C = 0` — the model's central assumption, that layers are independent
— is not a grid of zeros. It is *an empty table.* And an empty table cannot tell you whether
somebody looked and found nothing, or nobody looked.

⭐⭐⭐ **AND THE FIX IS NOT A RELATIONAL ONE. IT IS A SECOND TABLE, BECAUSE THE SECOND FACT IS
ABOUT THE SEARCH RATHER THAN ABOUT ANY ROW.** `coupling_search` has one row per filing saying
what happened when somebody went looking; `elimination_search` does the same for each fusion.
Neither is a matrix, neither has a shape, and neither could have been a column on the tall
table it explains — you cannot attribute "nobody looked" to a row that is not there. →
**[§8](#8-the-zero-that-turned-out-to-be-two)**

That is typed absence arriving from the relational side. It is why every quantity column has a
partner `absent` column carrying a reason, and why the DDL makes exactly one of the two present:

```sql
CONSTRAINT slack_is_stated_or_typed_absent
    CHECK ((low IS NOT NULL) <> (absent IS NOT NULL))
```

A plain `NULL` says nothing about *why* it is null, which is the failure this model exists to
avoid. → **the cost of losing this is [§5](#5-what-densifying-costs)**

---

## From the financial side

⭐⭐⭐ **IF YOU CONSOLIDATE ACCOUNTS FOR A LIVING YOU ALREADY DO LINEAR ALGEBRA AND NOBODY CALLS
IT THAT.** This section is the shallow end on purpose: no eigenvalues, no decomposition, nothing
you have not done by hand every period. Four operations, and every one of them has a name in
your work already.

| you call it | it is | in this model |
|---|---|---|
| adding the members up | a matrix product, `Fx` | `part` joined to the members' layers |
| translation, restatement, unit conversion | a scale applied one part at a time, `Φ` | `Part/factor` |
| elimination entries | a vector subtraction, `e` | `Elimination`, one row per quantity |
| the consolidated column | `FΦx − e` | the composed layer's own claim |

**That is the entire consolidation, written once.** `FΦx − e` — take the members, put them in one
unit, add them along the ownership incidence, subtract what was counted twice. → **and it is
checked against the filings in [§3](#3-fφx--e-as-an-actual-matrix-product), every composed layer
quantity the corpus owes, to the digit.**

### The chart of accounts is a basis, and two charts are two bases

⛔⛔ **THIS IS THE ONE THAT COSTS MONEY.** `6250` in one chart and `6226` in another are not two
values of one thing. They are **coordinates in different bases**, and adding them is a change of
basis nobody recorded. Every accountant knows this and every spreadsheet forgets it, because a
code is a string and strings concatenate.

The corpus files the same question under US GAAP and under NCRF-PE. Read what happens:

```
labor.absorbed-evening          both refuse: `not-a-financial-fact`      COMPARABLE
                                same coding pack, same taxonomy URI

compute.reserved-block-idle     US holds 6250, PT holds 6226             NOT COMPARABLE
                                two charts; nothing maps them
```

⭐⭐ **The refusals compare and the positions do not, and that is not an inconsistency — it is
the finding.** A refusal code comes from a pack that is deliberately shared across jurisdictions;
a chart position does not. The model carries both as `BorrowedTerm`, which names the authority
beside the value, so **the comparison either joins or it does not.** No NULL, no silent
`6250 ≠ 6226` comparison of unrelated strings. ↑ *that is [relational division and the join
condition](#from-the-relational-side) doing accounting work: comparability IS the `ON` clause.*

Portugal has a national chart under SNC. The United States has none, so its witness cites the
entity's own. **A model that stored a position as a bare code would have compared them and
reported agreement.**

**This one is not proved by a query in this directory, and saying so is the honest thing.**
The coverage documents are not ingested — they carry no quantities, so they are not matrices and
there is nothing here for a join to do. The proof is
[`tests/coverage_parse.rs`](../../tests/coverage_parse.rs), in
`two_regimes_are_comparable_where_they_share_an_authority`, which asserts both halves: that the
refusals compare **and** that the positions do not. A claim whose evidence lives elsewhere should
say where rather than borrowing the authority of the section it sits in.

### An elimination is the only entry that makes a number smaller

⛔⛔⛔ **AND AN UNEXPLAINED REDUCTION IS THE SHAPE EVERY ACCOUNTING SCANDAL HAS IN COMMON.** So
`Elimination/observed` is required, and `Elimination/against` is required, because an elimination
that does not say *which of the three quantities* it removes is an adjustment applied to whichever
number the reader happened to be holding.

The three are `demand`, `nameplate`, `draw` — what was asked, what was committed, what was
served. A consolidation standard eliminates **balances**; these are not balances, which is why
this model contributes the distinction rather than borrowing one.

**`nameplate` eliminates far more rarely than it looks**, and the asymmetry is the interesting
part: two members' people are two sets of people, so labour nameplate almost never eliminates. A
reservation one member holds and **resells** to another does. If your consolidation is netting
capacity as freely as it nets revenue, one of those two is wrong.

### ⭐⭐ What licenses a row of `F` in the first place

`F` looks like an ownership matrix and it is not one. Consolidation scope tells you WHICH entities
go in; it does not tell you which of their capacities are the **same capacity**. A 1 in `F` says
two filed layers are ONE layer, and what licenses it is **fungibility**: can a unit of supply in
one part serve demand in the other?

⛔ **The question is between two different members by construction**, so "they serve different
customers in different countries" does not answer it — that is a statement about coupling. What
settles it is whether one member's people can take the other's work.

⭐ **Which is why the paragraph above is not a contradiction.** Two members' people are two sets of
people, so `nameplate` almost never eliminates — and those two sets can still be one layer, because
fungible means *interchangeable*, not *shared*. Money is fungible without being one coin. The
elimination measures double counting, `F` carries the fungibility judgement, and they are
independent axes: reading one off the other is the mistake a file this full of arithmetic would
otherwise invite.

The judgement is the composer's, it is required to carry prose, and it is the claim a reader is
entitled to argue with. See `asrt:Fusion`.

### ⭐⭐ The question your auditor asks, which the model could not answer until this month

*Did anybody look for the double counting?*

Without a wrapper the answer is unfileable. A fusion checked and found clean and a fusion nobody
examined produce **the same bytes** — an empty list of eliminations. Which makes the
reconciliation `Σ parts − eliminations = consolidated` **exact for the fusions that file one and
a shrug for the fusions that file none**, with nothing in the document saying which you are
reading.

```
eliminations absent none          checked, clean   -> Σ parts must equal the consolidated figure
eliminations absent unmeasured    NOT CHECKED      -> no equality owed; report UNCHECKED
eliminations absent notApplicable one part         -> nothing to count twice
```

**Three verdicts, not two.** A checker has to be able to say *unchecked*, because reporting a
pass on a reconciliation nobody performed is the same failure as reporting a pass on a rule that
examined no rows. → **[§8](#8-the-zero-that-turned-out-to-be-two)**

### Where an accountant's instinct is wrong, and it is worth ten minutes

Everything above is arithmetic you already trust. This is the one place the ordinary habit breaks,
and it breaks quietly.

**Netting two ranges does not net componentwise.** Given a committed capacity of `[9, 10, 11]` and
a demand of `[8, 12, 15]`, the shortfall is *not* `[9−8, 10−12, 11−15]`. The **worst case of a
difference pairs one side's worst against the other's best**: least capacity against most demand.

```
best case    11 − 8   =   3 spare
worst case    9 − 15  =  -6 short      <- NOT 11 − 15
```

Do it componentwise and the low bound pairs the good week's capacity with the good week's
demand, which is a scenario that describes **one week twice** and understates the downside by the
full width of both ranges. It is the same error as translating a range at the best-case rate and
the worst-case volume together. → **the full argument, and where it bites again in a
consolidation, is [`r = n − d` reverses its bounds](#r--n--d-reverses-its-bounds).**

**And the same trap has a translation form.** One FX or unit factor multiplies *both* the
capacity and the demand of the part it converts, so the two converted figures are **correlated**,
and differencing them counts the factor's spread twice. This is not hypothetical: the corpus has a
consolidation where re-deriving a remainder from converted figures gives `[1092, 2857, 4198.8]`
against a filed `[1414, 2857, 4085.6]` — **identical at the mode, wrong at both bounds.** →
**[§4](#4-φ-correlated-with-itself)**

### ⭐⭐⭐ And the reason any of this is being written down

**The remainder is off balance sheet by construction, and both regimes say so in the same words.**

An evening a salaried engineer absorbs has no counterparty and therefore no transaction. There is
nothing to recognise, no measurement basis to apply, no position to code — and asked where it
sits, US GAAP and NCRF-PE **both return `not-a-financial-fact` from the same coding pack.**

That is the correct answer and this model does not dispute it. What it says is that *the
quantity still exists and somebody still bore it*, so it needs a home that is not the ledger. The
whole apparatus above — the buffers, the holders, the typed absences — is the shape of that home,
and the accounting refusal is the evidence it is needed rather than an argument against it.

**The one thing that would refute this section**: a framework that DOES code it. If your
regime has a position for absorbed capacity with no counterparty, that is the most valuable thing
you can send back, and [`assets/corpus/coverage-us-gaap.xml`](../corpus/coverage-us-gaap.xml)
shows the shape a reply takes — including `exception`, which is how a witness disagrees with the
corpus **on purpose** rather than looking like a bug somebody stopped chasing.

---

## From the linear-algebra side

**[The financial section](#from-the-financial-side) is the same subject with the notation taken
off**, and it is not a simplification: `FΦx − e` there and `FΦx − e` here are one expression. What
this section adds is the part a consolidation does not have to think about, because a ledger holds
numbers and this model holds **ranges** — and a range subtracts, converts and composes by rules
that are not the ones a number obeys.

Read as linear algebra, a filing declares these.

| | shape | an entry is | the relation | run it |
|---|---|---|---|---|
| `d` | L | a layer's demand | `layers/demand.sqlc` | `layers.demand` |
| `n` | L | a layer's committed nameplate | `layers/nameplate.sqlc` | `layers.nameplate` |
| `q` | L | a lumpy layer's quantum | `layers/lumpy.sqlc` | `layers.lumpy` |
| `r = n − d` | L | the remainder, and the whole subject | `layers/remainder.sqlc` | `layers.remainder` |
| `D` | P×L | what operation *p* draws from layer *l*, now | `entries/draws.sqlc` | `entries.draws` |
| `N` | P×L | what operation *p* commits on layer *l*, later | `entries/inductions.sqlc` | `entries.inductions` |
| `C` | L×L | an **observed** dependence between two remainders | `entries/couplings.sqlc` | `entries.couplings` |
| `H` | L×5 | who bears layer *l*'s remainder, and how much | `entries/holders.sqlc` | `entries.holders` |
| `S` | L×3 | how much each of the three buffers holds | `entries/slacks.sqlc` | `entries.slacks` |
| `F` | L×L | which layer of another filing composes into which layer of this one | `composition/parts.sqlc` | `composition.parts` |
| `Φ` | a weight on each entry of `F` | the factor converting that part into the composed unit | `composition/converted.sqlc` | `composition.converted` |
| `e` | L | quantities double-counted across parts, subtracted once | `eliminations/filed.sqlc` | `eliminations.filed` |

⭐ **The last two columns are the way in.** Every symbol is a file you can read and a relation you
can query: `psql -c 'SELECT * FROM layers.remainder'` after the load, or
`assets/sql/layers/remainder.sql` to run the same rows with nothing loaded but the schema. The
notation is not a description of the model written elsewhere; it is an index of it.

Three things in that table do not behave the way the notation suggests, and each has its own
subsection below: the product `DᵀN`, which is two rows rather than one; the difference `r = n − d`;
and `Φ`.

### `DᵀN` composes, but its quantities do not

`DᵀN` is the obvious way to collect cross-layer structure, and the query computes it in eight
lines. Then read the unit column: `people * launches`. Each layer carries its own unit, so the
product is not a rate of anything. **The incidence composes and gives you reachability; the
quantities do not.** There is also no firing count per operation, deliberately, because sequence
and timing are BPMN's job. → **and in this corpus it is empty: [§2](#2-dᵀn-the-good-zero)**

### `r = n − d` reverses its bounds

Subtracting intervals crosses the subscripts: the **low** of `n − d` pairs `n`'s low with `d`'s
**high**. Get it backwards and every remainder comes out inside out. The query writes the
crossing visibly:

```sql
n.amount_low  - l.demand_high AS r_low,
n.amount_high - l.demand_low  AS r_high
```

Then it recomputes the fit from those bounds and compares against what the document filed.
**Thirty-two layers, thirty-two agreements.** That is ISO 286's own criterion — a fit compares
two *ranges*, not two points — and XSD cannot state it in any form.
→ **checked independently in [§1](#1-the-fit-recomputed-from-the-ranges)**

### `Φ` is correlated with itself, and the corpus proves it

The one worth the whole exercise. A conversion factor multiplies **both** the nameplate and the
demand of the same part, so the two converted intervals move together. Difference them as though
they were independent and `Φ`'s spread gets counted twice:

```
converted directly, as filed          1414.0   2857.0   4085.6
re-derived from the composed totals   1092.0   2857.0   4198.8
```

They agree at the mode and nowhere else, because the mode is the one point where `Φ` is a single
number with no spread to double. **Both figures are arithmetically correct. Only the first is the
remainder.** → **checked in [§4](#4-φ-correlated-with-itself)**

### And the fusion rule checks out

`x_composed = F Φ x_parts − e`, over every composed layer quantity that owes the equality, exact
on all three bounds. `cargo run --example matrices` §3 prints how many that is, per quantity,
beside how many are suspended; `composition/owed_equality.sqlc` is the population.

The eliminations are the term that gets dropped, and on one layer that is 90 GPU-hours of
demand counted in two members' filings at once. Nothing warns you — the totals come out
plausible and wrong.
→ **as a real matrix product in [§3](#3-fφx--e-as-an-actual-matrix-product)**

---

## What the queries can and cannot say

`rules.sql` prints three KINDS of table, and the difference between the kinds is most of the
design.

**1. Violations.** Rows that fail a rule. Empty is the good outcome.

**2. Referrals.** **Not violations, and not passes.** Things a query can *find* and only a
person can *settle*. A coupling whose two ends fuse into one layer one level up is absorbed by
that fusion, and the fusion owes a sentence saying so — detecting the structure is mechanical,
judging whether the sentence exists and means it is not. **A clean run has rows here and that is
correct**, which is why they are not mixed in above:

```
merge-group-composition    compute-us -> compute-pt   merge-holding-composition/compute
merge-group-composition    labour -> on-call          merge-holding-composition/staff
merge-group-composition    labour -> shift-line       (no fusion holds both ends)
merge-holding-composition  staff -> shift-line        (no fusion holds both ends)
refutation                 compute -> labour          (no fusion holds both ends)
```

The three unabsorbed rows are there on purpose. A referral that printed only its findings
would be as unreadable as a rule that printed only its violations: *five couplings examined
and two absorbed* is a statement; two rows is not.

⭐⭐ **Also reported here: the other claim a document can refute in this format.** The model says
every layer has a remainder, and `StatedRemainder` is a choice — a remainder, or a typed reason
there is none — so a sender who disagrees has to say so rather than leave a field empty. Two
corpus layers do, and both argue the same thing in different words: a supply with no quantum
divides exactly, so nothing is left over. Read it beside the independence report; they are the
model's two falsifiers and each has a wrapper built to carry the refusal.

Also reported here: `narrowsWhen` coverage. The annotation says *"a claim without it is
weaker, and a receiver is entitled to say so"* — so the receiver says it with a number.
**20 of 26 ranged demands (77%) decline to say what would tighten them.** Judging whether a
given sentence would *actually* narrow the range is prose. Counting which claims decline to
offer one is not.

**3. Coverage**, and this one matters more than the first:

```
psql -d process_modulus_proof -f assets/sql/reports/coverage.sql
```

One row per rule, ordered by how much it examined: the size of the population it looked at,
how many of those breached it, and a verdict on the count itself. `ok`; `⚠️  thin`, where one
or two rows is a demonstration rather than evidence; and `⛔ VACUOUS`, where the rule examined
nothing whatever.

**A VACUOUS row is the machinery working**, not a defect in it. The rule is written and it is
wired in, and this corpus holds nothing for it to look at, so it proves nothing here and says
so. A rule reported as `ok` when it examined nothing is the dangerous zero; a rule reported as
VACUOUS is a rule you can trust the rest of the report about.

⛔⛔ **And that row is the one a checker structurally cannot produce, which is why the
rules are built the way they are.** Group a filtered population by rule and a rule with an
empty population contributes no row at all — so the single most important verdict this report
can return would be delivered by *silence*, which is indistinguishable from the rule not
existing. Every check therefore joins `checks/roster.sqlc` first, where each rule's sentence is
written exactly once; the roster row exists before the population does. `examined` is then a
count of what the rule looked at, `violations` a count of what failed, and the violations table
and this report are `WHERE violates` and `GROUP BY rule` over one relation — which cannot
disagree about what was examined. The previous version restated each population in a second dialect of itself, and
**three of the twenty-two restatements disagreed with the rule they reported on** — one loudly
enough to call a rule that examines a single row `ok`.

⭐⭐ **None of those rows is a new idea, and several are reachable only because the state they
turn on has a name.** Where a state is a blank — an empty list, a missing element, an omitted
enumeration — there is no reason to group by, and the rule stays prose however plainly it is
written. *A window is carried through a fusion and never summed* is the sharpest: a composed
layer that drops its part's duty cycle is byte-identical to a line that runs seven days a
week. → **[§8](#8-the-zero-that-turned-out-to-be-two)**

The thin ones are thin for the same reason the Rust tests are: almost nothing in the corpus
files a numeric slack, only three filings state any coupling at all, and exactly two layers
deny having a remainder.

⭐⭐ **That last one is the model's own falsifier, and an ingest that reads one branch throws it
away.** `StatedRemainder` is a choice, a remainder or a typed reason there is none, and every
layer is required to carry one *precisely* so that a sender who disagrees with "every layer has
a remainder" must say so explicitly. Read only the first branch and the layers taking the second
arrive as five NULLs, indistinguishable from documents that said nothing. One of
them says otherwise in its own note: *"filed as a counter-example to the claim that every layer
carries a remainder, **not as a gap in this document**."* A gap is exactly what was stored.

### Couplings, and the three shapes they come in

`C` is the model's own falsifier — the stack is *assumed* to be independent layers, so every
non-zero entry is somebody reporting that the assumption failed. Five couplings, three shapes,
and each shape is checkable differently:

| shape | corpus | what can be checked |
|---|---|---|
| a plain sized coupling in a flat filing | `refutation compute→labour` | that it carries its observation at all |
| **propagating through a fusion** | `group labour→shift-line` becomes `holding staff→shift-line` | **that it ATTENUATED** |
| **absorbed by a fusion above** | `group compute-us→compute-pt`, `group labour→on-call` | which ones — then a person |

⭐⭐ The middle one is the good check, because the ceiling comes from two *other* documents. If
`labour` is coupled to `shift-line`, and `labour` is fused into `staff` one level up, the
coupling survives but weakens: the composed layer is only partly `labour`, so at most `labour`'s
share of it can move.

```
labour's share of staff   [0.819, 0.804, 0.793]
group coupling x share    [0.082, 0.177, 0.277]   <- the ceiling
holding coupling filed    [0.06,  0.15,  0.26 ]   OK at all three bounds
```

Nothing in either filing states that ceiling. It is a join across a composition, a fusion and
two layers' demands, and a filer could have put any number there.

### The rules were checked by breaking things

Four edits inside a rolled-back transaction — a fit put back to the two-member reading, a holder
deleted, a share inflated, a part pointed at a second parent — produced **six** violations,
because breaking the share sum also broke the slack bound. **The rules are not independent of
each other**, which is worth knowing before trusting a single green run.

### Where a query language stops

Not everything. No join can check that an `observation` on a coupling describes a real
observation, that a `narrowsWhen` names something that would actually narrow the range, or that a
note saying *"the portion that ages out is `unrealised`"* agrees with the holder list beside it.
Those are prose against data.

What it can do is the whole cross-element and cross-document half of the model, which is the
half XSD 1.0 gave up on. That half turns out to be most of it.

### And where a picture starts, which is where the danger moves

`assets/sqlc/diagrams/` renders the model into BPMN 2.0, one document per filing, plus an SVG of
each. Three programs do it and none of them decides anything: `examples/diagramming/main.rs` emits the
filings, `examples/graphs/main.rs` emits the model's own graphs as the lane sets of one pool, and
`examples/rendering/main.rs` draws what the BPMN says while reading no model at all.

⛔⛔ **The reader of a diagram is the RDBMS of this pipeline.** Postgres executes a broken
difference and returns a plausible table; a brilliant analyst reads a well-formed diagram, reaches
a confident conclusion, and does not come back to tell you it was wrong. A wrong table gets
re-checked. A wrong diagram gets quoted. Every relation below exists because of that one
asymmetry.

| what you want to know | where it is decided |
|---|---|
| what a correct translation OWES, as cardinality identities | [`diagrams/roster.sqlc`](diagrams/roster.sqlc) |
| what each `pm.*` table renders as, or the typed reason there is none | [`diagrams/domain_objects.sqlc`](diagrams/domain_objects.sqlc) |
| which of BPMN's glyphs are spent, and why each of the rest is withheld | [`diagrams/notation.sqlc`](diagrams/notation.sqlc) |
| what a document owes on its own FACE, where the default reading is wrong | [`diagrams/legends.sqlc`](diagrams/legends.sqlc) |
| what states each sentence the artifact carries | [`diagrams/annotated.sqlc`](diagrams/annotated.sqlc) |

⭐⭐⭐ **The last row is the one this section is really about, and it is not a count.** Every law
on the roster asks how many of an element the artifact carries, and a sentence is not that kind of
fact: a document can carry exactly the right number of `documentation` elements and have each of
them say something no relation states, with the count exact the whole way. So every sentence names
the relation that states it, the way a generated `.sql` file names its template on one `--` line,
and `examples/diagramming/main.rs` reads them back out of the files afterwards. A sentence with no
source, a source that is not a relation in this tree, and a source the emitter never queried each
fail the run.

⚠️ And the pointer is drawn as well as filed. A `documentation` element is read by a tool that
could have opened the database anyway; a `textAnnotation` is read by a person holding a picture,
who has no other route back.

---

# Digging in: the second witness

Everything above is one witness. `matrices.sql` computes a number and this document says *look,
it is right.* That is an author asserting.

⭐⭐ `examples/matrices/main.rs` pulls the same rows out and computes with `nalgebra`, where a matrix
product is a matrix product, then asserts the two agree. This repository's own standard,
[`tests/independence.rs`](../../tests/independence.rs), says corroboration between two things
sharing a code path is worth nothing — so the SQL does its sums as `GROUP BY` and the Rust does
them as `gemm`, and agreement means the claim was checked rather than stated.

The two share the ingest, and that is fine: the ingest is not what is being proved. The
arithmetic on top of it is.

**There is no silent skip.** No `DATABASE_URL` means the example fails to run. A proof that
passes without executing is the dangerous zero.

⚠️ **The blocks below are a transcript of one run, kept to show the SHAPE of the output.** They are
not the authority for any number in them, and three of them were materially stale before anybody
re-ran the program. `cargo run --example matrices` is the authority; read the figures there.

### 1. The fit, recomputed from the ranges

Builds `d` and `n` as three `DVector`s each — low, mode, high — and does the crossed subtraction
as vector arithmetic, one line per bound. Then classifies each layer by ISO 286's criterion and
compares to the filed `sign`.

```
1. fits recomputed from the ranges: 57 of 61 layers, 0 disagreements
   ⛔ 4 layer(s) excluded: their parts convert through a factor with width, so n and d are
   correlated and the difference is a bound rather than the remainder.
   composition/fused_remainders.sqlc carries theirs.
   observation  26 layers: 11 clearance, 14 interference, 1 transition
   stipulation  35 layers: 26 clearance, 1 interference, 8 transition
```

⭐⭐ **The census is split by `evidence` and the split is the content.** The stipulations were
written to exercise the states real filings almost never reach, `transition` above all, so a
pooled count hands the corpus's transitions the fixtures' weight and reports a stipulation as
evidence.

It asserts a floor before it asserts anything about the answers, so the check cannot pass by
examining nothing — and the floor is on the CORPUS alone, not on every row in the census.
Counting the fixtures would let them hold the assertion up while the corpus emptied underneath
it, which is the vacuity trap one level out: plenty to check, none of it the thing being
claimed. ↑ *the claim this settles is [`r = n − d` reverses its
bounds](#r--n--d-reverses-its-bounds).*

### 2. `DᵀN`, the good zero

```
2. D-transpose N: 2 operation(s) both draw and induce, 0 with both stated
   'Close an enterprise contract' draws on `labour` and commits `capability`,
      and THE DRAW IS UNMEASURED, so the product is empty.
```

The product is not computed because it cannot be. **The section reports why rather than
printing an empty matrix**, because the reason is the finding: the one cross-layer entry this
corpus could have had is missing for exactly the reason the model exists.
↑ *settles [`DᵀN` composes, but its quantities do not](#dᵀn-composes-but-its-quantities-do-not).*

### 3. `FΦx − e`, as an actual matrix product

`F` is built as a dense incidence matrix — 1 where a part composes into a layer — and `Φ` as a
diagonal, which is available because no part layer in this corpus is used twice with two different
factors. The model permits that, and the factor is filed per edge of `F` rather than per layer, so
a corpus that exercised it would need the weights on the entries instead. Then the fusion is three
real matrix products, one per bound, and each result is compared against the figure the composed
layer filed, once per quantity: demand, nameplate and draw each get their own `F`, because a layer
that files one and not another is in the incidence for one and not the other.

```
3. F.Phi.x - e against the filed composed figures, per quantity:
   demand     F is 24x37, the relation stores 37 of 888: 20 layers agree, 4 suspended
   draw       F is 13x16, the relation stores 16 of 208: 11 layers agree, 2 suspended
   nameplate  F is 24x37, the relation stores 37 of 888: 20 layers agree, 4 suspended
   the matrix product equals the SQL's join and GROUP BY on 51 sums;
   51 layer quantities agree with their filings, 10 suspended
```

⭐⭐ **This is where "a matrix product is a join with a `GROUP BY`" gets checked.**
`matrices.sql` computes the same rows with a join and a sum. Same answer, two algorithms.
↑ *settles [the one idea](#the-one-idea-both-algebras-share), [the fusion
rule](#and-the-fusion-rule-checks-out), and the claim that **a consolidation IS this
expression** — [from the financial side](#from-the-financial-side).*

### 4. `Φ`, correlated with itself

```
4. Phi: filed [1414, 2857, 4085.6] vs re-derived [1092, 2857, 4198.8]
   Equal at the mode, apart at both bounds, by 322.0 and 113.2.
```

**A threshold like `> 1.0` cannot carry this assertion**, because it cannot tell a small real
disagreement from *no* disagreement. No disagreement would mean `Φ` has no spread,
which would make the whole section vacuous while still printing green. It is now two assertions:
first that some factor actually spreads, then that the bounds differ at all.
↑ *settles [`Φ` is correlated with itself](#φ-is-correlated-with-itself-and-the-corpus-proves-it)
and the translation trap in [where an accountant's instinct is
wrong](#where-an-accountants-instinct-is-wrong-and-it-is-worth-ten-minutes).*

### 5. What densifying costs

The one section where the matrix form **loses**, kept at the end because it is more useful than
a victory lap.

```
5. C densified to 8x8: 3 filings state a coupling, 0 assert independence, 5 say nothing
   In `values` all 64 entries are 0.0 and indistinguishable.
```

A filing where nobody looked and a filing where somebody looked and found nothing become the same
number the instant you allocate the matrix. The example carries a `present` mask beside the
values, which is the only thing keeping them apart — **and nothing in a matrix requires anyone to
carry one.**

⭐⭐ **AND THE MASK NEEDED A THIRD VALUE, WHICH IS THE SAME ARGUMENT ONE TURN DEEPER.** A bit
distinguishes *stated* from *blank.* It cannot distinguish TESTED-AND-ZERO from NOBODY-LOOKED —
and those are opposite verdicts on the model itself. The mask is `0 | 1 | 2` now, and the
count printed beside it is the one number in this file most worth reading.

That is why the tables are sparse rather than dense, and it is the bad zero in one screen.
↑ *settles [why the tables are shaped as they are](#why-the-tables-are-shaped-as-they-are) and
[§8](#8-the-zero-that-turned-out-to-be-two).*

### 6. The residue census, and why the figure is counted by a program

`r = mq − (d mod q)` splits a remainder into the half a procurement decision moves and the half
no decision removes. The second half is a **sawtooth** in `d`, so at an interval's three points it
need not come back ordered — and an unordered triple is not an interval at all, while the demand
it was computed from is perfectly well formed.

```
6. residue census: 25 lumpy corpus layers, 17 cross a tooth, 15 of them sawtoothed,
   0 disagreements
```

Postgres computes the verdict with `mod()`; the example recomputes it with `%`. The disagreement
count is the second witness, and it is the same standard the rest of this file runs on.

⚠️ The section also asserts every filed quantum is a POINT VALUE. A quantum with a spread makes
`d mod q` three different divisions and the query divides by the mode — currently free, since no
corpus quantum has a range, and still an assumption. Asserted rather than assumed, so it stops
being free out loud.

⭐⭐ **Bounded at both ends, because both vacuous extremes are reachable and neither is
interesting.** All-clean would mean the corpus files only demands sitting on the lattice;
all-sawtoothed would mean the ordered case is unexercised. The claim is that an unordered residue
is ORDINARY rather than universal, and that needs both to occur.

⛔ This figure is quoted nowhere in prose, deliberately: `examples/matrices/main.rs` §6 prints it on
every run. Maintained by reading the XML and counting instead, it is a number nobody recounts.
↑ *settles the sawtooth half of [`r = n − d` reverses its
bounds](#r--n--d-reverses-its-bounds).*

### 7. Slack coverage, and the column that reads zero

One row per (layer, buffer): whether that buffer was sized, or which typed absence stands there
instead.

```
7. slack coverage (corpus): 84 (layer, buffer) rows
   capacity   13 sized of 28
   inventory  20 sized of 28
   time       13 sized of 28
```

⛔⛔ **The interesting rows are the sized ones, and they are not all zero.** `capacity` carries
the shortfall inequality: what a filing's own demand and nameplate say could have gone unserved,
against what the supply can absorb plus what the document admits turning away. Most of the sized
rows sit at `[0, 0, 0]`, which is a filer saying the supply cannot be run hot at any price, and
**that is the tightest possible bound rather than a missing one**. A minority state a real width,
and `enterprise-contract/support-cover` is the one to read: it sizes its capacity slack at
`[0, 16, 40]` engineer-hours per week, filed the same way in the Portuguese twin. The rest of the
column is `unmeasured`, which is a third state again.

⚠️ **A sentence about this column rots whenever the spelling of a zero moves, and it has, twice.**
File the zeroes as `absent/reason = none` and they count as absences; narrow the wrapper so a
measured zero becomes a claim and the column moves under any prose that named a figure. So print
it: `cargo run --example matrices` §7 is the census, and `reports/slack_census.sqlc` is the
relation behind it.

⛔ **And a stated width is not the same as an exercised inequality, which is the part worth
separating.** `checks/share_exceeds_slack` still reads ⛔ VACUOUS on this corpus, and not for want
of a number to bind against: every layer that sizes its absorbing buffer under an `interference`
fit is then removed because every holder on it is `customer` or `unrealised`, so nothing was
absorbed at all and the demand was turned away. `entries/borne.sqlc` argues it and
`algebra/borne.sqlc` holds `Σall = Σkept + Σremoved` per layer so the vacuum is arithmetic rather
than a claim in a comment.

**Nothing asserts it stays zero**, and that is deliberate. An equality here would make the first
filer to size a capacity slack break the build for doing exactly what the model wants. The zero is
REPORTED, and the assertion sits one level out: that *some* slack somewhere carries a number, so
the share-sum rule is not passing against an empty table.
↑ *settles [why the tables are shaped as they
are](#why-the-tables-are-shaped-as-they-are).*

### 8. The zero that turned out to be two

Not a section of the example — a section of `rules.sql`, and the reason the previous five got
sharper. Five encodings in the two schemas held a three- or four-valued fact in two states, and
every one of them survived review **because both of its values were correct.** Nothing in a
boolean, or in an empty list, points at what it cannot say.

| what is two-valued | the value with no encoding |
|---|---|
| `Stack/coupling`, an unbounded element | ⭐⭐ *somebody looked and the layers are independent* |
| `Fusion/elimination`, an unbounded element | *the composer checked and the parts do not double count* |
| `Divisibility/window`, optional | *the unit has no denominator, so the question is malformed* |
| `Claim/boundOrigin`, optional | *nothing sets this bound — the range is where the measurements fell* |
| `CoverageEntry/complete`, the only `xs:boolean` | *the witness answers PART of the question* |

```
⛔⛔⛔ HAS ANYBODY TESTED THE MODEL?      -- assets/sql/reports/independence_tested.sql
+----------------------------------------------+--------+
| the_independence_assumption                  | stacks |
+----------------------------------------------+--------+
| NOBODY LOOKED                                |      4 |
| somebody looked and the layers MOVE TOGETHER |      3 |
| one layer; no pair to couple                 |      1 |
+----------------------------------------------+--------+
```

⛔⛔ **Read the row that is not there.** No stack in this corpus asserts independence. The
model's central claim — that a layer is a place where a remainder is held *independently of every
other layer's* — has never been tested by any filing here, and has once been contradicted. That is
a fact about the EVIDENCE rather than about any one document, and it is reachable only because an
empty list is not an answer here.

**The same shape one document up, and here the answer changes the arithmetic.** A fusion that
files `eliminations` as `none` or `notApplicable` owes an EXACT sum — the composed figure equals
`Σ` converted parts, full stop. One that files `unmeasured` owes nothing and the check is
suspended. An empty list quietly bought the first reading for every composer who had earned the
second, which is the sum rule `Elimination` exists to make exact, silently back to a warning.

**And requiring `boundOrigin` produced a result nobody was looking for.**

```
                                                       -- assets/sql/reports/bound_ownership.sql
| who_owns_the_edge                                           | claims |
+-------------------------------------------------------------+--------+
| NOTHING sets it -- the range is where the measurements fell |     59 |
| stated in a sibling element (amountOrigin, quantum origin)  |     56 |
| somebody owns it: intrinsic                                 |     32 |
| not a bound on a committed quantity                         |     22 |
| somebody owns it: contractual                               |     13 |
| nobody has asked                                            |      3 |
| somebody owns it: policy                                    |      1 |
```

Roughly a third of the corpus answers `derived`, meaning **the model already states the author of
that edge in a sibling element.** `Nameplate/amountOrigin` and `LumpyQuantum/origin` do that job
for the nameplate half of every filing, and an optional `boundOrigin` three lines away sits blank
— required and wrapped in one case, optional and silent in the other, in the same sequence.
↑ *settles [why the tables are shaped as they are](#why-the-tables-are-shaped-as-they-are).*
