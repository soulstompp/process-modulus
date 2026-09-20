# process-modulus

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

`process-modulus` is an XML Schema for describing how a business actually meets demand:
what it has committed, what that commitment can be divided into, what the division leaves
over, and who ends up carrying it. You write instance documents against the schema,
validate them with any XSD 1.0 validator, and the result is a description another
organisation can read without running any of this code.

> **Provisional namespace URIs.** Both schemas and `build.rs` carry
> `https://example.invalid/…` until the author's hosting domain is settled.
> `tests/namespace.rs` makes changing them a checked operation. Everything else is real.

The model starts from a division. A business meets demand that varies smoothly with supply that
arrives in whole units: a person, a shift, a reserved block of hardware, a launch, a funding
round. **The whole unit you have to divide by is the modulus**, and the division leaves something
over every time.

Take the case the corpus is built around. A platform team of four people serving a demand that
runs between 4.5 and 6.0, most likely 5.2. The shortfall is 1.2 people, and that 1.2 divides once
and cleanly:

```text
1 person      a whole unit, and A DECISION.      Hire one more and it moves.
0.2 people    the residue, and NOT a decision.   No headcount removes it.
```

Both halves come out of the same division, which is why the name points at the division rather
than at what it leaves. `Remainder` is what the schema calls the result; the modulus is what
makes one exist at all.

⛔ **And the distinction is load-bearing rather than pedantic.** *Management chooses which buffer
absorbs the remainder and who bears it; management does not choose whether it exists* is a true
sentence about the 0.2 and a false one about the 1.2, because the whole remainder contains a
decision. Run the two together and a model either flatters the business, by calling a staffing
choice a law of nature, or accuses it, by demanding it remove something nothing removes.

## Modulation is a choice, which is why nothing here is enumerated

The unit is not handed to you. The same team modulated in people and modulated in on-call weeks
are two readings of one business, both true, with different remainders landing on different
people. **Choosing the unit is the modelling act.** So the schema lists no layers: what makes
something a layer is that its remainder can be held independently of every other layer's, which
is a test you apply rather than a roster you are given.

⭐ And it is the same act all the way up. A parent fusing two members' layers into one is
dividing by a coarser unit, and it owes the same account of what the division left over. That is
why a consolidation here is a document somebody signs rather than a join somebody runs.

## The residue nobody bought

A remainder gets carried in five ways. Four of them leave a transaction behind or a customer who
noticed. The fifth does not: the capacity absorbed by the people doing the work, by working above
their rating. Nothing was bought, so no instrument records it, so it is invisible to every system
that starts from transactions.

That is what this schema is for, and it is why *nobody measured this* has to be something a
sender **files** rather than a cell they leave blank. ⭐ Once it is filed that way the size of the
residue can be worked out anyway, from figures the sender had to give regardless, and what stays
genuinely unknown shrinks to something much sharper: not how big the gap was, but how it split
between the people who absorbed it and the customers who quietly went away.

⭐ **The fastest way in is that one layer, read end to end**, and there is a section for it
below.

That is a real ask, and the cost is worth stating up front. Writing this schema means
committing to say which kind of blank each blank is, to express quantities as ranges rather
than as single numbers, and to name the authority behind every value borrowed from someone
else. Corpora that already exist tend to do none of the three, and that migration is the
work. What you get for it is a document that stays true after it crosses an organisational
boundary, which is the only place any of this matters.

## What you are writing

- **A schema, not a library.** [`schema/`](schema/) is the deliverable, and validating a document
  needs no Rust and no dependency on this project.
- **Five kinds of document, and four of them are signed by somebody other than the entity.** A
  filing, a coverage answer, a promoted run, a cross-filing dependence and a consolidation. A
  claim *about* a filing cannot live inside the filing it judges.
- **Typed absence, and it reaches lists too.** A blank says which kind of blank it is: `none`,
  `unmeasured` or `notApplicable`, with a position some identity computes carrying that identity's
  name instead. A stack with no couplings filed therefore says whether anybody went looking,
  because *these layers have been tested and they are independent* and *nobody checked* are
  opposite claims that a bare optional list spells the same way.
- **Three-point claims.** Every quantity is a `low`, `mostLikely` and `high` with its provenance
  and date. There is no bare number type anywhere in the model.
