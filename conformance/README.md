# `conformance/`: what a profile may narrow, and which rules no validator reaches at all

> **Também disponível em português europeu: [`pt-PT/conformance/README.md`](../pt-PT/conformance/README.md).**

There is no profile here yet, on purpose: a profile should follow a real adopter rather than come
before one. This page says what a profile is, what it may and may not do, and which of the model's
rules a validator cannot reach on its own.

Adopting is a separate question from conforming, and it has its own page.
[`adoption.md`](adoption.md) shows what breaking the `BorrowedTerm` and `Absence` rules looks like
from inside a corpus that already exists, because an adopter cannot fix what they do not recognise
themselves doing.

## What a profile is for

The schema carries values it does not own as `BorrowedTerm { taxonomy, value }`, with the taxonomy
required. It cannot validate the value, because most accounting vocabulary lives in standards text
rather than in a published list. `historicalCost` and `fairValue` are defined in prose by ASC 820
and IFRS 13, and an XBRL taxonomy publishes concepts rather than a list of measurement bases.

A conformance profile is a second schema that imports this one and narrows it for one regime, for
the documents that claim that regime.

## A profile is keyed to a pair, never to a country

A profile narrows one `(authority, framework)` pair, because different authorities code the same
framework differently. Portugal is the worked case. A microentity is `NC-ME` to the IES
`AnexoASNC` and `M` to the SAF-T referencial, and since `S` covers both `NCRF` and `NCRF-PE`, the
SAF-T code cannot be mapped back.

So there is no `pt` profile. `pt-ies-anexo-asnc` and `pt-saft-referencial` are two profiles, and a
document may declare both regimes.

## When a profile is possible

Only where the regime publishes a list a schema can point at. Two look promising:

| regime | the list |
|---|---|
| SAF-T PT | the referencial: `S`, `M`, `N`, `O` |
| IES | `AnexoASNC`: `NIC`, `NCRF`, `NCRF-PE`, `NC-ME` |

The two do not line up, which is why `taxonomy` is required in the first place. A borrowed value
without its taxonomy is ambiguous, not merely unattributed.

## How a profile is written

`xs:union` combines simple types across a namespace once the other schema is imported.
`schemaLocation` is a hint; the namespace is the identity.

```xml
<xs:import namespace="urn:regime" schemaLocation="regime.xsd"/>

<xs:simpleType name="BasisUnderThatRegime">
  <xs:union memberTypes="pm:ContributedBasis regime:Referencial"/>
</xs:simpleType>
```

`xs:union` takes simple types only. Anything with child elements needs `xs:choice`, or a
substitution group where the extension should be possible without editing this repository.

## What a profile must not do

- **Restate the regime's list.** Import it. A copied list drifts, with nothing here to notice.
- **Relax the base.** A profile narrows. A document valid under a profile is valid under the base
  schema, and the reverse need not hold.
- **Become required.** The base schema stands alone. A sender with no profile still files a
  truthful document, which is why the schema names the authority instead of validating against it.

Where a regime publishes only prose, a profile has nothing to import. Writing the list is still
legitimate, provided it is labelled as this project's reading of that standard, in this project's
namespace, citing theirs. An accountant can then point at a value it gets wrong. What it must never
do is present that list as the regime's own.

## A profile is a gate, and a cargo feature is not

The crate may gate which profiles it compiles behind cargo features. It must never gate what counts
as conformant. Cargo unifies features across the whole build, so if one crate enables `us-gaap` and
another `pt-ncrf`, both get both, silently, in somebody else's build. A narrowing expressed as a
feature is no narrowing. It belongs in the validator, per document, where it can be seen.

Reading several regimes is fine under the same rule: one implementation may well read Portuguese and
US documents. Writing and judging are what must not move.

## Which documents a profile is run against

Before asking whether a document conforms, a profile run asks whether the profile applies to it at
all. That question has four answers:

