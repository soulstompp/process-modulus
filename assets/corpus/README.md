# `assets/corpus/`: what a filing looks like, and the one layer the whole model exists for

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

Every document here is a claim about a business: a demand somebody observed, a supply somebody
committed, a remainder somebody bore. The figures are illustrative rather than anybody's real
numbers, and that changes nothing about what the documents are, which is filings.

⛔ **The directory next door holds the other kind.** [`assets/fixtures/`](../fixtures/) is one
document per state the schema admits, and it argues the difference in full rather than having it
restated here. The short version: a dark state in this directory is a finding about the evidence,
and a dark state in that one is a defect.

## The documents

Five root elements appear, because a claim *about* a filing is not itself a filing.

| file | root | what it files |
|---|---|---|
| [`enterprise-contract.xml`](enterprise-contract.xml) | `pm:processModulus` | Four layers and two operations. The layer read below is this one |
| [`contrato-empresarial.xml`](contrato-empresarial.xml) | `pm:processModulus` | The same four layers declared in Portuguese by a microentity under the IES `AnexoASNC` |
| [`unstated.xml`](unstated.xml) | `pm:processModulus` | Everything a sender may legitimately decline, each with the reason attached |
| [`refutation.xml`](refutation.xml) | `pm:processModulus` | Two counter-examples to the model, filed in the model's own format |
| [`merge-us-member.xml`](merge-us-member.xml) · [`merge-pt-member.xml`](merge-pt-member.xml) | `pm:processModulus` | Two honest filings that no heuristic can merge. Neither is interesting alone |
| [`merge-group-composition.xml`](merge-group-composition.xml) | `asrt:composition` | The repair, filed by neither member: what the parent treated as one layer, and why |
| [`merge-holding-composition.xml`](merge-holding-composition.xml) | `asrt:composition` | The second level, which is what makes compositions nest |
| [`dependence-group-consolidation.xml`](dependence-group-consolidation.xml) | `asrt:dependence` | A dependence between two filings, filed by the filer of neither |
| [`coverage-us-gaap.xml`](coverage-us-gaap.xml) · [`coverage-pt-ncrf-pe.xml`](coverage-pt-ncrf-pe.xml) | `asrt:coverage` | The same questions answered under two regimes, so the answers are comparable key by key |
| [`run-2026-08-30.xml`](run-2026-08-30.xml) | `asrt:run` | A run promoted to evidence: the dated extract a report cites |

Each document opens with a comment saying what it is for. That comment is the entry above, and
the file is where it is authoritative.

## Reading one layer, which is the whole model

The `labour` layer of [`enterprise-contract.xml`](enterprise-contract.xml). Three facts, and
everything else follows from them:

```
demand    between 4.5 and 6.0 people, most likely 5.2
supply    4 people
the unit  1 person, and it does not divide
```

### The demand, and two facts that travel beside the range

```xml
<pm:demand>
  <pm:amount>
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
      ...
    </pm:claim>
  </pm:amount>
</pm:demand>
```

`narrowsWhen` is what would have to change for the range to **tighten**, and `kind` says whether
that is a measurement arriving or the process itself changing. Not knowing and genuinely varying
are different conditions and only the first one gets better by looking harder.

`boundOrigin` is **who owns the edge**. `none` here says somebody looked and nobody owns it,
because this range is where twelve months of observations fell rather than where a rule put them.
A demand bounded by a contract would answer `contractual`, and that is a lever somebody could
pull.

### The supply, where the unit lives

```xml
<pm:nameplate>
  <pm:amount>
    <pm:claim>
      <pm:low>4</pm:low><pm:mostLikely>4</pm:mostLikely><pm:high>4</pm:high>
      <pm:unit>people</pm:unit>
      <pm:boundOrigin>
        <pm:derivation>
          <pm:identity>amountOrigin</pm:identity>
          <pm:note>`Nameplate/amountOrigin` says who could have held a different
                   number of these, one element over</pm:note>
        </pm:derivation>
      </pm:boundOrigin>
    </pm:claim>
  </pm:amount>

  <!-- the establishment is ours to set, so the one-person shortfall below
       is a decision rather than a constraint -->
  <pm:amountOrigin><pm:origin>policy</pm:origin></pm:amountOrigin>

  <pm:divisibility><pm:divisibility>
    <pm:lumpy>
      <pm:size><pm:claim>
        <pm:low>1</pm:low><pm:mostLikely>1</pm:mostLikely><pm:high>1</pm:high>
        <pm:unit>people</pm:unit>
      </pm:claim></pm:size>
      <pm:origin>intrinsic</pm:origin>
    </pm:lumpy>
    <pm:window>
      <pm:absent>
        <pm:reason>notApplicable</pm:reason>
        <pm:note>the nameplate is quoted in `people`, a stock with no period, so there
                 is no cycle to be live in part of</pm:note>
      </pm:absent>
    </pm:window>
  </pm:divisibility></pm:divisibility>
</pm:nameplate>
```