- **Borrowed values carry their authority.** Anything this model does not own travels as
  `BorrowedTerm { taxonomy, value }` with the taxonomy required, so a value arrives with the
  authority that defines it instead of as a bare code.
- **Regimes split into separate axes.** Jurisdiction, framework and the authority that codes the
  framework are three questions, and one enumeration mixing them answers none of them.
- **A generated Rust crate.** Every type and every doc comment comes from the schemas, so
  `cargo doc` shows the schema's own annotations.

## What it buys you

**The buffers are borrowed and the holders are ours.** Buffers are Hopp and Spearman's, closed
at three in *Factory Physics*, and this model adopts them as published rather than adding a
fourth. What it adds is the separate axis named above: `booked`, `counterparty`, `customer`,
`unrealised` and `people`.

**Demand perishes, and that is what keeps the arithmetic honest.** A queue that nobody ever
leaves grows for ever, and a model built on one would call every business over capacity
incoherent — which is most of them, most of the time. `timeSlack` is how long demand survives
being held, filed as a measured quantity rather than a yes or no. It is what makes a business
that is permanently short describable as a going concern rather than a contradiction. ⭐ Note
what it is NOT: a question about whether a customer is *willing* to wait. Nobody refuses
anybody here. Demand decays, the same way an unsold pastry decays.

**A blank is a claim, so it should be typed like one.** `unmeasured` on a labour draw is
the model's central argument, written down. If a sender can only leave the field empty,
then the argument and an oversight look identical, and the model's own subject becomes
unrecordable in the model.

**A code without its authority is ambiguous, not merely unattributed.** `6250` is one
account in Spain's PGC and a different one in Sweden's BAS. Two witnesses citing the same
coding pack are comparable row by row; two citing different packs are legibly different
rather than silently incomparable. Requiring the taxonomy is what buys that.

**Independence is what makes agreement mean anything.** This crate depends on nothing from
the codebase whose model it corroborates, and `tests/independence.rs` fails the build if
that stops being true. Two models sharing a type or a code path cannot corroborate each
other, because their agreement is a tautology. A consumer should generate its types from
the vendored schema, the way its BPMN reader generates from the vendored OMG schemas.

**Disagreement has somewhere to go.** A model you cannot file a counter-example against is
not doing much. `Coupling` records an observed dependence between two layers' remainders,
and a continuous supply whose premium is `none` contradicts the pricing claim. Both are
valid documents.

### Caveats

* The model is deliberately small and it is not close to a complete description of a
  business. It says what a supply is, what is left over, and who carries it. Everything
  about sequence, control flow and events is BPMN's job, and this model points at BPMN
  rather than restating it.

* The two schemas state rules in prose that no validator can reach, because XSD 1.0 has no
  `xs:assert` and cannot compare across elements. Nearly all of them carry the marker
  `NOT REACHABLE BY A VALIDATOR` at the annotation that states them, so a reader can tell a
  binding rule from an unenforced one. [`conformance/README.md`](conformance/README.md) lists
  them, names the query that runs each one that runs, and says what an implementer still owes.
  Most are joins and comparisons across elements, which is a shape XSD has no way to express
  and a query language has nothing else.

* Neither direction of the crate is validation, and one concrete case covers both.
  `Operation` is a sequence with a repeated choice in it, which the code generator
  flattens into a single `Vec`, so `label` stops being a required singular field as far as
  `rustc` is concerned. The XSD still enforces it. Reading, the types accept a document the
  validator refuses; writing, the crate emits an operation with no `label` and reports
  success. `tests/roundtrip.rs` holds every document here to surviving the write and the read
  back, which is a weaker claim than being valid. Validate with an XSD validator.

* No conformance profile ships yet. A profile should follow a real adopter rather than
  precede one, and the reasoning behind that is in `conformance/`.

* The namespace URIs are still placeholders. Nothing else in the repository is.

## One layer, read end to end

[`assets/corpus/README.md`](assets/corpus/README.md) walks the labour layer of
[`enterprise-contract.xml`](assets/corpus/enterprise-contract.xml) element by element: what
travels beside a range and why, the two origins that must never be merged, the two absences a
receiver must not merge either, and why the remainder's size is computable while the share is the
one thing no instrument reaches.

## Where the rest of the argument lives

Each line below is that document's own first line. The document is where it is authoritative, and
this table is a way in rather than a second copy of it.