| the document | in the profile's population? |
|---|---|
| `framework/term` whose `(taxonomy, value)` matches the profile | **Yes.** Run it |
| `framework/absent/reason = none` | **No.** Somebody looked, and the entity reports under no framework |
| `framework/absent/reason = unmeasured` | **Unknown.** The entity reports under something and has not named it |
| no `regime` element at all | **Unknown, differently.** Nobody said anything. A witness that is not an accounting model reports under no framework and must not invent one |

All four are valid documents. Membership is the profile's question, not the validator's.

`unmeasured` is not `notApplicable`. `notApplicable` says the document is outside the population,
and for `none` somebody established that. For `unmeasured` nobody did, so skipping the document and
running it both assert facts nobody has. A corpus whose framework is not yet filed would otherwise
sit silently outside every profile, and its report would read as nothing to see.

A profile run therefore reports three counts, and names a fourth state beside them:

| | |
|---|---|
| **conformant** | in the population, and the narrowed rules hold |
| **non-conformant** | in the population, and they do not |
| **membership unestablished** | `framework` absent `unmeasured`, so the profile could not ask |
| *(beside, not inside)* | `framework` absent `none`, and no `regime` at all: out of the population, and distinct from each other |

"Forty documents did not conform" and "forty documents never said what they report under" call for
different work. Where the framework is merely unnamed, a profile's answer is that it could not ask,
and `assertion.xsd` already has the word for that: `cannotAsk`.

Two questions stay open until a second profile exists. One is whether a profile may narrow a
document that declares several regimes, only one of which it matches. The other is whether it may
narrow on `chart` as well as `framework`. `chart` has the same four states, but a self-authored
chart adds a fifth: positively named, and outside any national profile's population.

## What a validator cannot reach, and an implementer therefore still owes

XSD 1.0 cannot compare one element with another, so the rules below are stated in the schemas' own
prose and no validator gates them. Most sit under the heading `# What no validator reaches`, in the
type that states them. The rows marked with an asterisk do not, which is a gap in the marking.

The third column names the query that runs the rule, one row of
[`assets/sqlc/checks/roster.sqlc`](../assets/sqlc/checks/roster.sqlc). An empty third column means
the rule is still owed by an implementer. [`assets/sql/rules.sql`](../assets/sql/rules.sql) runs
every named rule over the corpus loaded into Postgres. It prints the rows that break one, then how
many rows each rule examined, because a rule that examined nothing has not passed.
[`assets/sql/reports/coverage.sql`](../assets/sql/reports/coverage.sql) gives each rule's verdict
on that: `ok`, thin, or vacuous. That includes the one rule no validator could see even in
principle, *no layer is counted through two paths*, whose second path runs through a filing the
first does not contain.

A clean run holds the rules for the documents loaded, and an adopter runs the same file over their
own. What no query reaches is prose against data. Does a coupling's `observed` describe a real
observation? Does a `narrowsWhen` name something that would actually narrow the range? Does a note
calling a portion `unrealised` agree with the holder list beside it? A person still owes those.

