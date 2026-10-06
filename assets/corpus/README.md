# `assets/corpus/`: what a filing looks like, and one layer read end to end

> **Também disponível em português europeu: [`pt-PT/assets/corpus/README.md`](../../pt-PT/assets/corpus/README.md).**

Every document here is a claim about a business: a demand somebody observed, a supply somebody
committed, a remainder somebody carried. The figures are illustrative rather than anybody's real
numbers, and the documents are filings all the same. The directory beside it,
[`../fixtures/`](../fixtures/), holds the other kind: one document for each state the schema
admits, which says nothing about any business.

## The documents

| file | root | what it files |
|---|---|---|
| [`enterprise-contract.xml`](enterprise-contract.xml) | `pm:processModulus` | four layers and two operations. The layer read below is one of them |
| [`contrato-empresarial.xml`](contrato-empresarial.xml) | `pm:processModulus` | the same four layers, filed in Portuguese by a microentity under the IES `AnexoASNC` |
| [`unstated.xml`](unstated.xml) | `pm:processModulus` | everything a sender may decline, each with its reason |
| [`refutation.xml`](refutation.xml) | `pm:processModulus` | two counter-examples to the model, filed in the model's own format |
| [`merge-us-member.xml`](merge-us-member.xml) · [`merge-pt-member.xml`](merge-pt-member.xml) | `pm:processModulus` | two members of one group, each filing honestly about itself |
| [`merge-group-composition.xml`](merge-group-composition.xml) | `asrt:composition` | the group, one cycle up: which of its members' layers are one layer, and why |
| [`merge-holding-composition.xml`](merge-holding-composition.xml) | `asrt:composition` | the holding, one cycle further up, composing the group |
| [`dependence-group-consolidation.xml`](dependence-group-consolidation.xml) | `asrt:dependence` | a dependence between two filings, filed by somebody who filed neither |
| [`coverage-us-gaap.xml`](coverage-us-gaap.xml) · [`coverage-pt-ncrf-pe.xml`](coverage-pt-ncrf-pe.xml) | `asrt:coverage` | the same questions answered under two regimes, so the answers compare position by position |
| [`run-2026-08-30.xml`](run-2026-08-30.xml) | `asrt:run` | one dated run, promoted to evidence a report may cite |

Each document opens with a comment saying what it is for.

## One layer, end to end

The `labour` layer of [`enterprise-contract.xml`](enterprise-contract.xml) is the platform team
from the front page. Its team lead reports a demand of 4.5 to 6.0 people, most likely 5.2, and has
four people committed, who come one whole person at a time. Everything else in the layer follows
from those three facts.

### The demand the team lead reports

```xml
<pm:demand>
  <pm:amount>
    <pm:claim>
      <pm:low>4.5</pm:low>
      <pm:mostLikely>5.2</pm:mostLikely>
      <pm:high>6.0</pm:high>
      <pm:unit>people</pm:unit>
      <pm:denominator>
        <pm:absent><pm:reason>notApplicable</pm:reason></pm:absent>
      </pm:denominator>
      <pm:narrowsWhen>
        <pm:narrowing>
          <pm:condition>support interrupts are time-recorded instead of estimated</pm:condition>
          <pm:kind>instrument</pm:kind>
        </pm:narrowing>
      </pm:narrowsWhen>
      <pm:boundOrigin>
        <pm:absent>
          <pm:reason>none</pm:reason>
          <pm:note>nothing sets this bound. The range is where the observations fell,
                   not where a rule put them, so there is no lever here to look for</pm:note>
        </pm:absent>
      </pm:boundOrigin>
      …
    </pm:claim>
  </pm:amount>
</pm:demand>
```

`narrowsWhen` says what would tighten the range, and `kind` says whether that is a measurement
arriving or the process itself changing. Not knowing gets better by looking harder; genuine
variation does not. `boundOrigin` says who owns the edge, and `none` says somebody looked and
nobody does: the range is where the observations fell. A receiver who assumed a contract set the
bound would go looking for a lever that is not there.

The `denominator` is `notApplicable`. People are a stock, counted rather than quoted per week, so
this demand has no period.

### The commitment, and the whole unit it comes in

```xml
<pm:nameplate>
  <pm:amount>
    <pm:claim>
      <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
      <pm:unit>people</pm:unit>
      …
    </pm:claim>
  </pm:amount>
  <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>
  <pm:divisibility>
    <pm:divisibility>
      <pm:lumpy>
        <pm:size><pm:claim>
          <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
          <pm:unit>people</pm:unit>
          …
        </pm:claim></pm:size>
        <pm:origin>intrinsic</pm:origin>
      </pm:lumpy>
      <pm:window>
        <pm:absent>
          <pm:reason>notApplicable</pm:reason>
          <pm:note>the nameplate is quoted in `people`, a stock with no period,
                   so there is no period for a window to be part of</pm:note>
        </pm:absent>
      </pm:window>
    </pm:divisibility>
  </pm:divisibility>
  …
</pm:nameplate>
```

