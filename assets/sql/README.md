# The same model, twice: as tables and as matrices

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

Five files and one claim.

```
schema.ddl            the model as relations
ingest.sql            Postgres reading assets/corpus/*.xml itself, with no help
matrices.sql          the matrices, pulled out with joins
rules.sql             the rules XSD 1.0 cannot reach, as one query
../../examples/matrices.rs   the same arithmetic again, in nalgebra, asserting agreement
```

**The claim:** forty-four rules in this model are written in the schemas' prose and checked by
nothing, because XSD 1.0 has no `xs:assert` and cannot compare one element against another.
Look at what those rules actually say. *The shares sum to the magnitude. The sign agrees with
the range comparison. No leaf is reachable by two paths.* Those are joins and sums and
comparisons — impossible in a grammar, ordinary in a query language.

**What this is not.** It is not a recommended database schema. Nothing here is normalised
for writing, indexed for a workload, or shaped for an application. Copy the ideas, not the
layout.

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
psql -d process_modulus_proof -f assets/sql/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

Run it from the repository root — `ingest.sql` reads `assets/corpus/*.xml` from the client
side, so paths are relative to wherever you started `psql`.

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
| **the same zero, twice** | one fact with two spellings | `absent reason="none"` vs a claim of `[0,0,0]` |
| **the boundary zero** | a comparison landing exactly on the line | `n_low = d_high` — a chosen convention |
| **the zero that should NOT be zero** | a table whose emptiness would mean nobody looked | the referrals below |
| **the zero that is now two zeros** | a blank that carried "checked and found nothing" and "nobody checked" at once | `coupling_search`, `elimination_search` — [§6](#6-the-zero-that-turned-out-to-be-two) |

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
| **union** (∪) | the rows of either | how `rules.sql` folds sixteen checks into one answer |
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
**[§6](#6-the-zero-that-turned-out-to-be-two)**

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
| translation, restatement, unit conversion | a **diagonal** scale, `Φ` | `Part/factor` |
| elimination entries | a vector subtraction, `e` | `Elimination`, one row per quantity |
| the consolidated column | `FΦx − e` | the composed layer's own claim |

**That is the entire consolidation, written once.** `FΦx − e` — take the members, put them in one
unit, add them along the ownership incidence, subtract what was counted twice. → **and it is
checked against the filings in [§3](#3-fφx--e-as-an-actual-matrix-product), eight layers, to the
digit.**

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

### ⭐⭐ The question your auditor asks, which the model could not answer until this month

*Did anybody look for the double counting?*

For two revisions the answer was unfileable. A fusion that had been checked and found clean and a
fusion nobody had examined produced **the same bytes** — an empty list of eliminations. Which
means the reconciliation `Σ parts − eliminations = consolidated` was **exact for the fusions that
filed one and a shrug for the fusions that filed none**, and nothing in the document said which
you were reading.

```
eliminations absent none          checked, clean   -> Σ parts must equal the consolidated figure
eliminations absent unmeasured    NOT CHECKED      -> no equality owed; report UNCHECKED
eliminations absent notApplicable one part         -> nothing to count twice
```

**Three verdicts, not two.** A checker has to be able to say *unchecked*, because reporting a
pass on a reconciliation nobody performed is the same failure as reporting a pass on a rule that
examined no rows. → **[§6](#6-the-zero-that-turned-out-to-be-two)**

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

| | shape | an entry is |
|---|---|---|
| `d`, `n`, `q` | L | a layer's demand, committed nameplate, quantum |
| `r = n − d` | L | the remainder, and the whole subject |
| `D` | P×L | what operation *p* draws from layer *l*, now |
| `N` | P×L | what operation *p* commits on layer *l*, later |
| `C` | L×L | an **observed** dependence between two remainders |
| `H` | L×5 | who bears layer *l*'s remainder, and how much |
| `S` | L×3 | how much each of the three buffers holds |
| `F` | L×P | which part filings compose into which layer |
| `Φ` | diag | the factor converting each part into the composed unit |
| `e` | L | quantities double-counted across parts, subtracted once |

Three of them are not what they look like.

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
**Twenty-one layers, twenty-one agreements.** That is ISO 286's own criterion — a fit compares
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

`x_composed = F Φ x_parts − e`, over eight composed layers, exact on all three bounds.

It was wrong the first time it ran, because I forgot `e`. The eliminations are the term you
drop, and on one layer that is 90 GPU-hours of demand counted in two members' filings at once.
Nothing warns you — the totals come out plausible and wrong.
→ **as a real matrix product in [§3](#3-fφx--e-as-an-actual-matrix-product)**

---

## What building this found

Three things, none visible from the XSD or from the Rust.

### The absorber is a borrowed term, and my first DDL forked it

I declared `absorber buffer` as an enum with three values. The corpus refused to load:

```
ERROR:  invalid input value for enum buffer: "capacidade"
```

The Portuguese filing cites a **translated edition** of *Factory Physics*; its absorber is
`capacidade`. That filing is correct. My enum was the fork, and the README says so in as many
words: *"a restated value set is a fork, and a fork drifts with nothing here able to notice that
it has."* So the value travels with the authority that defines it, and deciding `capacidade`
means the same buffer as `capacity` is a step a **reader** takes on purpose — `buffer_term` holds
that judgement in the open.

It happened twice more. A `boolean NOT NULL` for lumpy-or-continuous met a document that files
divisibility as a typed absence: three states, two-valued column. **Every time a column here had
fewer states than the fact it held, the corpus found it on the first run.**

### One fact, two spellings, and a rule that saw one of them

The idiom for a measured zero is `absent reason="none"` — *"somebody looked and it is zero."*
Nothing forbids stating it as a claim of `[0, 0, 0]`, which asserts the same thing. The presence
and exposure rules keyed on the absence alone, so a filer choosing the other spelling was
**silently skipped by both** — and a rule that skips is indistinguishable from one that passes.

Both spellings are accepted now, and a twelfth check reports the ambiguity itself, because a
receiver comparing two filings cannot treat the two forms as one field. Reported, not
legislated: the schema does not state it as a rule and whether it should is a live question.

### Nothing in the corpus says which document a part reference points at

A composition names its parts by a notation and an id — `urn:example:filing:us-member:2026-08-31`
/ `compute`. **No document declares its own notation.** `Composition` carries witness, observedAt,
provenance, regime, citation and fusion, and nothing saying *"I am that URN."* Neither does
`pm:processModulus`.

So a part reference cannot be resolved from the corpus at all, and the conformance rule that says
*"a dependence end's filing exists, and the layer named is in it"* assumes a lookup the model does
not provide. `ingest.sql` fills `filing_identity` from **filenames**, which is a guess, written
down as one.

Writing a foreign key found it. A key needs something to point at, and there was nothing there.

---

## What the queries can and cannot say

`rules.sql` prints three tables, and the difference between them is most of the design.

**1. Violations.** Rows that fail a rule. Empty is the good outcome.

**2. Referrals.** **Not violations, and not passes.** Things a query can *find* and only a
person can *settle*. A coupling whose two ends fuse into one layer one level up is absorbed by
that fusion, and the fusion owes a sentence saying so — detecting the structure is mechanical,
judging whether the sentence exists and means it is not. **A clean run has rows here and that is
correct**, which is why they are not mixed in above:

```
a fusion absorbing a coupling between its own parts must say so
  merge-group-composition  compute-us -> compute-pt   into merge-holding-composition/compute
  merge-group-composition  labour -> on-call          into merge-holding-composition/staff
```

Also reported here: `narrowsWhen` coverage. The annotation says *"a claim without it is
weaker, and a receiver is entitled to say so"* — so the receiver says it with a number.
**18 of 23 ranged demands (78%) decline to say what would tighten them.** Judging whether a
given sentence would *actually* narrow the range is prose. Counting which claims decline to
offer one is not.

**3. Coverage**, and this one matters more than the first:

```
a ranged claim does not file narrowsWhen as notApplicable            23   ok
sign agrees with the range comparison                                21   ok
a quantum is expressed in the unit of the nameplate it divides       20   ok
the nameplate is a whole multiple of the quantum                     20   ok
stated shares sum to the magnitude                                   18   ok
a window is notApplicable only where the unit has no denominator     14   ok
a part reference resolves to a filing that is here                   12   ok
a clearance fit rules out customer and unrealised                     8   ok
no leaf layer is reachable through two paths                          7   ok
a fusion absorbing a coupling between its own parts must say so       5   ok
a coupling attenuates through a fusion, bounded by the part's share   4   ok
a slack is expressed in the unit of the shares it bounds              4   ok
a fusion calls double counting malformed only when it has one part    3   ok
a window is carried through a fusion and never summed                 3   ok
a measured zero is filed as an absence, not a claim of zero           2   thin
a share does not exceed the slack of the buffer that absorbed it      2   thin
a supply that cannot run hot names who went unserved                  2   thin
exposure does not exceed slack plus unserved shares                   2   thin
a derived time slack needs a window that permits the derivation       0   VACUOUS
a point value files narrowsWhen as notApplicable, having no range     0   VACUOUS
```

**The last two lines are the machinery working**, not a defect in it. Each catches a real
mistake — a point value has no range to tighten, so `narrowsWhen` on one is a paste or a claim
filed at the wrong width — and this corpus contains none, so they prove nothing here and say so.
A rule reported as `ok` when it examined nothing is the dangerous zero; a rule reported as
VACUOUS is a rule you can trust the rest of the table about.

⭐⭐ **Four of these rows are new and none of them is a new idea.** Each was already written down
in the schemas' prose and was UNCHECKABLE, because in each case the state it turns on was a blank
— an empty list, a missing element, an omitted enumeration — and a blank has no reason to group
by. *A window is carried through a fusion and never summed* is the sharpest: it caught a live
defect on its first run, a composed layer that had dropped its part's duty cycle where the drop
was byte-identical to a line that runs seven days a week. → **[§6](#6-the-zero-that-turned-out-to-be-two)**

Four more are thin for the same reason the Rust tests are: almost nothing in the corpus files a
numeric slack.

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

---

# Digging in: the second witness

Everything above is one witness. `matrices.sql` computes a number and this document says *look,
it is right.* That is an author asserting.

⭐⭐ `examples/matrices.rs` pulls the same rows out and computes with `nalgebra`, where a matrix
product is a matrix product, then asserts the two agree. This repository's own standard,
[`tests/independence.rs`](../../tests/independence.rs), says corroboration between two things
sharing a code path is worth nothing — so the SQL does its sums as `GROUP BY` and the Rust does
them as `gemm`, and agreement means the claim was checked rather than stated.

The two share the ingest, and that is fine: the ingest is not what is being proved. The
arithmetic on top of it is.

**There is no silent skip.** No `DATABASE_URL` means the example fails to run. A proof that
passes without executing is the dangerous zero.

### 1. The fit, recomputed from the ranges

Builds `d` and `n` as three `DVector`s each — low, mode, high — and does the crossed subtraction
as vector arithmetic, one line per bound. Then classifies each layer by ISO 286's criterion and
compares to the filed `sign`.

```
1. fits recomputed from the ranges: 21 layers, 0 disagreements
```

It also asserts `n >= 20` before it asserts anything about the answers, so the check cannot
pass by examining nothing. ↑ *the claim this settles is [`r = n − d` reverses its
bounds](#r--n--d-reverses-its-bounds).*

### 2. `DᵀN`, the good zero

```
2. D-transpose N: 1 operation both draws and induces, 0 with both stated
   'Close an enterprise contract' draws on `labour` and commits `capability`,
      and THE DRAW IS UNMEASURED, so the product is empty.
```

The product is not computed because it cannot be. **The section reports why rather than
printing an empty matrix**, because the reason is the finding: the one cross-layer entry this
corpus could have had is missing for exactly the reason the model exists.
↑ *settles [`DᵀN` composes, but its quantities do not](#dᵀn-composes-but-its-quantities-do-not).*

### 3. `FΦx − e`, as an actual matrix product

`F` is built as a dense incidence matrix — 1 where a part composes into a layer — and `Φ` as a
diagonal. Then the fusion is three real matrix products, one per bound, and each result is
compared against the demand the composed layer filed.

```
3. F.Phi.x - e against the filed composed demand: 8 layers, all agree
```

⭐⭐ **This is where "a matrix product is a join with a `GROUP BY`" gets checked.**
`matrices.sql` computes the same eight rows with a join and a sum. Same answer, two algorithms.
↑ *settles [the one idea](#the-one-idea-both-algebras-share), [the fusion
rule](#and-the-fusion-rule-checks-out), and the claim that **a consolidation IS this
expression** — [from the financial side](#from-the-financial-side).*

### 4. `Φ`, correlated with itself

```
4. Phi: filed [1414, 2857, 4085.6] vs re-derived [1092, 2857, 4198.8]
   Equal at the mode, apart at both bounds, by 322.0 and 113.2.
```

**The assertion here used to be `> 1.0`, and that was wrong** — a threshold cannot tell a
small real disagreement from *no* disagreement. No disagreement would mean `Φ` has no spread,
which would make the whole section vacuous while still printing green. It is now two assertions:
first that some factor actually spreads, then that the bounds differ at all.
↑ *settles [`Φ` is correlated with itself](#φ-is-correlated-with-itself-and-the-corpus-proves-it)
and the translation trap in [where an accountant's instinct is
wrong](#where-an-accountants-instinct-is-wrong-and-it-is-worth-ten-minutes).*

### 5. What densifying costs

The one section where the matrix form **loses**, kept at the end because it is more useful than
a victory lap.

```
5. C densified to 7x7: 3 filings state a coupling, 0 assert independence, 4 say nothing
   In `values` all 49 entries are 0.0 and indistinguishable.
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
[§6](#6-the-zero-that-turned-out-to-be-two).*

### 6. The zero that turned out to be two

Not a section of the example — a section of `rules.sql`, and the reason the previous five got
sharper. Five encodings in the two schemas held a three- or four-valued fact in two states, and
every one of them survived review **because both of its values were correct.** Nothing in a
boolean, or in an empty list, points at what it cannot say.

| what was two-valued | the value that had no encoding |
|---|---|
| `Stack/coupling`, an unbounded element | ⭐⭐ *somebody looked and the layers are independent* |
| `Fusion/elimination`, an unbounded element | *the composer checked and the parts do not double count* |
| `Divisibility/window`, optional | *the unit has no denominator, so the question is malformed* |
| `Claim/boundOrigin`, optional | *nothing sets this bound — the range is where the measurements fell* |
| `CoverageEntry/complete`, the only `xs:boolean` | *the witness answers PART of the question* |

```
⛔⛔⛔ HAS ANYBODY TESTED THE MODEL?
+----------------------------------------------+--------+
| the_independence_assumption           | stacks |
+----------------------------------------------+--------+
| somebody looked and the layers MOVE TOGETHER | 3 |
| NOBODY LOOKED                                | 3 |
| one layer; no pair to couple                 | 1 |
+----------------------------------------------+--------+
```

⛔⛔ **Read the row that is not there.** No stack in this corpus asserts independence. The
model's central claim — that a layer is a place where a remainder is held *independently of every
other layer's* — has never been tested in seven filings, and has once been contradicted. That is
a fact about the EVIDENCE rather than about any one document, and it is a fact only because the
empty list stopped being an answer.

**The same shape one document up, and here the answer changes the arithmetic.** A fusion that
files `eliminations` as `none` or `notApplicable` owes an EXACT sum — the composed figure equals
`Σ` converted parts, full stop. One that files `unmeasured` owes nothing and the check is
suspended. An empty list quietly bought the first reading for every composer who had earned the
second, which is the sum rule `Elimination` exists to make exact, silently back to a warning.

**And requiring `boundOrigin` produced a result nobody was looking for.**

```
| stated in a sibling element (amountOrigin, quantum origin)  | 48 |
| NOTHING sets it -- the range is where the measurements fell | 68 |
| nobody has asked                                            | 3 |
| somebody owns it: contractual / intrinsic / policy          | 5 |
```

Roughly a third of the corpus answers `derived`, meaning **the model already states the author of
that edge in a sibling element and had no way to point at it.** `Nameplate/amountOrigin` and
`LumpyQuantum/origin` were doing the job for the nameplate half of every filing while
`boundOrigin` sat blank three lines away — required and wrapped in one case, optional and silent
in the other, in the same sequence.
↑ *settles [why the tables are shaped as they are](#why-the-tables-are-shaped-as-they-are).*
