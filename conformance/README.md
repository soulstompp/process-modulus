# Conformance profiles

**There is nothing here yet, and that is deliberate.** A profile should follow a real
adopter rather than precede one. This file explains what a profile is, what it may and may
not do, and which of the model's rules a validator cannot reach on its own.

Adopting is a separate question from conforming, and it has its own file.
[`adoption.md`](adoption.md) describes what breaking the `BorrowedTerm` and `Absence` rules
looks like from inside a corpus that already exists, because an adopter cannot act on a
rule they do not recognise themselves breaking.

## What a profile is for

The base schema carries values it does not own as `BorrowedTerm { taxonomy, value }`, with
the taxonomy required. It cannot validate the value, because most accounting vocabulary has
its authority in standards text rather than in a published enumeration. `historicalCost`
and `fairValue` are defined in ASC 820 and IFRS 13 as prose, and an XBRL taxonomy publishes
concepts rather than a list of measurement bases.

A conformance profile is a second schema that imports the base and narrows it for one
regime, for documents that claim that regime.

## A profile is keyed to a pair, never to a country

A profile narrows one `(authority, framework)` pair, because the same framework is coded
differently by different authorities. Portugal is the worked case. A microentity is `NC-ME`
to IES's `AnexoASNC` and `M` to the SAF-T referencial, and since `S` covers both `NCRF` and
`NCRF-PE`, the SAF-T code cannot be mapped back.

So a `pt` profile is not a thing. `pt-ies-anexo-asnc` and `pt-saft-referencial` are two
profiles, and a document may legitimately declare both regimes.

## When a profile is possible

Only where the regime publishes an enumeration a schema can point at. Two look promising:

| regime | the enumeration |
|---|---|
| SAF-T PT | the referencial: `S`, `M`, `N`, `O` |
| IES | `AnexoASNC`: `NIC`, `NCRF`, `NCRF-PE`, `NC-ME` |

These two do not line up, which is the reason `taxonomy` is required in the first place. A
borrowed value without its taxonomy is genuinely ambiguous, not merely unattributed.

## The mechanism

`xs:union` combines simple types across a namespace boundary once the other schema is
imported. `schemaLocation` is a hint; the namespace is the identity.

```xml
<xs:import namespace="urn:regime" schemaLocation="regime.xsd"/>

<xs:simpleType name="BasisUnderThatRegime">
  <xs:union memberTypes="pm:ContributedBasis regime:Referencial"/>
</xs:simpleType>
```

`xs:union` is simple types only. Anything with sub-elements needs `xs:choice`, or a
substitution group if the extension should be possible without editing this repository,
which is the mechanism to reach for if adoption goes well.

## What a profile must not do

- **Restate the regime's list.** Import it. A copied enumeration is a fork that drifts with
  nothing here able to notice it has.
- **Relax the base.** A profile narrows what is valid. A document valid under a profile is
  valid under the base schema, and the reverse need not hold.
- **Become required.** The base schema stands alone. A sender with no profile still
  produces a truthful document, which is the whole point of naming the authority instead of
  validating against it.

### Where the regime publishes only prose

A profile for a regime whose vocabulary lives in standards text has nothing to
`xs:import`. Authoring the list is still legitimate, provided it is labelled as ours. Such a
profile publishes this project's reading of that standard, in this project's namespace,
citing theirs. That is falsifiable, and an accountant can point at a value we got wrong.

What it must never do is present that list as the regime's own. Where a regime does publish
a list, import it and never restate it.

## A profile is a gate. A cargo feature is not.

The crate may gate which profiles it compiles behind cargo features. It must never gate
what counts as conformant.

Cargo unifies features across the whole build graph. If one crate in the graph enables
`us-gaap` and another enables `pt-ncrf`, both get both, silently, and the widening happens
in somebody else's build where nobody here can see it. A narrowing expressed as a feature is
not a narrowing. Narrowing belongs in the validator, where it is per-document and visible.

Additive use is safe under the same rule. A multi-regime reader is legitimate and expected,
since one implementation may read Portuguese documents and US ones, so unification producing
a reader that accepts both is the correct outcome rather than a leak. Writing and judging
are what must not move.

## Which documents a profile is run against

The first question a profile run must answer is not whether a document conforms. It is
whether the document is one the profile applies to at all.

That question has four answers, and it did not before `Regime/framework` became a
`StatedBorrowedTerm`.

| the document | in the profile's population? |
|---|---|
| `framework/term` whose `(taxonomy, value)` matches the profile | **Yes.** Run it |
| `framework/absent reason="none"` | **No, positively.** Somebody looked, and the entity reports under no framework. The profile does not apply, and saying so is a finding about nothing |
| `framework/absent reason="unmeasured"` | **Unknown.** The entity reports under something and has not named it. It may or may not be this profile's |
| no `regime` element at all | **Unknown, and differently.** Nobody said anything. `regime` is optional and its absence is a real state, since a witness that is not an accounting model reports under no framework and must not be made to invent one |

All four are legitimate documents and all four validate, which is the point rather than a
problem. Membership is the profile's question and not the validator's, and a profile that
does not answer it deliberately will answer it by accident.

That was run rather than assumed: four coverage documents identical but for the regime
block, validated against `assertion.xsd`, all four accepted. The validator was proved able
to fail first, since deleting the required `framework` from the same document gives
*"Missing child element(s). Expected is one of ( jurisdiction, framework )."*

### The state that must not be folded into the others