⭐⭐ **Two origins, and keeping them apart is the point of the element.** `origin` is who you
would have to talk to in order to change the **size of one unit**, and `intrinsic` means nobody,
because one person is one person. `amountOrigin` is who you would have to talk to in order to hold
**a different number of them**, and `policy` means the filer, because the establishment is theirs
to set.

⭐ Those two are also why the claims answer `boundOrigin` with a **derivation** naming the
identity rather than repeating themselves. The question *who owns this edge* is answered one
element over, and a document that answered it twice would eventually answer it two different ways.
A `derivation` is not an absence: it says the value is computable and names what computes it.

`window` is the other half of divisibility. Not how the supply divides in **amount** but how it
divides in **time**: a line running five days of seven, a machine stopped two hours a day. A
headcount has no such cycle, so the answer says which of the alternatives is meant rather than
leaving a blank.

### What give each buffer has

```xml
<pm:capacitySlack>
  <pm:absent>
    <pm:reason>unmeasured</pm:reason>
    <pm:note>a person can work above their rating. HOW FAR ABOVE, and for how long,
             nobody here has measured</pm:note>
  </pm:absent>
</pm:capacitySlack>
<pm:inventorySlack>
  <pm:claim>
    <pm:low>0</pm:low><pm:mostLikely>0</pm:mostLikely><pm:high>0</pm:high>
    <pm:unit>people</pm:unit>
    <pm:provenance>
      <pm:party>platform</pm:party>
      <pm:note>capacity not used today is GONE. Last week's unused hours cannot be
               stockpiled to serve this week</pm:note>
    </pm:provenance>
  </pm:claim>
</pm:inventorySlack>
```

⛔ **A measured zero is a CLAIM here and never an absence.** It carries a unit, an owner and a
provenance, and the absence arm has nowhere to put any of the three. `[0, 0, 0]` says somebody
checked and the answer is nothing; `unmeasured` says nobody checked. They are opposite statements
and a bare empty element spells them the same way.

### The other face of the supply, which is what actually happened

```xml
<pm:jagged>
  <pm:draw>
    <pm:absent>
      <pm:reason>unmeasured</pm:reason>
      <pm:note>no instrument records hours absorbed above the establishment</pm:note>
      <pm:provenance><pm:party>platform</pm:party> ... </pm:provenance>
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
```

⭐ **The two absences carry different reasons and a receiver must not merge them.** The draw is
`unmeasured`: an instrument could exist and does not. The measurement basis is `notApplicable`:
asking the question is malformed here, because a headcount has no valuation to have a basis for.
A receiver treating the second as a gap would report a deficiency that does not exist.

### The remainder, which is the conclusion

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

The fit is `interference` in the mechanical sense borrowed from ISO 286: it works by deforming the
material, and inspecting the output will not reveal it. The absorber is Hopp and Spearman's
`capacity` buffer, cited to their taxonomy rather than restated in this namespace.

⛔⛔ **Note which of the two things is absent, because it is not the one people expect.** The
remainder's SIZE is a derivation: the document determines it and a receiver computes it. What no
instrument reaches is the **share**, how much of the gap the team absorbed rather than turned
away. That is a much smaller and much sharper admission than *we do not know the remainder*.

⭐ And the second holder is what this layer's own `timeSlack` note asks for. Work that queues,
waits and quietly ages out is `unrealised` and not `people`. Filing only `people` would have said
the team absorbed all of it, which the same layer contradicts a few elements above.

### What the layer adds up to

```
|nameplate - demand|  =  |4 - [4.5, 5.2, 6.0]|  =  [0.5, 1.2, 2.0] people
```

and at the mode that 1.2 divides, exactly and in one way:

| | | |
|---|---|---|
| **1 person** | a whole unit, and **a decision** | hire one more and it moves. `amountOrigin` says the establishment is the filer's to set |
| **0.2 of a person** | the residue, and **not a decision** | no headcount removes it. Four people leave 0.2 short and five leave 0.8 spare |

⭐⭐⭐ **That 0.2 is the subject.** Nobody bought it, so no transaction records it, so no system
that starts from transactions can see it. This document says it exists, says who carried it, says
that nobody measured how the two carriers split it, and says who stands behind that statement.

One layer, and it is the whole model.
