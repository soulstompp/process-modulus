# Conformance profiles

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

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
citing theirs. That is falsifiable, and an accountant can point at a value it gets wrong.

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
| `framework/absent/reason = none` | **No, positively.** Somebody looked, and the entity reports under no framework. The profile does not apply, and saying so is a finding about nothing |
| `framework/absent/reason = unmeasured` | **Unknown.** The entity reports under something and has not named it. It may or may not be this profile's |
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

XSD 1.0 has no `xs:assert` and cannot compare across elements, so the rules below are stated in
the schemas' own prose and gated by nothing. Most carry the marker `NOT REACHABLE BY A
VALIDATOR` at the annotation that states them, so a reader can tell a binding rule from an
unenforced one; the rows marked with an asterisk do not, which is a gap in the marking rather
than in the reasoning.

⛔ **This paragraph does not count them, and a count here is a number nobody recounts.** The
table is the only thing that knows how many rows it has. `tests/conformance.rs` holds this
table and its Portuguese twin to the same length, the same asterisks and the same third column,
because unheld they drift, and an implementer who reads one document is owed what the other
one owes.

⭐⭐⭐ **NO RULE HERE IS A NEW IDEA, AND SEVERAL ARE REACHABLE ONLY BECAUSE THE STATE THEY TURN
ON HAS A NAME.** Where a state is encoded as a blank — an empty list, a missing element, an
omitted enumeration — there is no reason to group by, and the rule stays prose however plainly
it is written. Five two-valued encodings say which of their three or four states they mean, and
that is what makes the rules under them reachable rather than adding any. ⛔ A composed layer
that drops its part's duty cycle is byte-identical to one that runs seven days a week, which is
what the window carry-through rule is for.

⭐⭐ **THE THIRD COLUMN NAMES THE CHECK THAT RUNS THE RULE, AND EMPTY MEANS IT IS STILL ONLY
OWED.** [`assets/sqlc/checks/roster.sqlc`](../assets/sqlc/checks/roster.sqlc) carries one row
per rule that runs, with the sentence it enforces, and every slug in that column is one of
its slugs. ⛔ `tests/conformance.rs` anti-joins the two in BOTH directions, so a rule that
starts running and is not written down here fails the build, and so does a slug here that no
longer names a check. A rule can be enforced and undocumented, or documented and gone, and
this join is the only thing that reads a prose table against a relation.
[`assets/sql/rules.sql`](../assets/sql/rules.sql) expresses them as one query over the corpus
loaded into Postgres, and an empty result means every one of them held. That includes the rule
no validator can see in principle: *no leaf layer is reachable through two paths* needs a
recursive walk across documents, and the second path runs through a filing the first does not
contain.

**It does not discharge the rules; it discharges them FOR THIS CORPUS.** An adopter runs the
same file against their own filings, which is the point of shipping it. And the query reports how
many rows each rule examined, because thin coverage is the failure mode here — almost nothing in
the corpus files a numeric slack, and a bound with nothing to bound passes loudest.
[`assets/sql/reports/coverage.sql`](../assets/sql/reports/coverage.sql) prints the verdict per
rule, `ok` against `⚠️ thin` against ⛔ `VACUOUS`, and a rule that examined nothing is **left
saying so rather than quietly counted as passing**. The counts are not repeated here: this
document and its Portuguese twin last carried two DIFFERENT answers to the same question, which
is what a number in prose does.

⛔ What SQL still cannot reach is prose against data: whether a coupling's `observed` describes a
real observation, whether a `narrowsWhen` names something that would actually narrow the range,
whether a note claiming a portion is `unrealised` agrees with the holder list beside it. Those
remain owed by a person.

⛔ **Two rows in this table can disagree about what `clearance` means, and the third `Fit`
member is what settles it.** Read as *"under an interference fit"* it is the `sign` value, a
comparison at `mostLikely`. Read as *"clearance **across the whole demand range**"* it is a
comparison of two ranges, which a two-member enumeration has to spell out in prose because it
has no name for its answer. That prose IS ISO 286's own criterion, already load-bearing here.
With `transition` filed the qualifier is redundant, so the row is shorter rather than longer.

**Two rows left this table by being subsumed rather than dropped.** *`absorber = inventory`
requires `admitsInventory = true`* and its `time` twin were availability gates on a boolean;
the slack rule below is strictly stronger, because a buffer whose slack is a measured zero
fails it for any positive share, and a buffer with a sized slack is now bounded as well as
permitted.

| the rule | where |
|---|---|---|
| a `Claim`'s bounds satisfy `low` <= `mostLikely` <= `high` | `Claim` | |
| the expected value is derived and must not be carried | `Claim` | |
| a quantum's `size` is expressed in the unit of the nameplate it divides | `LumpyQuantum` | `quantum_unit_mismatch` |
| a supply whose `capacitySlack` is a measured zero, under an interference fit, must hold it as `customer` or `unrealised`, across every holder | `Fit` | `nobody_named_as_unserved` |
| the same supply under a TRANSITION fit names at least one `customer` or `unrealised` holder, presence rather than universality, because part of the range is legitimately clearance | `Fit` | `nobody_named_as_unserved` |
| `max(0, demand.high - nameplate.low)` does not exceed `capacitySlack.high` plus the unserved shares' highs, evaluated at that one corner | `Nameplate` | `exposure_unaccounted` |
| a draw does not exceed the nameplate plus the capacity slack the supply filed, since a supply cannot serve more than it can make | `Jagged`, `Nameplate` | `draw_exceeds_the_supply` |
| the `nameplate` is a whole multiple of the quantum, for a lumpy supply | `Remainder` | `nameplate_not_a_multiple` |
| `quantity` is `derived` wherever demand, nameplate and the quantum are all stated | `Remainder` | |
| a `clearance` fit rules out `customer` and `unrealised`, the value now meaning across the whole range | `Remainder` | `clearance_with_unserved` |
| a layer denying it has a remainder is not contradicted by its own demand and nameplate, which between them derive one | `StatedRemainder` | `denied_remainder_is_not_contradicted` |
| `sign` agrees with the RANGE comparison — `clearance` where `nameplate.low` >= `demand.high`, `interference` where `nameplate.high` <= `demand.low`, `transition` where they overlap | `Fit` | `fit_disagrees` |
| the stated `share`s sum to `\|nameplate - demand\|`, wherever every share is stated | `Holder` | `shares_do_not_sum` |
| a holder `kind` appears at most once per remainder | `Holder` | |
| a `dependence` end's filing exists, and the layer named is in it | `FiledLayer` (`assertion.xsd`) | |
| a `dependence` end's `version` names the edition actually read \* | `FiledLayer` (`assertion.xsd`) | |
| a `dependence` entry's two ends are not the same filing *and* the same layer | `DependenceEntry` (`assertion.xsd`) | |
| a `dependence` witness is not the filer of both ends, since if they are, the observation belongs in `pm:Coupling` \* | `Dependence` (`assertion.xsd`) | |
| a part's `filing` resolves to a filing that is in the corpus, and to a layer in it | `FiledLayer` (`assertion.xsd`) | `unresolved_part` |
| a LOCAL part, whose notation is its own composition's, names a layer in that document's own stack | `FiledLayer` (`assertion.xsd`) | `local_part_dangles` |
| layers that always move together are one layer, so a part cycle among them fails the definition of a layer rather than naming an edge to break | `Layer`, `FiledLayer` (`assertion.xsd`) | `layers_move_together` |
| a composed layer's claim equals `Σ parts - Σ eliminations`, per quantity | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| an elimination subtracts component-wise and does NOT reverse bounds | `Elimination` (`assertion.xsd`) | |
| a fusion's parts are fungible, so their remainders may offset | `Fusion` (`assertion.xsd`) | |
| `party` and `asOf` appear only on a `counterparty` holder | `Holder` | |
| a `counterparty` holder names its `party`, and should carry `asOf` | `Holder` | |
| a coupling propagates through a fusion and ATTENUATES, bounded by the part's share of the layer it was fused into | `Coupling` | `coupling_does_not_attenuate` |
| a fusion that absorbs a coupling between its own parts says so, and never cites it as evidence | `Coupling` | |
| no leaf layer is reachable through two paths, once compositions nest | `composition` (`assertion.xsd`) | `jagged_layer` |
| a holder's share does not exceed the slack of the buffer its `absorber` names, on the interference side, with `unrealised` exempt | `Nameplate`, `Layer` | `share_exceeds_slack` |
| a fused layer's slack is bounded by the SUM of its parts', and one unsized part makes that bound unsized | `Nameplate`, `Layer` | |
| a part's `factor` converts into the composed layer's unit, and is absent exactly when they already agree | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| a `factor` is strictly positive, so the interval product is component-wise | `Part` (`assertion.xsd`) | |
| an elimination is stated in the composed unit, AFTER conversion | `Part` (`assertion.xsd`) | |
| a converted part's remainder is converted directly and never re-derived from its converted nameplate and demand | `Part` (`assertion.xsd`) | |
| a `composition` and a `dependence` filed by one consolidator about one consolidation agree about witness, date and regime | `Dependence` (`assertion.xsd`) | |
| a part crossing a regime boundary files the instrument that reconciles it, as a part crossing a unit boundary files the factor | `Composition` (`assertion.xsd`) | `regime_crossing_without_a_citation` |
| a composer's `regime` for a part is one that part's own filing declares, which is a claim about the other document and outside any keyref's reach | `FiledLayer` (`assertion.xsd`) | `part_regime_disagrees` |
| a slack is expressed in the unit of the shares it bounds | `Nameplate`, `Layer` | `slack_unit_mismatch` |
| a slack measured as a duration is converted before filing, by `quantity = duration x rate` | `Nameplate`, `Layer` | |
| a unit's denominator covers at least one whole duty cycle of the supply it measures | `Claim` | |
| `timeSlack` is `derived` only where the layer runs the WHOLE of its period, filed as a window of one whole period in the period's own unit | `Layer` | `derived_slack_over_a_window` |
| a claim filing `boundOrigin` as `derived` sits beside a sibling element that states the author — `Nameplate/amountOrigin` or `LumpyQuantum/origin` — so the pointer resolves | `Claim` | |
| a point value files `narrowsWhen` as `notApplicable`, having no width to tighten | `Claim` | `narrows_a_point_value` |
| a claim that spans a width does not file `narrowsWhen` as `notApplicable` | `Claim` | `range_says_no_range` |
| a point value does not file `boundOrigin` absent `none`, since that reason says the bound is where the measurements fell and nothing fell anywhere | `Claim` | `bound_fell_with_no_range` |
| a `window` is the ON-duration, one per period of the nameplate's unit, and never the gap | `Divisibility` | |
| a `window` requires the nameplate's unit to name a period, since it is the live part of that denominator | `Divisibility` | |
| a `window` is CARRIED through a fusion and never summed: it is a property of the machine, not a quantity | `Divisibility` | `window_lost_or_summed` |
| a layer filing a `window`, OR filing its absence as `unmeasured`, must not file `timeSlack` as `derived`, because in neither case is the spare known to be spread evenly across the period | `Divisibility`, `Layer` | `derived_slack_over_a_window` |
| a `window` filed as `notApplicable` sits on a unit with no denominator, since a unit that names a period can be answered | `Divisibility` | `window_not_applicable_on_a_rate` |
| a fusion filing `eliminations` as `none` or `notApplicable` owes an EXACT sum: the composed figure equals `Σ` converted parts. Filing it as `unmeasured` suspends the check rather than passing it | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| a fusion filing `eliminations` as `notApplicable` has exactly one part, since between a set of one nothing can be counted twice | `Fusion` (`assertion.xsd`) | `elimination_not_applicable_with_parts` |
| a fusion of ONE part that eliminates nothing carries that part unchanged, in every quantity the layer files and not only its demand | `Fusion` (`assertion.xsd`) | `one_part_fusion_alters_its_part` |
| a part whose unit differs from the layer it is composed into files what converts it, even where the conversion is one, because then somebody is asserting the two units interchange | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| converting a quantity round a cycle of units returns what it started with: one lies inside the product of the factors round the cycle | `Part` (`assertion.xsd`) | `conversion_cycle_does_not_close` |
| a layer restated by a second filing that claims to carry it through unchanged agrees with the first, `absorber` included \* | `composition` (`assertion.xsd`) | |

The four `dependence` rows are not a weakness of that design. They are the reason it is a
separate document. An XSD identity constraint is scoped to one document, so a keyref that
appeared to reach across a filing boundary would validate by not being checked, which is a
reference that looks constrained and is not. An implementer that can fetch the other filing
owes the first two checks. One that cannot owes the reader the knowledge that it did not
happen, which is the difference between an unresolvable reference and an unchecked one.

The three `composition` rows split three ways, and collapsing them would lose the reason each
is unenforced. The first is ordinary cross-filing arithmetic: an implementer that can fetch the
member filings owes it, and `tests/composition.rs` discharges it for the three documents in this
repository. The second is reachable in principle and simply beyond XSD 1.0, and it is the one
most likely to be got wrong quietly, because subtracting with the wrong bound convention still
yields a well-formed interval. The third **is not owed by anybody and never will be**: whether
two members' people can cover for each other is a judgement, not a computation, and a checker
that tried to settle it would be asserting something no document contains.

The two `Holder` rows are one rule with two halves, and only the negative one is easy to
write: `party`/`asOf` belong to `counterparty` and to nothing else. The positive half is **a
counterparty holder must name its party**, because a burden asserted to sit in another
entity's books with nobody named is a guess wearing the one holder kind that promises an
instrument. The rule is easiest to break in a consolidation, where a `booked` share really
is booked in some member's books and naming which one looks exactly like what `party` is for.
It is not: on a counterparty holder `party` names whose OTHER books carry the burden. Two
relations, one field. `tests/corpus_parse.rs` now checks both halves for every holder in
every filing in `assets/corpus/`, compositions unwrapped — which is where the violation that
prompted the rows was found.

The two `Coupling` rows are what happens when a coupling meets a fusion one level up, and
they exist because `asrt:composition` nests. ⛔ Neither says a coupling is evidence for a
fusion, and that is deliberate: **coupling and fungibility are independent axes**, and the
documents in this repository populate both off-diagonal cells. Two delivery teams in two
countries are one layer and not coupled at all. A delivery team and an out-of-hours rota are
tightly coupled and are two layers, because an engineer on the rota delivers no features. A
fusion citing a coupling as its justification would be answering a different question from
the one it was asked.

⭐ The same holds one axis over, for fungibility against DOUBLE COUNTING. A fusion's nameplate
elimination is how much supply its parts counted in common, and the documents here now populate
that scale end to end: a stated `[0, 0, 0]` at `merge-group-composition`'s `labour`, a whole part
at its `shift-line`, and the middle at `assets/fixtures/every-partial-elimination.xml`. ⛔ The
bottom of that scale is a CLAIM of zero and not `absent/reason = none`: an elimination's
`quantity` is a `pm:StatedClaim`, whose reasons are `{unmeasured, notApplicable, derived}`, and
`none` is not in the type. The parts are
fungible at all three. An elimination is no more evidence for a kind of fusion than a coupling
is evidence for a fusion at all.

The `composition` row is a guarantee that weakens with depth, which makes it the one most
worth stating. `partIdentity` is an `xs:key` and it is COMPLETE while every part is a leaf;
at two levels it is not, because a holding naming both `group#labour` and `member#labour`
has two distinct notation/id pairs and the member's layer is consolidated twice. The
transitive check requires fetching the chain, and the fetch is not uniform: a layer sits one
element deeper inside a composition than inside a plain filing, and `notation` says which is
which nowhere, so a resolver reads the root element.

