# process-modulus

`process-modulus` is an XML Schema for describing how a business actually meets demand:
what it has committed, what that commitment can be divided into, what the division leaves
over, and who ends up carrying it. You write instance documents against the schema,
validate them with any XSD 1.0 validator, and the result is a description another
organisation can read without running any of this code.

> **Provisional namespace URIs.** Both schemas and `build.rs` carry
> `https://example.invalid/…` until the author's hosting domain is settled.
> `tests/namespace.rs` makes changing them a checked operation. Everything else is real.

The model starts from one observation. A business is a stack of quantized supplies serving
continuous demands. Demand varies smoothly, while supply arrives in whole units: a person,
a reserved block of hardware, a launch, a funding round. The difference between the two is
a **remainder**, and it does not go away. Management chooses which buffer absorbs it and
who bears it. Management does not choose whether it exists.

What the remainder does next is the part that takes longest to see, and it is not what the
word "leftover" suggests. A business asked for more than it committed to does not seize up.
It settles. The line runs a little hot, the queue backs up until callers stop waiting, and
from then on a steady portion of the demand leaves every week. The business is short and
stable at the same time, and it can stay that way for years. **Nothing fails. What it
produces is a residual**, week after week, and the residual is what this schema is for.

Which makes the question not "did you cope" but **where did it go**. Some of it the team
absorbed by working above their rating. Some a counterparty took and invoiced. Some a
customer bore by waiting and then going elsewhere. Some was never served at all. Those are
four different events with four different consequences, and only one of the five ways a
remainder can be borne leaves a transaction behind.

That is the one this model adds: the capacity absorbed by the people doing the work. Nothing
was bought, so there is no transaction, so no instrument records it, so it is invisible to
every system that starts from transactions. The schema is built so that "nobody measured
this" is a claim a sender files rather than a cell they leave blank.

⭐ And once it is filed that way, something useful follows. If a document says how much was
demanded, how much was committed, and how far the supply can be pushed past its rating, then
**the part of the residual with no record behind it can be worked out anyway** — not as an
argument about invisible work, but as a number, from three fields the sender had to fill in
regardless.

That is a real ask, and the cost is worth stating up front. Writing this schema means
committing to say which kind of blank each blank is, to express quantities as ranges rather
than as single numbers, and to name the authority behind every value borrowed from someone
else. Corpora that already exist tend to do none of the three, and that migration is the
work. What you get for it is a document that stays true after it crosses an organisational
boundary, which is the only place any of this matters.

## Features

- **A schema, not a library.** `schema/process-modulus.xsd` is the deliverable. Validating
  a document needs no Rust and no dependency on this project.
- **XSD 1.0 on purpose**, so that `xmllint`, the JDK's bundled validator, `lxml`, Nokogiri
  and everything else that wraps libxml2 can check a document on a stock machine.
- **Typed absence.** A blank says which kind of blank it is: `none`, `unmeasured`,
  `notApplicable` or `derived`. An absence of evidence and evidence of absence stop looking
  alike.
- **Three-point claims.** Every quantity is a `low`, `mostLikely` and `high` with its
  provenance and date. There is no bare number type anywhere in the model.
- **Borrowed values carry their authority.** Anything this model does not own travels as
  `BorrowedTerm { taxonomy, value }` with the taxonomy required, so a value arrives with
  the authority that defines it instead of as a bare code.
- **Regimes split into separate axes.** Jurisdiction, framework and the authority that
  codes the framework are three questions, and one enumeration mixing them answers none of
  them.
- **Answers travel on their own.** `schema/assertion.xsd` lets a second party answer a
  corpus of questions and send the answers without running anything from here.
- **Cross-filing observations have a home.** A dependence between two entities that file
  separately belongs to whoever read both filings, and it is a document rather than a
  footnote in either one.