The nameplate is the commitment, made before the work. Two origins sit in it, and they answer
different questions. `origin` on the unit says who could change the size of one unit: `intrinsic`,
nobody, because one person is one person. `amountOrigin` says who could hold a different number of
them: `policy`, the business itself. That is what makes the one-person shortfall a decision. A
receiver with only the figure could not tell a decision from a constraint.

The unit divides in amount and not in time. The `window` is `notApplicable`, because people have
no period to be live in part of. The merge members' shift line, live 5 days of each week, is the
other case.

### What give each buffer has

```xml
<pm:capacitySlack>
  <pm:absent>
    <pm:reason>unmeasured</pm:reason>
    <pm:note>a person can work above their rating and in most stacks is the only supply
             that can. How far above, and for how long, nobody here has measured</pm:note>
  </pm:absent>
</pm:capacitySlack>
<pm:inventorySlack>
  <pm:claim>
    <pm:low>0</pm:low><pm:mostLikely>0</pm:mostLikely><pm:high>0</pm:high>
    <pm:unit>people</pm:unit>
    …
    <pm:provenance>
      <pm:party>platform</pm:party>
      <pm:note>capacity not used today is lost. Last week's unused hours cannot be
               stockpiled to serve this week, so `inventory` is never this layer's
               `absorber`</pm:note>
    </pm:provenance>
  </pm:claim>
</pm:inventorySlack>
```

A measured zero is a claim, with a unit, an owner and a source: somebody checked, and the answer is
nothing. `unmeasured` says nobody checked. The two are opposite statements, and an empty element
would spell them the same way.

### What happened

```xml
<pm:jagged>
  <pm:draw>
    <pm:absent>
      <pm:reason>unmeasured</pm:reason>
      <pm:note>no instrument records hours absorbed above the establishment</pm:note>
      …
    </pm:absent>
  </pm:draw>
  <pm:measurementBasis>
    <pm:absent>
      <pm:reason>notApplicable</pm:reason>
      <pm:note>there is no valuation here to have a basis</pm:note>
    </pm:absent>
  </pm:measurementBasis>
</pm:jagged>
```

This is the second record, what the supply actually served. Here nobody measured it, and the
filing says so. The two blanks carry different reasons, and a receiver keeps them apart. The draw
is `unmeasured`: an instrument could exist and does not. The measurement basis is `notApplicable`:
a headcount has no valuation to have a basis for. Read as a gap, the second would report a
deficiency that does not exist.

### The remainder

```xml
<pm:remainder><pm:remainder>
  <pm:sign><pm:fit>interference</pm:fit></pm:sign>
  <pm:absorber>
    <pm:term>
      <pm:taxonomy>urn:example:factory-physics:buffers</pm:taxonomy>
      <pm:value>capacity</pm:value>
    </pm:term>
  </pm:absorber>
  <pm:holder><pm:holder>
    <pm:kind>unrealised</pm:kind>
    <pm:share><pm:absent><pm:reason>unmeasured</pm:reason>
      <pm:note>work that queued, waited and aged out before anyone got to it</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>
  <pm:holder><pm:holder>
    <pm:kind>people</pm:kind>
    <pm:share><pm:absent><pm:reason>unmeasured</pm:reason>
      <pm:note>the absorption has no counterparty and therefore no transaction</pm:note>
    </pm:absent></pm:share>
  </pm:holder></pm:holder>
  <pm:quantity>
    <pm:derivation>
      <pm:identity>magnitude</pm:identity>
      <pm:note>computable from this layer's demand and nameplate; the receiver computes it</pm:note>
    </pm:derivation>
  </pm:quantity>
</pm:remainder></pm:remainder>
```

The fit is `interference`: the team is short wherever demand lands. The absorber is the `capacity`
buffer, cited to Hopp and Spearman's taxonomy rather than restated.

Notice which part is absent, because it is not the one people expect. The remainder's size is a
`derivation`: the team lead's own figures determine it, and a receiver works it out. What no
instrument reaches is the share, how the gap split between the people, who absorbed it, and the
work that waited until it aged out. That is how management learns how busy the people are: never
directly, always through the team lead's figures. It is also a much smaller admission than *we do
not know the remainder*.

There are two holders because the layer's own time slack asks for two. Its note says queued work
survives for a while and some of it ages out. Filing only `people` would say the team absorbed all
of it, which the same layer contradicts.

### What the layer adds up to

Four people committed against a demand of 4.5 to 6.0 leaves the team short by 0.5 to 2.0 people,
most likely 1.2. The 1.2 splits into one whole person, which `amountOrigin` says is the business's
to change, and 0.2, which no headcount removes. The first query of
[the walk](../sqlc/README.md) works it out from this document.