⛔ A FOURTH LIMIT IS DELIBERATELY ABSENT FROM THE TABLE, because listing it would imply
somebody owes it. The units of a fusion's parts are NOT checked and must not be: the parts
legitimately spell one unit two ways — `people` and `pessoas` — and asserting that they name
one unit IS WHAT A FUSION SAYS. A checker demanding string equality would reject the case the
type exists for. That is a limit of the world, not a debt of the implementer.

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

### The decomposition rules are arithmetic, which makes them a different kind

The rules that arrived with `Remainder`'s decomposition are not prose conventions. They are
arithmetic over values the document already carries, so an implementer discharges them by
computing rather than by reading:

```
m       = nameplate / q  - floor(demand / q)
residue = demand mod q
r       = m*q - residue           and, always,  r ≡ -demand  (mod q)
```

⛔⛔ **THE TOTAL IS AN IDENTITY AND THE SPLIT IS NOT, AND THE BLOCK ABOVE READS AS THOUGH BOTH
WERE.** Substituting `k = nameplate/q` shows the floors cancel outright:

```
r = (n/q − ⌊d/q⌋)·q − (d − ⌊d/q⌋·q) = n − d
```

So `r` is exact for **any** demand and **any** nameplate, interval or not — `⌊⌋` appears twice
with opposite signs and never has to resolve. But `demand mod q` is a **sawtooth**, so
evaluated at a demand range's three points it need not be ordered at all: `(4.5, 5.2, 6.7)` at
`q = 1` gives residues `(0.5, 0.2, 0.7)`, which violates `low ≤ mostLikely ≤ high` — the first
rule in the table above — while the demand that produced it is perfectly well formed. **Lumpy
layers in `assets/corpus/` are in that state today**, `refutation.xml`'s `compute` at
`(3.0, 5.2, 0.4)` among them. `cargo run --example matrices` counts them against the lumpy
total, in its residue census.