- **A consolidation is a document somebody signs.** Two honest filings cannot be merged by
  any heuristic — joining on the layer name merges unrelated things, joining on the facts
  filed misses the pair that is genuinely one layer. So the party with standing files the
  mapping itself, says what it treated as one layer and why, and records what it removed to
  avoid counting demand twice. Compositions nest, so a group composes segments with nothing
  added.
- **Refutable in its own format.** `assets/corpus/refutation.xml` is a valid document that files
  two counter-examples to the model.
- **A generated Rust crate.** Every type and every doc comment comes from the schemas, so
  `cargo doc` shows the schema's own annotations.
- **The unreachable rules, made runnable.** Forty-four rules are stated in the schemas' prose
  and gated by nothing, because XSD 1.0 cannot compare one element against another. Most of
  them are joins and comparisons. [`assets/sql/`](assets/sql/) expresses them as SQL — including
  the one no validator can see, that no leaf layer is reachable through two paths once
  compositions nest — and reports how many rows each rule actually examined, because a rule
  with nothing to check passes loudest.
- **Every blank has a reason attached.** Not "the field is empty" but *which* kind of empty:
  somebody looked and there is none, nobody has measured it, the question does not apply here,
  or it is computed from something else. That applies to lists too — a stack with no couplings
  filed says whether anybody went looking, because "we tested the layers and they are
  independent" and "nobody checked" are opposite claims and used to be the same document.

## Why process-modulus

**The remainder is the contribution.** Buffers are Hopp and Spearman's, closed at three in
*Factory Physics*, and this model adopts them as published rather than adding a fourth.
What it adds is a separate axis: who holds the remainder. `booked`, `counterparty`,
`customer`, `unrealised` and `people` are the five, and only the last of them has no
instrument behind it.

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

* Forty-four rules across the two schemas are stated in prose and no validator can reach
  them, because XSD 1.0 has no `xs:assert` and cannot compare across elements. Forty-one
  are marked `NOT REACHABLE BY A VALIDATOR` at the annotation that states them, so a reader
  can tell a binding rule from an unenforced one. [`conformance/README.md`](conformance/README.md)
  lists all forty-four and says what an implementer still owes. Most of them are joins and
  comparisons across elements, which is a shape XSD has no way to express and a query
  language has nothing else.

* Deserialization is not validation, and there is one concrete case where they differ.
  `Operation` is a sequence with a repeated choice in it, which the code generator
  flattens into a single `Vec`, so `label` stops being a required singular field as far as
  `rustc` is concerned. The XSD still enforces it. Validate with an XSD validator.

* No conformance profile ships yet. A profile should follow a real adopter rather than
  precede one, and the reasoning behind that is in `conformance/`.

* The namespace URIs are still placeholders. Nothing else in the repository is.

## Example: a team of four serving a demand of five

The document root is a `processModulus`: some regime declarations, one stack of layers, and
any number of operations that draw on them.

```xml
<pm:processModulus xmlns:pm="https://example.invalid/process-flow/1.0">
  <pm:regime> ... what this document reports under ... </pm:regime>
  <pm:stack>
    ... the layers ...
    <pm:couplings>
      <pm:absent>
        <pm:reason>unmeasured</pm:reason>
        <pm:note>nobody has tested whether these layers move together</pm:note>
      </pm:absent>
    </pm:couplings>
  </pm:stack>
  <pm:operation> ... what draws on them ...            </pm:operation>
</pm:processModulus>
```

⭐ `couplings` is required, and it is the one element in the schema that asks a filer whether
they **tested** the model rather than what they measured. A stack claims its layers are separate
places where a shortfall can land; this is where a filer says whether anybody checked. "We
relieved one layer and the others did not move" and "nobody looked" are opposite claims, and
without this they were the same empty document.

A layer is a demand, a supply and the remainder between them. Here is the labour layer from
[`assets/corpus/enterprise-contract.xml`](assets/corpus/enterprise-contract.xml), which is the case
the whole model exists for. The demand is between 4.5 and 6 people. The supply is four
people, and a person is not divisible.