| the rule | where | the query |
|---|---|---|
| a range runs in order: `low`, then `mostLikely`, then `high` | `Claim` | |
| the expected value is worked out by the receiver and never filed | `Claim` | |
| a whole unit's `size` is in the unit of the nameplate it divides | `LumpyQuantum` | `quantum_unit_mismatch` |
| a supply whose three buffers are all stated empty, under an `interference` fit, holds the excess as `customer` or `unrealised`, in every holder | `Fit` | `nobody_named_as_unserved` |
| the same supply under a `transition` fit names at least one `customer` or `unrealised` holder, at least one rather than all, because part of the range is legitimately covered | `Fit` | `nobody_named_as_unserved` |
| the shortfall at its worst, the largest demand against the smallest nameplate, does not exceed the largest capacity slack plus the largest unserved shares | `Nameplate` | `exposure_unaccounted` |
| a draw does not exceed the nameplate plus the capacity slack the supply filed, since a supply cannot serve more than it can make | `Jagged`, `Nameplate` | `draw_exceeds_the_supply` |
| the `nameplate` is a whole number of whole units, for a lumpy supply | `Remainder` | `nameplate_not_a_multiple` |
| `quantity` may be filed as a `magnitude` derivation wherever the demand and the nameplate are both stated, and a stated `quantity` equals the gap between the nameplate and the demand | `Remainder` | `stated_quantity_is_not_the_magnitude` |
| a `clearance` fit, which holds across the whole range, rules out `customer` and `unrealised` | `Remainder` | `clearance_with_unserved` |
| a layer denying it has a remainder is not contradicted by its own demand and nameplate, which between them give one | `StatedRemainder` | `denied_remainder_is_not_contradicted` |
| `sign` agrees with the ranges: `clearance` where the smallest nameplate covers the largest demand, `interference` where the largest nameplate falls short of the smallest demand, `transition` where they overlap | `Fit` | `fit_disagrees` |
| the stated `share`s add up to the gap between the nameplate and the demand, wherever every share is stated | `Holder` | `shares_do_not_sum` |
| a `dependence` end's filing exists, and the layer named is in it | `FiledLayer` (`assertion.xsd`) | |
| a `dependence` end's `version` names the edition actually read | `FiledLayer` (`assertion.xsd`) | |
| a `dependence` entry's two ends are not the same filing and the same layer | `DependenceEntry` (`assertion.xsd`) | |
| a `dependence` witness is not the filer of both ends, since then the observation belongs in `pm:Coupling` | `Dependence` (`assertion.xsd`) | |
| a part's `filing` resolves to a filing that is in the corpus, and to a layer in it | `FiledLayer` (`assertion.xsd`) | `unresolved_part` |
| a local part, whose notation is its own composition's, names a layer in that document's own stack | `FiledLayer` (`assertion.xsd`) | `local_part_dangles` |
| layers that always move together are one layer, so parts composed round a loop among them are one layer filed as several, not a link to cut | `Layer`, `FiledLayer` (`assertion.xsd`) | `layers_move_together` |
| a composed layer's figure equals its parts added up, less what was eliminated, quantity by quantity | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| an elimination is taken low from low and high from high, except where that would leave the low above the high; there the low pairs with the elimination's high | `Elimination` (`assertion.xsd`) | `fusion_sum_disagrees` |
| a fusion's parts can stand in for each other, so their remainders may offset | `Fusion` (`assertion.xsd`) | |
| `party` and `asOf` appear only on a `counterparty` holder | `Holder` | |
| a `counterparty` holder names its `party`, and should carry `asOf` | `Holder` | |
| a coupling carries through a fusion and weakens there, bounded by the part's share of the layer it was fused into | `Coupling` | `coupling_does_not_attenuate` |
| a fusion that absorbs a coupling between its own parts says so, and never cites it as evidence | `Coupling` | |
| no layer is counted through two paths once compositions nest | `composition` (`assertion.xsd`) | `jagged_layer` |
| a holder's share does not exceed the slack of the buffer its `absorber` names, on the short side, with `customer` and `unrealised` exempt | `Nameplate`, `Layer` | `share_exceeds_slack` |
| a fused layer's slack is at most its parts' slacks added up, and one unsized part leaves that limit unsized | `Nameplate`, `Layer` | |
| a part's `factor` converts into the composed layer's unit, and is absent exactly when the two already agree | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| a `factor` is greater than zero, so a converted range keeps its low and its high in place | `Part` (`assertion.xsd`) | |
| an elimination is stated in the composed unit, after conversion | `Part` (`assertion.xsd`) | |
| a converted part's remainder is converted directly, never worked out again from its converted nameplate and demand | `Part` (`assertion.xsd`) | |
| a `composition` and a `dependence` filed by one consolidator about one consolidation agree about witness, date and regime \* | `Dependence` (`assertion.xsd`) | |
| a part crossing a regime boundary files the instrument that reconciles it, as a part crossing a unit boundary files its factor | `Composition` (`assertion.xsd`) | `regime_crossing_without_a_citation` |
| a composer's `regime` for a part is one that part's own filing declares, a claim about the other document that no key in this one can check | `FiledLayer` (`assertion.xsd`) | `part_regime_disagrees` |
| a slack is expressed in the unit of the shares it bounds | `Nameplate`, `Layer` | `slack_unit_mismatch` |
| a slack measured as a duration is converted into a quantity at the supply's rate before it is filed | `Nameplate`, `Layer` | |
| a unit is quoted over at least one whole period of the supply it measures | `Claim` | |
| `timeSlack` is filed as a `clearance` derivation only where the layer runs the whole of its period, filed as a window of one whole period in the period's own unit | `Layer` | `derived_slack_over_a_window` |
| a claim whose `boundOrigin` or `narrowsWhen` is filed as a derivation names an identity that computes the claim's own position, or for an edge the origin its holder states beside it (`amountOrigin` on a nameplate amount, `quantumOrigin` on a unit's or a window's size), since a `Claim` is one type wherever it sits | `Claim` | `identity_does_not_compute_the_claim` |
| a single figure files `narrowsWhen` as `notApplicable`, having no width to tighten | `Claim` | `narrows_a_point_value` |
| a range with any width does not file `narrowsWhen` as `notApplicable` | `Claim` | `range_says_no_range` |
| a single figure does not file `boundOrigin` as `none`, since that reason says the bound is where the measurements fell, and nothing fell anywhere | `Claim` | `bound_fell_with_no_range` |
| a `window` is the live part, one per period of the nameplate's unit, and never the gap | `Divisibility` | |
| a `window` requires the nameplate's unit to name a period, since it is the live part of that period | `Divisibility` | |
| a `window` is carried through a fusion and never summed: it belongs to the supply, not to a quantity | `Divisibility` | `window_lost_or_summed` |
| a `window` filed as a whole unit does not file that unit's `size` as `notApplicable`: a unit with no period is the window's own `notApplicable` | `StatedLumpyQuantum` | `window_size_not_applicable` |
| a layer filing a `window`, or filing its absence as `unmeasured`, does not file `timeSlack` as a `clearance` derivation, because in neither case is the spare known to be spread evenly across the period | `Divisibility`, `Layer` | `derived_slack_over_a_window` |
| a `window` filed as `notApplicable` sits on a unit with no period, since a unit that names a period can be answered | `Divisibility` | `window_not_applicable_on_a_rate` |
| a fusion filing `eliminations` as `none` or `notApplicable` owes an exact sum: the composed figure equals its converted parts added up. Filed `unmeasured`, the check is suspended, not passed | `Fusion` (`assertion.xsd`) | `fusion_sum_disagrees` |
| a fusion filing `eliminations` as `notApplicable` has exactly one part: with one part, nothing can be counted twice | `Fusion` (`assertion.xsd`) | `elimination_not_applicable_with_parts` |
| a fusion of one part that eliminates nothing carries that part unchanged, in every quantity the layer files and not only its demand | `Fusion` (`assertion.xsd`) | `one_part_fusion_alters_its_part` |
| a part whose unit differs from the layer it is composed into files what converts it, even where the conversion is one, because then somebody is asserting the two units interchange | `Part` (`assertion.xsd`) | `unit_crossing_without_a_factor` |
| converting a quantity round a loop of units and back returns what it started with, within the factors' ranges | `Part` (`assertion.xsd`) | `conversion_cycle_does_not_close` |
| a layer restated by a second filing that claims to carry it through unchanged agrees with the first, `absorber` included \* | `composition` (`assertion.xsd`) | |