**The schema is already safe and the reasoning for it was simply never written down.**
`Remainder` carries `quantity`, `sign`, `absorber` and `holder` — the total, and never the two
components. **Read this block as an implementer's derivation of `r`, never as a filing
instruction for `m·q` and `residue`,** which are not `Claim`s in the general case.
`the_decomposition_is_an_identity_and_its_two_halves_are_not_claims` in
[`tests/corpus_parse.rs`](../tests/corpus_parse.rs) discharges both halves.

`tests/corpus_parse.rs` discharges the share-sum rule for the documents here, in
`an_unserved_excess_splits_across_two_holders_that_sum_to_the_magnitude`, and it was proved
able to fail before its pass was believed: perturbing one share by a single launch gives
`left: (3.0, 3.0, 5.0)` against `right: (2.0, 3.0, 5.0)`. That is not the same as
discharging the rule, for the reason the chart rule is not discharged either — this crate
answers only for documents it can read.

The consolidation rule joins that family and is discharged the same way, in
`tests/composition.rs`, by `the_fused_demand_reconciles_with_its_parts_less_the_eliminations`. It
too was proved able to fail first: moving the composed labour demand by one tenth reports
`the composed demand is (10.4, 11.6, 13.0) and its parts less their eliminations are
(10.4, 11.5, 13.0)`. TWO THINGS MAKE IT HARDER THAN THE OTHERS AND BOTH BELONG TO
WHOEVER RUNS IT. The parts are in OTHER DOCUMENTS, so the check needs a catalogue mapping
each `filing/notation` to something fetchable, and that catalogue is the receiver's, never
the sender's. And the comparison CANNOT BE EXACT: `Claim` holds `f64`, `10.0 - 10.4` is
`-0.40000000000000036`, and 7,168 of the 39,601 one-decimal pairs below 20 fail an exact
`==` against their own sum. A tolerance is a policy number, which is why it is stated here
and left to the profile rather than fixed in the model.

