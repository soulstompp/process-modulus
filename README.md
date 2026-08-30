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

Most of the parties who bear a remainder already show up in the accounts. The one this
model adds is the one that does not, which is the capacity absorbed by the people doing the
work. Nothing was bought, so there is no transaction, so no instrument records it, so it is
invisible to every system that starts from transactions. The schema is built so that
"nobody measured this" is a claim a sender files rather than a cell they leave blank.

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
- **Refutable in its own format.** `examples/refutation.xml` is a valid document that files
  two counter-examples to the model.
- **A generated Rust crate.** Every type and every doc comment comes from the schemas, so
  `cargo doc` shows the schema's own annotations.

## Why process-modulus

**The remainder is the contribution.** Buffers are Hopp and Spearman's, closed at three in
*Factory Physics*, and this model adopts them as published rather than adding a fourth.
What it adds is a separate axis: who holds the remainder. `booked`, `counterparty`,
`customer`, `unrealised` and `people` are the five, and only the last of them has no
instrument behind it.

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

* Eight rules across the two schemas are stated in prose and no validator can reach them,
  because XSD 1.0 has no `xs:assert` and cannot compare across elements. Most are marked
  `NOT REACHABLE BY A VALIDATOR` at the annotation that states them, so a reader can tell a
  binding rule from an unenforced one. [`conformance/README.md`](conformance/README.md)
  lists all eight and says what an implementer still owes.

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
  <pm:stack>  ... the layers ...                       </pm:stack>
  <pm:operation> ... what draws on them ...            </pm:operation>
</pm:processModulus>
```

A layer is a demand, a supply and the remainder between them. Here is the labour layer from
[`examples/enterprise-contract.xml`](examples/enterprise-contract.xml), which is the case
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
      <pm:narrowsWhen>support interrupts are time-recorded instead of estimated</pm:narrowsWhen>
      <pm:provenance><pm:party>platform</pm:party></pm:provenance>
      <pm:asOf>2026-08-30</pm:asOf>
    </pm:claim>
  </pm:demand>
```

`narrowsWhen` is what would have to change for the range to tighten, which is a different
fact from the range itself and is worth carrying beside it.

The supply has two faces. `nameplate` is what was committed, and it is where divisibility
lives. `origin` records who you would have to talk to in order to change the quantum, and
`intrinsic` means nobody, because one person is one person.

```xml
  <pm:supply>
    <pm:label>the platform team</pm:label>
    <pm:nameplate>
      <pm:amount>
        <pm:claim>
          <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
          <pm:unit>people</pm:unit>
        </pm:claim>
      </pm:amount>
      <pm:divisibility>
        <pm:divisibility>
          <pm:lumpy>
            <pm:size>
              <pm:claim>
                <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
                <pm:unit>people</pm:unit>
              </pm:claim>
            </pm:size>
            <pm:origin>intrinsic</pm:origin>
          </pm:lumpy>
        </pm:divisibility>
      </pm:divisibility>
      <pm:admitsInterference><pm:value>true</pm:value></pm:admitsInterference>
    </pm:nameplate>
```

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
material, and inspecting the output will not reveal it. The buffer is Hopp and Spearman's
`capacity`, cited to their taxonomy rather than restated. The holder is `people`, and the
quantity is `unmeasured` for the reason that is the whole point.

```xml
  <pm:remainder>
    <pm:remainder>
      <pm:sign>interference</pm:sign>
      <pm:absorber>
        <pm:taxonomy>urn:example:factory-physics:buffers</pm:taxonomy>
        <pm:value>capacity</pm:value>
      </pm:absorber>
      <pm:holder><pm:holder><pm:kind>people</pm:kind></pm:holder></pm:holder>
      <pm:quantity>
        <pm:absent>
          <pm:reason>unmeasured</pm:reason>
          <pm:note>the absorption has no counterparty and therefore no transaction</pm:note>
        </pm:absent>
      </pm:quantity>
    </pm:remainder>
  </pm:remainder>
</pm:layer>
```

Four people, a demand of five, an indivisible unit of one, and a difference that landed on
somebody. The document says who, says that nobody measured it, and says who stands behind
that statement. That is the whole model in one layer.

## Quick start

```bash
cargo test          # parses examples/ with the generated types and checks their claims
cargo doc --open    # the schemas' annotations, as rustdoc
```

Validating a document needs none of that, which is the point of shipping a schema rather
than a library:

```bash
xmllint --noout --schema schema/process-modulus.xsd examples/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       examples/coverage-us-gaap.xml
```