| | |
|---|---|
| [`schema/`](schema/) | the deliverable itself, and the five documents it lets anybody write |
| [`assets/`](assets/) | the evidence, the machinery that reads it, and what is generated from both |
| [`conformance/`](conformance/) | what a profile may narrow, and which rules no validator reaches at all |
| [`src/proofs/`](src/proofs/) | The equations this model states, each shown to hold by a program that `cargo test` runs. |
| [`examples/`](examples/) | The examples, and the question each one puts to the model |

⭐ Nothing above is restated here, on purpose. A document that had to be summarised in its parent
would be summarised twice as soon as somebody changed it once, and the two copies would then
disagree with nothing able to notice.

## Quick start

```bash
cargo test          # parses assets/corpus/ with the generated types and checks their claims
cargo doc --open    # the schemas' annotations, as rustdoc
```

Validating a document needs none of that, which is the point of shipping a schema rather
than a library:

```bash
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/coverage-us-gaap.xml
```

And a third way, which checks the rules a validator cannot reach:

```bash
createdb process_modulus_proof
psql -d process_modulus_proof -f assets/ddl/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

Postgres reads the corpus itself — no Rust, no extensions, no superuser. See
[`assets/sqlc/README.md`](assets/sqlc/README.md).

`assets/corpus/` holds twelve documents: an enterprise contract and its European Portuguese
counterpart, a refutation, one that
exercises everything a sender may decline, two member filings and the two nested compositions
that consolidate them, two coverage files answering the same questions under different regimes,
a run record, and one cross-document dependence.

## The model

The stock half describes a supply and what is left over.

| | |
|---|---|
| `Facility` | one supply with both of its faces at once: the `Nameplate` that was committed, and the `Jagged` record of what happened |
| `Divisibility` | how a supply divides, on two axes. In AMOUNT it is `lumpy` or `continuous` — a choice between two shapes, not a size that might be zero, so a continuous supply has no quantum rather than a quantum of zero. In TIME it may carry a `window`: the machine that runs 02:00 to 05:00, the shift pattern, the two hours a day of maintenance. A supply can be both, and the choice could not say so |
| `LumpyQuantum` | the indivisible unit the project is named after. In `a mod n`, `n` is the modulus, and `a mod n` is the remainder it leaves |
| `ConstraintOrigin` | who you have to talk to in order to change something: `intrinsic` (nobody), `contractual` (the counterparty), `policy` (you, unilaterally). It is asked twice, about two different things: the size of one unit, and how many units are held |
| `Remainder` | what the division leaves, and it separates into whole quanta somebody chose plus a residue nobody can remove. `absorber` names somebody else's buffer set; `holder`, who bears it, is this model's own |
| `Holder` | who bears a remainder, and how much of it. One remainder routinely lands on several parties at once, so each carries a `share` and the shares sum to the whole. A single holder made the sender pick the biggest one and throw the rest away, and the discarded half is usually the interesting one |
| the three **slacks** | one measured quantity per buffer, and the three facts about a layer that no arithmetic recovers. `capacitySlack`: how far the supply can be driven past its rating — not spare capacity, the room ABOVE the rating. `inventorySlack`: how much output can be held ahead. `timeSlack`: how long the demand survives being held. They were three booleans once, and a bit says a buffer exists rather than how much it holds, so any share fitted |
| `Fit` | the sign of a remainder, in ISO 286's sense: `clearance`, `transition`, `interference`. A `transition` fit is short at the top of the demand range and spare at the bottom, which is the ordinary condition of a business at capacity, and it is one value rather than a hedge |
| `HolderKind` | the five ways a remainder is borne: `booked`, `counterparty`, `customer`, `people`, `unrealised`. Only the first leaves a transaction. `customer` and `unrealised` are both demand nobody served, and they differ by whether anybody was there to experience it |
| `Claim` | how every quantity is expressed, as a three-point estimate with its provenance |
| `Absence` | a blank that says which kind of blank it is. A reason a query cannot reach is not a typed absence, so a paragraph in a notes field does not count |
| `Provenance` | who stands behind a value, as `party`, `enteredBy` and `approvedBy`, and what `standing` the assertion has |

The flow half describes where a supply meets a demand and what draws on it.

| | |
|---|---|
| `Layer` | a demand, a supply and a remainder, plus `timeSlack`: how long that demand survives being held. ⭐ Not whether the customer is *willing* to wait — that would be an unfalsifiable claim about somebody else's state of mind, filed by the party who benefits from the answer. Demand decays, the way stock decays, and this measures the decay |
| `Stack` | the layers of one system, deliberately unordered |
| `Coupling` | an observed dependence between two layers' remainders |
| `Operation` | the unit at which a draw is attributable, and not a unit of sequence |
| `Draw` | what an operation takes from a layer, now |
| `Induction` | a commitment made here that becomes a draw somewhere else, and who made it |

### Four decisions worth knowing about

**The schema does not enumerate the layers.** What makes something a layer is that its
remainder can be held independently of every other layer's. That is a test you can apply
rather than a list you have to be given, it is also the model's fourth falsifier, and it
means a new layer needs no schema change. It is the same sentence that decides when two
filings hold **one** layer — see [a consolidation is a
filing](#a-consolidation-is-a-filing-and-the-composer-signs-it). The stack is unordered for the same reason: an
ordering between layers would itself be a coupling, and asserting one in the container
would prejudge the question `Coupling` exists to answer.

**An operation consumes and produces asymmetrically.** What it consumes is a draw against a
layer's supply now. What it produces is a commitment induced on another layer later, not an
output quantity. `Draw` and `Induction` are two types despite an almost identical shape,
because folding them into one with a discriminator would put two kinds of fact in one slot.

**`ConstraintOrigin` keeps a falsifier honest.** A vendor who starts selling in finer
increments is a market moving, not a refutation of the model, and splitting quanta by who
can change them is what makes the difference legible.

**The model carries no clock, and time gets in three ways anyway.** There is no sequence
here and no timestamp on anything that moves, because sequence and timing are BPMN's job.
But three different timescales bear on any figure in a document, and the model files two of
them. The first is the **quantum** — the size of the unit supply arrives in. The second is
the **denominator** of the unit, the period a rate is quoted over: `per quarter`, `per week`,
and it is what a `window` is a fraction of. The third is the timescale on which a quantity
actually moves, and it has no element. ⭐ That matters because a range in this model reads as
*what nobody knows* — `narrowsWhen` says what would tighten it — while a range that is
genuine week-to-week variation does not narrow when you measure harder. The two are not
distinguished, and saying so is more useful than pretending the question does not arise.

**Pointing at your process notation is optional. Saying whether you did is not.** Most filings
name no operation at all, and a filing that names none says nothing about BPMN. But an operation
that is filed must say where it sits in a process notation, or give the typed reason it names
none: `none` where somebody looked and it is in no notation, `unmeasured` where a notation exists
and nobody has located it, `notApplicable` where there is no notation to point into. Those were
one silence until the element was made required, and they are the difference between a crossing
nobody has done yet and a crossing there is nothing to do — which is exactly what a receiver
deciding whether the two documents can be laid side by side needs to be told. ⭐ The crossing
itself costs the other document nothing: it is named by position, so no field is added to your
BPMN and no tool that reads it has to change.

## How it fits alongside existing standards

The model names other people's vocabulary rather than restating it. A restated value set is
a fork, and a fork drifts with nothing here able to notice that it has.

| borrowed from | what, and how it connects |
|---|---|
| BPMN 2.0 | sequence, gateways and events. `ForeignId` points at the same operation in a BPMN model, so a process notation and this model travel together, and the crossing is rendered rather than described: [below](#the-crossing-is-drawn-and-every-sentence-on-it-says-what-states-it) |
| *Factory Physics* (Hopp and Spearman) | the buffer set of inventory, capacity and time, adopted closed and as published |
| ISO 286 | the three fit classes — `clearance`, `transition` and `interference` — in the mechanical sense, adopted closed and as published |
| accounting frameworks | every measurement basis except `nameplate`, which describes committed capacity rather than value and so has no framework definition to cite |

What this model is answerable for is the short list: `Remainder`, `Holder` and `HolderKind`,
`Divisibility` and `ConstraintOrigin`, the three slacks, `Layer` and `Coupling`, `Induction`,
`Claim`, `Absence`, `Provenance`, and `nameplate`.

## The crossing is drawn, and every sentence on it says what states it

`ForeignId` points *at* a BPMN model. This repository also goes the other way: it renders each
filing **as** a BPMN document, so a process modeller can lay the two notations side by side
instead of taking a description of one on trust.

```bash
cargo run --example diagramming   # one .bpmn per filing, into assets/bpmn/filings/
cargo run --example graphs        # the model's own graphs, as the lane sets of one pool
cargo run --example rendering     # assets/svg/ from assets/bpmn/, reading no model at all
cargo run --example compositions  # the compose DAG, into assets/dag/edges.sql, needing no database
```

What a correct translation owes is written down rather than assumed.
[`assets/sqlc/diagrams/roster.sqlc`](assets/sqlc/diagrams/roster.sqlc) carries one law per
element kind, and each law names the relation that supplies the count it has to match.
[`assets/sqlc/diagrams/domain_objects.sqlc`](assets/sqlc/diagrams/domain_objects.sqlc) says, for
every table in the model, which BPMN element it renders as or the typed reason there is none, and
a mapping that loses something says how: `demoted` means a person can still read the fact and a
tool cannot resolve it, `absent` means it is not in the artifact in any form.

⛔ **A drawing is believed in a way a table is not.** A wrong table gets re-checked; a wrong
diagram gets quoted in a deck. So every sentence an emitted document carries names the relation
that states it, in the file and on the drawn page, and `examples/diagramming/main.rs` reads them back
out of the artifact afterwards: a sentence with no source, a source that is not a relation in this
tree, and a source the emitter never queried each fail the run.

## Regimes

A document declares what it reports under. `Regime` keeps jurisdiction, framework and the
authority that codes the framework as three separate axes, because a list mixing them
(`us-gaap`, `us-accrual`, `pt`) cannot answer any of the three questions it merges.

`framework` may be declined with a reason, so "reports under something not yet named" and
"reports under nothing" are different documents rather than one omission. `chart` names the
account list that positions are coded in and works the same way. It is required for a
reason: it is what a receiver checks an answer's position against, and a blank that cannot
be told from an unasked question disables the check.

**A chart of accounts is not a reporting taxonomy**, and confusing them is the mistake the
element exists to catch. Spain's PGC, Sweden's BAS and Portugal's SNC are lists of accounts
an entity posts to. `http://fasb.org/us-gaap` is a list of concepts a filing is tagged
with, and it belongs in `framework`. Filing a reporting taxonomy as a chart declares a
chart nobody posts to.