**`unmeasured` is not `notApplicable`, and folding it there undoes the repair that made it
sayable.** `notApplicable` is a claim that the document is outside the population. For
`reason="none"` that claim is true and somebody established it. For `reason="unmeasured"`
nobody established it. Skipping the document asserts it is outside, running it asserts it is
inside, and both are facts nobody has.

`Regime/framework` gained its wrapper precisely so that `none` and `unmeasured` would stop
sharing one encoding at the root of interpretation. Merging them again at the point where
documents are selected does not fix the defect. It moves the defect out of the schema and
into the thing that consumes the schema, where no validator can see it.

The failure that produces is invisible, which is the expensive kind. A corpus whose entity
tier is deliberately unfiled is in a legitimate and common state, and one of the cases the
wrapper was built for. It would be silently outside every profile's population, and its
report would read as nothing to see here when the truth is that the corpus has not yet said
what it reports under. Avoiding a deficiency that does not exist is right, and it must not
be bought by producing a conformance report that does not exist.

### What a profile run should report

Three counts rather than two, plus the fourth state named separately.

| | |
|---|---|
| **conformant** | in the population, and the narrowed rules hold |
| **non-conformant** | in the population, and they do not |
| **membership unestablished** | `framework` absent `unmeasured`, so the profile could not ask |
| *(reported beside, not inside)* | `framework` absent `none`, and no `regime` at all. Out of population, and the two are distinct |

A run that reports two numbers has already made a claim about the third. Reporting it as its
own line costs nothing and is the only version a reader can act on, because "forty documents
did not conform" and "forty documents never said what they report under" call for completely
different work.

In one line: **a profile answers `notApplicable` only where a document has positively
declined the framework. Where the framework is merely unnamed, the profile's own answer is
that it could not ask.** `assertion.xsd` already carries a word for that shape at the answer
level, which is `cannotAsk`, and reusing the existing word is better than minting one.

### What this does not decide

- **Whether a profile may narrow a document that declares several regimes**, only one of
  which it matches. `regime` is unbounded and declaring two codings of one framework is
  correct rather than duplicated, so this arrives as soon as a second profile exists.
- **Whether a profile may narrow on `chart` as well as `framework`.** The type question is
  settled, since `chart` is a required `StatedBorrowedTerm` and has the same four states
  `framework` does, so the table above transfers unchanged. What is not settled is the
  fourth row for a self-authored chart. An entity that is its own charting authority has
  positively named a chart, so it is neither unestablished nor declined. It is outside a
  national profile's population while being fully stated, which is a fifth state no other
  element has. A profile reporting it as non-conformant would report a deficiency that does
  not exist, and one reporting it as unestablished would lose a fact the document carries.

## What a validator cannot reach, and an implementer therefore still owes

XSD 1.0 has no `xs:assert` and cannot compare across elements. Eight rules in this model are
stated in the schemas' own prose and gated by nothing. Six of them carry the marker
`NOT REACHABLE BY A VALIDATOR` at the annotation that states it, so a reader can tell a
binding rule from an unenforced one. The two `dependence` rows marked below with an asterisk
are stated in prose without that marker, which is a gap in the marking rather than in the
reasoning.

| the rule | where |
|---|---|
| a `Claim`'s bounds satisfy `low` <= `mostLikely` <= `high` | `Claim` |
| the expected value is derived and must not be carried | `Claim` |
| a quantum's `size` is expressed in the demand unit of its layer | `LumpyQuantum` |
| a supply with `admitsInterference = false` and an interference fit must hold it as `customer` or `unrealised` | `Fit` |
| a `dependence` end's filing exists, and the layer named is in it | `FiledLayer` (`assertion.xsd`) |
| a `dependence` end's `version` names the edition actually read \* | `FiledLayer` (`assertion.xsd`) |
| a `dependence` entry's two ends are not the same filing *and* the same layer | `DependenceEntry` (`assertion.xsd`) |
| a `dependence` witness is not the filer of both ends, since if they are, the observation belongs in `pm:Coupling` \* | `Dependence` (`assertion.xsd`) |

The four `dependence` rows are not a weakness of that design. They are the reason it is a
separate document. An XSD identity constraint is scoped to one document, so a keyref that
appeared to reach across a filing boundary would validate by not being checked, which is a
reference that looks constrained and is not. An implementer that can fetch the other filing
owes the first two checks. One that cannot owes the reader the knowledge that it did not
happen, which is the difference between an unresolvable reference and an unchecked one.

A fifth rule became checkable when `Regime/chart` landed: an answer whose `holds` names a
taxonomy other than the declared `chart` is a finding. It could not be stated before,
because there was nowhere for the expected value to live, so the rule was satisfiable by
carrying any chart at all. It is now checked for the documents in this repository by
`every_position_is_held_in_a_chart_its_own_document_declares` in `tests/coverage_parse.rs`,
which was proved able to fail before its pass was believed. That is not the same as
discharging the rule, since the crate can only answer for documents it can read and a
profile still owes it for every document it has never seen. It applies to `holds` only and
never to `refuses`, because a refusal code comes from a coding pack that is deliberately
shared across regimes.

### The decision about Schematron, written down rather than left silent

Schematron is the correct long answer. It is the standard companion to XSD 1.0 and sits
beside the schema rather than inside it, so it costs the schema nothing. But it is a second
artifact with its own toolchain, and an adopter who will not run this crate's tests will not
run Schematron either.

So: not yet, deliberately, which is consistent with this file's own rule that a profile
should follow a real adopter. What was not acceptable was the silence, where a rule read as
binding and was not and nothing told a sender which of the two they were looking at. The
markers close that half at the cost of one clause per rule.
