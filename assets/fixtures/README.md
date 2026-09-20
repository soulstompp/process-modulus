# `assets/fixtures/`: one document per state, and NOT a second corpus

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

⛔⛔⛔ **THESE ARE STIPULATIONS, NOT FILINGS, AND THE DIFFERENCE IS THE WHOLE REASON THE
DIRECTORY EXISTS.** Every document in [`assets/corpus/`](../corpus/) is a claim about a
business — a demand somebody observed, a remainder somebody bore. Every document here is a
claim about the SCHEMA: that a state it admits validates, round-trips, and is handled by the
rules. Nothing here asserts anything about any business, and nothing here may be cited as
evidence about one.

## Why they cannot live in one directory

The corpus's dark states are EVIDENCE. No stack in `assets/corpus/` files `couplings` as
`absent/reason = none`, because nobody filing into that corpus tested whether their layers move
independently — **and that is a finding about the state of the evidence**, reported by
`rules.sql` and asserted by `tests/corpus_parse.rs`.

Add one `none` to the corpus to light the branch and the finding becomes a lie. Refuse to add
it anywhere and the branch ships untested, which is the trap this repository already names:
*a bound with nothing to bound passes loudest.* Two questions that rhyme and sit on
different axes, which is the split the schema itself draws between `Verdict` and
`AbsenceReason`.

| | `assets/corpus/` | `assets/fixtures/` |
|---|---|---|
| answers | can this express a real business? | does every admitted state work? |
| a document is | a claim about the world | a stipulation about the schema |
| a dark state means | **nobody has done that yet** — a finding | a gap in coverage — a defect |
| may be edited to light a branch | never | that is its job |
| cited in findings as evidence | yes | never |

## What each one is for

| file | lights |
|---|---|
| `every-absence.xml` | `StatedCouplings/none`, `window/none`, `StatedFit`'s whole absence arm, `boundOrigin/notApplicable`, `StatedDivisibility/none`; and a chart filed `none`, an absorber, a demand, a remainder and a measurement basis filed `unmeasured` |
| `every-elimination.xml` | `StatedEliminations/none` and `/unmeasured`, and the two different sums they owe |
| `every-claimed.xml` | `Claimed/partial`, the value `CoverageEntry/complete` could not hold |
| `every-local-part.xml` | the three-layer construction: theirs, mine, one made of both — and `StatedNotation/uri` under a LOCAL part |
| `every-partial-elimination.xml` | the middle of the elimination scale: a nameplate `e` that is neither zero nor a whole part, so `e` reads as a MAGNITUDE rather than as a kind of fusion |
| `every-inverting-elimination.xml` | an elimination wider than the sum it corrects: point parts and a shared block whose size is a range, so subtracting bound by bound inverts and the filed figure is the crossed pairing |
| `every-derived-elimination.xml` | the third arm of an eliminated quantity, which is neither a figure nor a typed absence: the composer names `sharedParts` and leaves the arithmetic to the receiver. Nothing computes a filed derivation, so the nameplate sum is suspended and the composed nameplate stands on the composer's word, while the demand elimination beside it is stated at zero and its sum is owed and exact. One fusion, one quantity checked and one not |
| `every-unserved-excess.xml` | an excess with nowhere to go: an interference fit whose three buffers are all stated empty, so every holder must be one of the two that bear unserved demand, and the exposure is held against the shares they admit |
| `every-unsized-conversion.xml` | `Part/factor`'s absent arm: a conversion nobody measured, which is not a part that needs none |
| `every-draft.xml` | `StatedNotation/unmeasured`, `StatedScope/unmeasured` and `StatedEvidence/unmeasured` — the document a first-time adopter actually has, including the one state where it will not even say whether it observed anything |
| `every-unit-cycle.xml` | a CYCLE IN THE UNIT GRAPH: three layers whose conversions run GPU to GPU-hour to node-hour and back, so a round trip can be asked about at all. The part graph stays a chain and nothing is composed from itself — it is the UNITS that come round |
| `every-nested-conversion.xml` | a SPREAD CONVERSION BENEATH A SPREAD CONVERSION, which is the state where a composed remainder stops being computable one level at a time. Three layers chained, both edges carrying a factor with width, and the filed holder shares agreeing with the recursive figure rather than the one-level one, so a reader that stops too early accuses a correct filing |
| `every-derived-quantity.xml` | a composed figure filed `derived`, which the receiver computes rather than reading it as a gap. A composed demand that is only an output of its fusion is a part of a composed layer that states its own, so checking the outer sum means computing the inner one first; beside it, a composed draw filed `derived` over a part nobody metered, which cannot be computed and says why, and a fusion built on that layer whose draw sum is lifted for the same reason and whose nameplate is itself filed `derived` |

**A fixture proves reachability, never correctness.** That a document filing
`claimed = partial` validates says the state exists; it says nothing about whether a runner
reports `notable` for a witness that answers beyond it. The negative controls in
`tests/fixtures.rs` are the other half, and they mutate a parsed document rather than reading a
file, because what they check is whether the CHECKER bites.

⭐ **The three verbs at the top of this file land in three places and only one of them is
`tests/fixtures.rs`.** A validator does the validating. `tests/roundtrip.rs` does the round
trip, walking this directory alongside the corpus, so that a state the schema admits is also
a state the generated crate can write back out and read again. The rules are the third.