```xml
<pm:layer>
  <pm:name>labour</pm:name>

  <pm:demand>
    <pm:claim>
      <pm:low>4.5</pm:low>
      <pm:mostLikely>5.2</pm:mostLikely>
      <pm:high>6.0</pm:high>
      <pm:unit>people</pm:unit>
      <pm:narrowsWhen>
        <pm:narrowing>
          <pm:condition>support interrupts are time-recorded instead of estimated</pm:condition>
          <pm:kind>instrument</pm:kind>
        </pm:narrowing>
      </pm:narrowsWhen>
      <pm:boundOrigin>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>nothing sets this bound. The range is where the observations fell</pm:note>
        </pm:absent>
      </pm:boundOrigin>
      <pm:provenance><pm:party>platform</pm:party></pm:provenance>
      <pm:asOf>2026-08-30</pm:asOf>
    </pm:claim>
  </pm:demand>
```

Two facts travel beside the range, and they answer different questions. `narrowsWhen` is what
would have to change for it to **tighten** — and `kind` says whether that is a measurement
arriving or the process itself changing, which is the difference between not knowing and
genuinely varying. `boundOrigin` is **who owns the edge**: `none` here says somebody looked and
nobody owns it, because this range is where twelve months of observations fell rather than where
a rule put them. A demand bounded by a contract would say `contractual`, and that is a lever.

The supply has two faces. `nameplate` is what was committed, and it is where divisibility
lives. Two different constraints are recorded, and keeping them apart is the point:
`origin` is who you would have to talk to in order to change the **size of one unit**, and
`intrinsic` means nobody, because one person is one person. `amountOrigin` is who you would
have to talk to in order to hold a **different number of them**, and `policy` means us,
because the establishment is ours to set.

⭐ Those two are why the claims above answer `boundOrigin` with `derived` rather than repeating
themselves. The question *who owns this edge* is already answered one element over, and a
document that answered it twice would eventually answer it two different ways.

`window` is the other half of divisibility: not how the supply divides in **amount** but how it
divides in **time** — a line running five days of seven, a machine stopped two hours a day. A
headcount has no such cycle, so the answer is `notApplicable` and the reason says which of the
alternatives is meant. It is not a blank.

```xml
  <pm:supply>
    <pm:label>the platform team</pm:label>
    <pm:nameplate>
      <pm:amount>
        <pm:claim>
          <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
          <pm:unit>people</pm:unit>
          ... narrowsWhen: notApplicable, there is no range here to tighten ...
          ... boundOrigin: derived, amountOrigin below states it ...
        </pm:claim>
      </pm:amount>
      <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>
      <pm:divisibility>
        <pm:divisibility>
          <pm:lumpy>
            <pm:size>
              <pm:claim>
                <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
                <pm:unit>people</pm:unit>
                ... boundOrigin: derived, the origin below states it ...
              </pm:claim>
            </pm:size>
            <pm:origin>intrinsic</pm:origin>
          </pm:lumpy>
          <pm:window>
            <pm:absent>
              <pm:reason>notApplicable</pm:reason>
              <pm:note>`people` is a stock with no period</pm:note>
            </pm:absent>
          </pm:window>
        </pm:divisibility>
      </pm:divisibility>
      <pm:capacitySlack>
        <pm:absent>
          <pm:reason>unmeasured</pm:reason>
          <pm:note>a person can work above their rating; how far above, nobody has measured</pm:note>
        </pm:absent>
      </pm:capacitySlack>
      <pm:inventorySlack>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>an hour not used today is gone; it cannot be stockpiled for next week</pm:note>
        </pm:absent>
      </pm:inventorySlack>
    </pm:nameplate>
```