`examples/` holds seven documents: an enterprise contract, two coverage files answering the
same questions under different regimes, a run record, a refutation, one that exercises
everything a sender may decline, and one cross-document dependence.

## The model

The stock half describes a supply and what is left over.

| | |
|---|---|
| `Facility` | one supply with both of its faces at once: the `Nameplate` that was committed, and the `Jagged` record of what happened |
| `Divisibility` | whether a supply is lumpy or continuous. It is a choice between two shapes, not a size that might be zero, so a continuous supply has no quantum rather than a quantum of zero |
| `LumpyQuantum` | the indivisible unit the project is named after. In `a mod n`, `n` is the modulus, and `a mod n` is the remainder it leaves |
| `ConstraintOrigin` | who you have to talk to in order to change a quantum: `intrinsic` (nobody), `contractual` (the counterparty), `policy` (you, unilaterally) |
| `Remainder` | what the division leaves. `absorber` names somebody else's buffer set; `holder`, who bears it, is this model's own |
| `Claim` | how every quantity is expressed, as a three-point estimate with its provenance |
| `Absence` | a blank that says which kind of blank it is. A reason a query cannot reach is not a typed absence, so a paragraph in a notes field does not count |
| `Provenance` | who stands behind a value, as `party`, `enteredBy` and `approvedBy`, and what `standing` the assertion has |

The flow half describes where a supply meets a demand and what draws on it.

| | |
|---|---|
| `Layer` | a demand, a supply and a remainder |
| `Stack` | the layers of one system, deliberately unordered |
| `Coupling` | an observed dependence between two layers' remainders |
| `Operation` | the unit at which a draw is attributable, and not a unit of sequence |
| `Draw` | what an operation takes from a layer, now |
| `Induction` | a commitment made here that becomes a draw somewhere else, and who made it |

### Three decisions worth knowing about

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

## How it fits alongside existing standards

The model names other people's vocabulary rather than restating it. A restated value set is
a fork, and a fork drifts with nothing here able to notice that it has.

| borrowed from | what, and how it connects |
|---|---|
| BPMN 2.0 | sequence, gateways and events. `ForeignId` points at the same operation in a BPMN model, so a process notation and this model travel together |
| *Factory Physics* (Hopp and Spearman) | the buffer set of inventory, capacity and time, adopted closed and as published |
| ISO 286 | `clearance` and `interference`, in the mechanical sense |
| accounting frameworks | every measurement basis except `nameplate`, which describes committed capacity rather than value and so has no framework definition to cite |

What this model is answerable for is the short list: `Remainder`, `Holder`, `Divisibility`
and `ConstraintOrigin`, `Layer` and `Coupling`, `Induction`, `Claim`, `Absence`,
`Provenance`, and `nameplate`.

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

[`examples/coverage-us-gaap.xml`](examples/coverage-us-gaap.xml) and
[`examples/coverage-pt-ncrf-pe.xml`](examples/coverage-pt-ncrf-pe.xml) answer the same
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

[`examples/dependence-group-consolidation.xml`](examples/dependence-group-consolidation.xml)
files one across two regimes, and `tests/dependence_parse.rs` asserts the property it
exists for, which is that neither end is the witness's own filing.

## It can be refuted, and the refutation is a filing

[`examples/refutation.xml`](examples/refutation.xml) is a valid document filing two
counter-examples: a supply with no quantum whose continuous price carries no premium, and a
coupling between two layers' remainders with the observation that produced it. Both
validate, so disagreement with the model can be filed rather than only discussed.

## What this is not

**Not a storage design.** There are no tables, keys, indexes or versioning constructs here,
on purpose. The database falls out of normalising the model properly, and that is the
implementer's job rather than the schema's.

**Not a process notation.** There is no sequence flow, no gateway, no event and no token.
BPMN 2.0 models all of that and ships public schemas for it. Restating any of it inside
this namespace would fork it.

## Project status

Early. The schemas are complete enough to write real documents against, and the examples
are checked two independent ways: an XSD validator, which is what any adopter will run, and
`tests/examples_parse.rs`, which reads them with the generated types and asserts the facts
each example exists to demonstrate. The validator was proved able to reject before any pass
was believed, using three deliberate defects and three distinct rejections.

What is not settled is the namespace URIs and the first published version. No conformance
profile exists yet, by choice.

## Licence

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT license ([LICENSE-MIT](LICENSE-MIT))

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for
inclusion in this work by you, as defined in the Apache-2.0 licence, shall be dual
licensed as above, without any additional terms or conditions.