**The United States publishes no chart of accounts at all.** Every filer's chart is their
own and unpublished, which is not an edge case but an entire filing population. A
self-authored chart names the entity as its own taxonomy: the filer genuinely is the
authority for their own account list, and naming themselves satisfies the rule honestly
rather than evading it. `unmeasured` is the wrong answer there, because that chart is
unpublished rather than unknown.

**A country code cannot pick a framework on its own.** Every jurisdiction met so far tiers
its frameworks by entity size. Portugal has NCRF, NCRF-PE and NC-ME beside NIC, Spain has
PGC with its SME and microentity variants, Sweden has K1 through K4. The tier is a fact
about the entity, and it is what selects the framework.

**The same framework is also coded differently by different authorities.** A Portuguese
microentity is `NC-ME` to IES's `AnexoASNC` and `M` to the SAF-T referencial, and because
`S` covers both `NCRF` and `NCRF-PE`, the coarser code cannot be mapped back. Declaring
both regimes is correct rather than duplicated, since neither declaration says what the
pair says.

A conformance profile is therefore keyed to an `(authority, framework)` pair and never to a
country. See [`conformance/`](conformance/README.md).

## Answers from a second witness

`schema/assertion.xsd` carries what a witness claims about a corpus of questions, plus a
run promoted to evidence. It imports the base schema for `BorrowedTerm` and `Regime`.