⛔ AND AN UNSIZED ELIMINATION MAKES THE SUM UNCOMPUTABLE RATHER THAN SATISFIED. A checker
that read an `unmeasured` elimination as zero would find the layer reconciling exactly and
report success about a figure it has been told is overstated. `unchecked` is a third state
and folding it into `checked and passed` is the failure this whole file is about. The zero is
the opposite case, and it is a CLAIM rather than an absence: an elimination that sizes to
nothing is filed `[0, 0, 0]`, because `Elimination/quantity` is a `pm:StatedClaim` and
`pm:ClaimAbsenceReason` has no `none` for it to hide in. `none` on the `eliminations` wrapper
says a different thing again, that the composer searched and found no double counting at all,
and that leaves the sum EXACT.

### The decision about Schematron, written down rather than left silent

Schematron is the correct long answer. It is the standard companion to XSD 1.0 and sits
beside the schema rather than inside it, so it costs the schema nothing. But it is a second
artifact with its own toolchain, and an adopter who will not run this crate's tests will not
run Schematron either.

So: not yet, deliberately, which is consistent with this file's own rule that a profile
should follow a real adopter. ⛔ What is not acceptable is silence, where a rule reads as
binding and is not and nothing tells a sender which of the two they are looking at. The
markers close that half at the cost of one clause per rule.