### Reading the table

**The four `dependence` rows are why a dependence is a document of its own.** An XSD key is scoped
to one document, so a reference that seemed to reach across a filing boundary would validate by not
being checked. An implementer that can fetch the other filing owes the first two checks. One that
cannot owes the reader the knowledge that it did not happen.

**The three `composition` rows are owed three different ways.** The sum of parts is ordinary
arithmetic across filings. An implementer that can fetch the members owes it, and
`tests/composition.rs` checks it for the documents here. The elimination's pairing is reachable in
principle and simply beyond XSD 1.0. Taken the wrong way, it still gives a well-formed range, so it
is the one most likely to go wrong quietly. Whether two members' people can cover for each other is
owed by nobody, ever: it is a judgement, not a computation.

**The two `Holder` rows are one rule with two halves.** `party` and `asOf` belong to
`counterparty` and nothing else. And a `counterparty` holder must name its party, because a burden
said to sit in another entity's books with nobody named is a guess. It is easiest to break in a
consolidation, where a `booked` share really is booked in some member's books. On a counterparty
holder, though, `party` names whose other books carry the burden. `tests/corpus_parse.rs` checks
both halves for every holder in every filing here.

**The two `Coupling` rows say what a coupling does one cycle up,** when it meets a fusion.
Neither makes a coupling evidence for a fusion, because coupling and standing in for each other are
independent. Two delivery teams in two countries are one layer and not coupled at all. A delivery
team and an out-of-hours rota are tightly coupled and are two layers, because an engineer on the
rota delivers no features.

