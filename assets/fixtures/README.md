# `assets/fixtures/` — one document per state, and NOT a second corpus

⛔⛔⛔ **THESE ARE STIPULATIONS, NOT FILINGS, AND THE DIFFERENCE IS THE WHOLE REASON THE
DIRECTORY EXISTS.** Every document in [`assets/corpus/`](../corpus/) is a claim about a
business — a demand somebody observed, a remainder somebody bore. Every document here is a
claim about the SCHEMA: that a state it admits validates, round-trips, and is handled by the
rules. Nothing here asserts anything about any business, and nothing here may be cited as
evidence about one.

## Why they cannot live in one directory

The corpus's dark states are EVIDENCE. No stack in `assets/corpus/` files `couplings` as
`absent reason="none"`, because nobody in those seven filings tested whether their layers move
independently — **and that is a finding about the state of the evidence**, reported by
`rules.sql` and asserted by `tests/corpus_parse.rs`.

Add one `none` to the corpus to light the branch and the finding becomes a lie. Refuse to add
it anywhere and the branch ships untested, which is the trap this repository already names:
*a bound with nothing to bound passes loudest.* ⭐ Two questions that rhyme and sit on
different axes, which is the split the schema itself draws between `Verdict` and
`AbsenceReason`.

| | `assets/corpus/` | `assets/fixtures/` |
|---|---|---|
| answers | can this express a real business? | does every admitted state work? |
| a document is | a claim about the world | a stipulation about the schema |
| a dark state means | **nobody has done that yet** — a finding | a gap in coverage — a defect |
| may be edited to light a branch | ⛔ never | ⭐ that is its job |
| cited in findings as evidence | yes | ⛔ never |

## What each one is for

| file | lights |
|---|---|
| `every-absence.xml` | `StatedCouplings/none`, `window/none`, `StatedFit`'s whole absence arm, `boundOrigin/notApplicable`, `StatedDivisibility/none` |
| `every-elimination.xml` | `StatedEliminations/none` and `/unmeasured`, and the two different sums they owe |
| `every-claimed.xml` | `Claimed/partial`, the value `CoverageEntry/complete` could not hold |
| `every-local-part.xml` | ⭐ the three-layer construction: theirs, mine, one made of both — and `StatedNotation/uri` under a LOCAL part |
| `every-draft.xml` | `StatedNotation/unmeasured` and `StatedScope/unmeasured` — the document a first-time adopter actually has |

⚠️ **A fixture proves reachability, never correctness.** That a document filing
`claimed = partial` validates says the state exists; it says nothing about whether a runner
reports `notable` for a witness that answers beyond it. The negative controls in
`tests/fixtures.rs` are the other half, and they mutate a parsed document rather than reading a
file, because what they check is whether the CHECKER bites.