The questions themselves stay in each corpus, because datetime formats and facility cases
are different subjects and unifying them would be pretending otherwise. What crosses
organisations is the claim. An accountant's answers to a corpus are a coverage file, and
nobody should have to run this project's code to send one.

Both things an answer carries are borrowed terms. A refusal code comes from a coding pack,
which is deliberately shared across regimes. A chart position is national, so a US witness
cites the entity's own chart. Stored as bare codes, two positions from two countries would
compare as equal or unequal without either result meaning anything.

[`assets/corpus/coverage-us-gaap.xml`](assets/corpus/coverage-us-gaap.xml) and
[`assets/corpus/coverage-pt-ncrf-pe.xml`](assets/corpus/coverage-pt-ncrf-pe.xml) answer the same
questions under two regimes, and `tests/coverage_parse.rs` asserts that comparability holds
where the authorities match and breaks where they do not.

There is no runner here, and that is deliberate. Unification is by conformance rather than
by dependency: a shared vocabulary plus a test per runner that it conforms, never a library
that everything imports.

## A dependence between two filings belongs to whoever read both

`Coupling` records an observed dependence between two layers of one stack. The dependence
that matters is often between two entities that file separately and cannot see each other,
such as a parent and a subsidiary, a supplier and a customer, or two borrowers of one
lender.