The two `slack` elements say how much give each buffer has. A person can be run above
their rating, so that buffer is open and nobody has measured how far — `unmeasured`. An
unused hour cannot be saved for next week, so that one is shut, and `none` is the value
that says somebody checked rather than that somebody skipped it. ⭐ The difference matters
later: a share can only be attributed to a buffer that has room for it.

`jagged` is the other face, which is what actually happened. This is where the argument
gets filed. Nothing recorded the hours absorbed above the establishment, so the draw is
`unmeasured` with a note saying why and a party standing behind the statement. It is not an
empty element.

```xml
    <pm:jagged>
      <pm:draw>
        <pm:absent>
          <pm:reason>unmeasured</pm:reason>
          <pm:note>no instrument records hours absorbed above the establishment</pm:note>
          <pm:provenance><pm:party>platform</pm:party></pm:provenance>
          <pm:asOf>2026-08-30</pm:asOf>
        </pm:absent>
      </pm:draw>
      <pm:measurementBasis>
        <pm:absent>
          <pm:reason>notApplicable</pm:reason>
          <pm:note>there is no valuation here to have a basis</pm:note>
        </pm:absent>
      </pm:measurementBasis>
    </pm:jagged>
  </pm:supply>
```

Note that the two absences are different reasons. The draw is `unmeasured`, meaning an
instrument could exist and does not. The measurement basis is `notApplicable`, meaning
asking the question is malformed here, because a headcount has no valuation to have a basis
for. A receiver that treated the second as a gap would report a deficiency that does not
exist.

The remainder is then the conclusion. Demand exceeded the nameplate, so the fit is
`interference` in the mechanical sense borrowed from ISO 286: it works by deforming the
material, and inspecting the output will not reveal it. A layer can also be short in some
weeks and spare in others, which is the third class, `transition`, and is the ordinary
condition of a business at capacity. The buffer is Hopp and Spearman's
`capacity`, cited to their taxonomy rather than restated.

The **holders** are where the point lands. Some of the excess the team absorbed, and some of it
queued, waited and quietly went away. Neither leaves a record, so both **shares** are
`unmeasured` — and note what that does not say. It does not say the remainder is unknown: the
size is `derived` from figures already in the document. It says nobody can tell you how the
two halves divide, which is a smaller and much sharper thing to admit.

```xml
  <pm:remainder>
    <pm:remainder>
      <pm:sign><pm:fit>interference</pm:fit></pm:sign>
      <pm:absorber>
        <pm:term>
          <pm:taxonomy>urn:example:factory-physics:buffers</pm:taxonomy>
          <pm:value>capacity</pm:value>
        </pm:term>
      </pm:absorber>
      <pm:holder>
        <pm:holder>
          <pm:kind>people</pm:kind>
          <pm:share>
            <pm:absent>
              <pm:reason>unmeasured</pm:reason>
              <pm:note>the absorption has no counterparty and therefore no transaction</pm:note>
            </pm:absent>
          </pm:share>
        </pm:holder>
      </pm:holder>
      <pm:holder>
        <pm:holder>
          <pm:kind>unrealised</pm:kind>
          <pm:share>
            <pm:absent>
              <pm:reason>unmeasured</pm:reason>
              <pm:note>work that queued, waited and aged out before anyone got to it</pm:note>
            </pm:absent>
          </pm:share>
        </pm:holder>
      </pm:holder>
      <pm:quantity>
        <pm:absent><pm:reason>derived</pm:reason></pm:absent>
      </pm:quantity>
    </pm:remainder>
  </pm:remainder>
</pm:layer>
```

Note which of the two is absent, because it is not the one people expect. The remainder's
size is `derived`: the document determines it and a receiver computes it. What no instrument
reaches is the `share` — how much of that gap the team absorbed rather than turned away.

Four people, a demand of five, an indivisible unit of one, and a difference that landed on
somebody. The document says who, says the size, says that nobody measured the part that
matters, and says who stands behind that statement. That is the whole model in one layer.

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
psql -d process_modulus_proof -f assets/sql/schema.ddl \
                              -f assets/sql/ingest.sql \
                              -f assets/sql/rules.sql