**Double counting is a third axis.** A fusion's nameplate elimination is how much supply its parts
counted in common. The documents here cover that scale end to end: a stated `[0, 0, 0]` at
`merge-group-composition`'s `labour`, a whole part at its `shift-line`, and the middle in
`assets/fixtures/every-partial-elimination.xml`. The bottom of the scale is a claim of zero, never
`none`, because an elimination's quantity has no `none` in its type.

**The `jagged_layer` row weakens with depth.** Within one document, `partIdentity` is an `xs:key`
and catches a layer consolidated twice. Two levels up it cannot, because a holding naming both
`group#labour` and `member#labour` holds two distinct references to one layer. The check needs the
chain fetched, and a layer sits one element deeper inside a composition than inside a filing.

**One limit is missing from the table on purpose.** The units of a fusion's parts are not compared,
because parts legitimately spell one unit two ways, `people` and `pessoas`, and saying they name one
unit is exactly what a fusion says.

**One more rule became checkable with `Regime/chart`:** an answer whose `holds` names a taxonomy
other than the declared `chart` is a finding. `tests/coverage_parse.rs` checks it for the documents
here, and a profile still owes it for every document it has never seen. It applies to `holds`
only, never to `refuses`, because a refusal code comes from a coding pack shared across regimes.

### The arithmetic rules

Some rules are arithmetic over values the document already carries, so an implementer discharges
them by computing.

- **The remainder is filed whole.** Its split into whole units and a residue is the receiver's to
  work out, figure by figure, and is never filed: at a demand range's three points the residues
  need not come out in order. The walk's second step, in [`assets/sqlc/`](../assets/sqlc/README.md),
  shows the split.
- **Sums need a tolerance.** `tests/corpus_parse.rs` checks that the stated shares add up to the
  remainder, and `tests/composition.rs` that a composed figure equals its parts less its
  eliminations, for the documents here. The figures are binary floating point, where `10.0 - 10.4`
  is `-0.40000000000000036`, so the comparison cannot be exact. The tolerance is a policy number,
  left to the profile. The parts also live in other documents, so the check needs the receiver's own
  catalogue of where each filing can be fetched.
- **An unsized elimination makes the sum uncomputable, not satisfied.** A checker that read an
  `unmeasured` elimination as zero would find the layer reconciling and report success about a
  figure it was told is overstated. Unchecked is a third state. An elimination that sizes to nothing
  is filed `[0, 0, 0]`, a claim. `none` on the `eliminations` wrapper says something else again:
  the composer searched and found no double counting, and the sum is exact.

### Schematron, not yet

Schematron is the right long answer: it is the standard companion to XSD 1.0 and sits beside the
schema, costing it nothing. But it is a second artifact with its own toolchain, and an adopter who
will not run this crate's tests will not run Schematron either. So not yet, in keeping with this
page's own rule that a profile follows a real adopter. Meanwhile the `# What no validator reaches`
headings tell a sender which rules bind and which are owed, at the cost of one paragraph per type.