Widening `Coupling` to point across that boundary was considered and rejected. It would put
a claim inside entity A's document that A cannot attest to, because A cannot see B's stack,
and the identity constraints could not follow it, so the reference would validate by not
being checked. A reference that looks constrained and is not is worse than an honest gap.

Instead `schema/assertion.xsd` carries `dependence`, an observation *about* two filings,
filed by the third party who read both: a group consolidator, an auditor, a lender. Both
ends are foreign, always, which is what makes the design work. There is never one local end
beside one foreign one, so there is never a reference that must reach across a boundary and
cannot. The world already files it this way, since a consolidation is a separate statement
rather than a footnote in the subsidiary's accounts.

[`assets/corpus/dependence-group-consolidation.xml`](assets/corpus/dependence-group-consolidation.xml)
files one across two regimes, and `tests/dependence_parse.rs` asserts the property it
exists for, which is that neither end is the witness's own filing.

## A consolidation is a filing, and the composer signs it

A `dependence` comments on two filings. A `composition` goes one step further: the party who
read them **files**. It is one document carrying a whole stack of its own plus the mapping
saying which layers of which filings each of its own layers was built from.

The problem it solves shows up the moment you hold two real filings. Two members of one group
each file honestly, and neither can be merged into the other by any rule you can write down.
Join them on the layer name and two unrelated vendor contracts both called `compute` become
one layer. Join them on the facts filed instead and you miss the pair that genuinely *is* one
layer, because one member instruments better than the other and their numbers therefore differ.
Two strategies, wrong in opposite directions, on one pair of honest documents.

The repair cannot live in either member. Neither has seen the other's stack, neither has
standing to name the other's layers, and a filing cannot cite a list published after it. So
the composer supplies the mapping in its own document and signs it, and three things carry it:

| | |
|---|---|
| `Fusion` | which filed layers are **one** layer, and why. **Fuse only what is fungible**: if a unit of supply in one part can serve demand in the other, they do not hold their remainders independently and they are one layer. If it cannot, they are two, and a `Coupling` is where any observed interaction goes. That judgement is the composer's, `observed` is where they defend it, and it is the claim a reader is entitled to argue with. ⚠️ The test is between two *different* teams by construction, so "they serve different customers" does not answer it — what settles it is whether one team's people can take the other's work. [`merge-group-composition.xml`](assets/corpus/merge-group-composition.xml) answers it with evidence and shows the rule refusing in the same breath: two delivery teams fuse because either side has picked up the other's backlog within a week, eleven times this year, while on-call stays a separate layer because the eight-hour offset makes it unfungible. A layer with no fusion at all is the third case — one the composer **originated**, like a group-level rota |
| `Part` | one filed layer going in, with the `factor` that puts it in the composed layer's unit. `4.4 GPU + 545 GPU-hour` is not a sum, and a composer who quietly multiplies by 720 has done exactly the unaudited arithmetic this document exists to expose. A factor is itself a three-point claim, because a month is `[672, 720, 744]` hours |
| `Elimination` | what was removed, and why the fused figure is therefore **not** the sum of its parts. When one member commissions work from another, both file it as their own demand, honestly, and the group's demand is the sum minus the commission. It names which of the three quantities it hits, since an adjustment that does not say is applied to whichever number the reader happened to be holding |

**Whether anybody looked for double counting is itself a filed fact.** An empty list says "the
parts were checked and are disjoint" and "nobody checked" in the same bytes, and the two owe
opposite arithmetic: under a checked-clean search the composed figure must equal the sum of its
converted parts exactly, and under `unmeasured` no equality is owed at all. That is the
difference between an exact rule and a warning, and it is why the search has a typed absence of
its own rather than being inferred from a count of zero.