```

Postgres reads the corpus itself — no Rust, no extensions, no superuser. See
[`assets/sql/README.md`](assets/sql/README.md).

`assets/corpus/` holds eleven documents: an enterprise contract, a refutation, one that
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
means a new layer needs no schema change. The stack is unordered for the same reason: an
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
*what we do not know* — `narrowsWhen` says what would tighten it — while a range that is
genuine week-to-week variation does not narrow when you measure harder. The two are not
distinguished, and saying so is more useful than pretending the question does not arise.

## How it fits alongside existing standards

The model names other people's vocabulary rather than restating it. A restated value set is
a fork, and a fork drifts with nothing here able to notice that it has.

| borrowed from | what, and how it connects |
|---|---|
| BPMN 2.0 | sequence, gateways and events. `ForeignId` points at the same operation in a BPMN model, so a process notation and this model travel together |
| *Factory Physics* (Hopp and Spearman) | the buffer set of inventory, capacity and time, adopted closed and as published |
| ISO 286 | the three fit classes — `clearance`, `transition` and `interference` — in the mechanical sense, adopted closed and as published |
| accounting frameworks | every measurement basis except `nameplate`, which describes committed capacity rather than value and so has no framework definition to cite |

What this model is answerable for is the short list: `Remainder`, `Holder` and `HolderKind`,
`Divisibility` and `ConstraintOrigin`, the three slacks, `Layer` and `Coupling`, `Induction`,
`Claim`, `Absence`, `Provenance`, and `nameplate`.

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
| `Fusion` | which filed layers are **one** layer, and why. **Fuse only what is fungible**: if a unit of supply in one part can serve demand in the other, they do not hold their remainders independently and they are one layer. If it cannot, they are two, and a `Coupling` is where any observed interaction goes. That judgement is the composer's, `observed` is where they defend it, and it is the claim a reader is entitled to argue with. A layer with no fusion at all is the third case — one the composer **originated**, like a group-level rota |
| `Part` | one filed layer going in, with the `factor` that puts it in the composed layer's unit. `4.4 GPU + 545 GPU-hour` is not a sum, and a composer who quietly multiplies by 720 has done exactly the unaudited arithmetic this document exists to expose. A factor is itself a three-point claim, because a month is `[672, 720, 744]` hours |
| `Elimination` | what was removed, and why the fused figure is therefore **not** the sum of its parts. When one member commissions work from another, both file it as their own demand, honestly, and the group's demand is the sum minus the commission. It names which of the three quantities it hits, since an adjustment that does not say is applied to whichever number the reader happened to be holding |

**Whether anybody looked for double counting is itself a filed fact.** An empty list said "we
checked and the parts are disjoint" and "nobody checked" in the same bytes, and the two owe
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
implementer's job. ⚠️ `assets/sql/` does contain a Postgres DDL, and it is not a counter-example — it
exists to CHECK the model rather than to store it, and it says so in its first five lines.
Nothing in it is normalised for writing or indexed for a workload. Copy the ideas, not the
layout.

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
   with `examples/matrices.rs` recomputing the same arithmetic in `nalgebra` and asserting the
   two agree.

⭐ Each was proved able to fail before any pass was believed. The validator by three deliberate
defects producing three distinct rejections; the Rust tests by perturbation against a scratchpad
copy; the SQL by four edits inside a rolled-back transaction, which produced six violations
because two of the rules are not independent of each other.

The crate's major and minor track the schema's `xs:schema/@version`, and
`tests/namespace.rs` fails the build if they drift apart. ⚠️ What is **not** settled is the
namespace URIs, which are still `https://example.invalid/…`. No conformance profile exists yet,
by choice.

## Licence

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in this work by you, as defined in the Apache-2.0 licence, shall be dual
licensed as above, without any additional terms or conditions.