**Compositions nest, and one rule escapes when they do.** A composition is itself a filing, so a
segment composes members and a group composes segments with nothing added. Within one document a
validator can enforce that no filed layer is consolidated twice. Across two it cannot, because
the second path runs through a document this one does not contain — so "no leaf layer is
reachable through two paths" is owed by whoever can fetch the chain, and
[`assets/sql/`](assets/sql/) is where it is actually checked.

[`assets/corpus/merge-us-member.xml`](assets/corpus/merge-us-member.xml) and
[`merge-pt-member.xml`](assets/corpus/merge-pt-member.xml) are the two members;
[`merge-group-composition.xml`](assets/corpus/merge-group-composition.xml) consolidates them and
[`merge-holding-composition.xml`](assets/corpus/merge-holding-composition.xml) consolidates the
group, which is the nesting. `tests/composition.rs` asserts both merge failures in the direction
that is true, so they stay demonstrations rather than claims.

## It can be refuted, and the refutation is a filing

[`assets/corpus/refutation.xml`](assets/corpus/refutation.xml) is a valid document filing two
counter-examples: a supply with no quantum whose continuous price carries no premium, and a
coupling between two layers' remainders with the observation that produced it. Both
validate, so disagreement with the model can be filed rather than only discussed.

## What this is not

**Not a storage design.** The schemas declare no tables, keys, indexes or versioning
constructs, on purpose: a database falls out of normalising the model properly, and that is the
implementer's job. ⚠️ `assets/ddl/schema.ddl` is a Postgres DDL, and it is not a counter-example.
It follows the XML schema as closely as the two formalisms allow, so that what is proved against
it is proved about the model rather than about a translation. It is sound and performant, and it
exists to CHECK the model rather than to serve an application. A real deployment will want
indexes, denormalisation and a write path this has no opinion about.

**Not an ergonomic Rust API.** The crate is the schemas plus whatever the code generator makes
of them, and the generated types read like generated types: no builders, no validation helpers,
no convenience constructors. A pleasant interface over these is a different piece of work and
belongs in its own crate. What is here is a faithful rendering of the schema and a set of tests
that hold it to its own annotations.

**Not a process notation.** There is no sequence flow, no gateway, no event and no token.
BPMN 2.0 models all of that and ships public schemas for it. Restating any of it inside
this namespace would fork it.

## Project status

Early. The schemas are complete enough to write real documents against, and the corpus is
checked **three independent ways**:

1. an **XSD validator**, which is what any adopter will run;
2. `tests/corpus_parse.rs`, which reads the documents with the generated types and asserts the
   facts each one exists to demonstrate;
3. `assets/sql/`, which expresses the cross-element and cross-document rules XSD cannot reach,
   with `examples/matrices/main.rs` recomputing the same arithmetic in `nalgebra` and asserting the
   two agree.

⭐ Each was proved able to fail before any pass was believed. The validator by three deliberate
defects producing three distinct rejections; the Rust tests by perturbation against a scratchpad
copy; the SQL by deliberate edits inside a rolled-back transaction, each aimed at a different
rule, which produce MORE violations than edits because the rules are not independent of one
another. ⭐ Re-run it rather than trusting this sentence: perturb a sign, a holder share, a
composed demand and a lumpy nameplate inside `BEGIN; ... ROLLBACK;`, then read
`assets/sql/reports/violations.sql`. The count moves as rules are added; the finding does not.

The crate's major and minor track the schema's `xs:schema/@version`, and
`tests/namespace.rs` fails the build if they drift apart. ⚠️ What is **not** settled is the
namespace URIs, which are still `https://example.invalid/…`. No conformance profile exists yet,
by choice.

Further reading: the model reconstructed for a reader who wants the matrices lives in the
examples that evaluate it, rather than in a note beside them. [`examples/`](examples/) is one
directory per program, each holding the program and the header that argues its case, with a table
of the question each one answers; nothing needs building to read it. `cargo doc --examples --open`
renders the same headers, and [`examples/matrices/`](examples/matrices/) is the one that carries
the arithmetic, with `nalgebra` on one side and `assets/sql/` on the other and the agreement
asserted on every run. ⭐ Every header exists in both languages, side by side in the same
directory, and `tests/examples.rs` fails if a program argues its case in only one of them.

## Licence

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in this work by you, as defined in the Apache-2.0 licence, shall be dual
licensed as above, without any additional terms or conditions.
