# `assets/fixtures/`: one document for each state the schema admits

> **Também disponível em português europeu: [`pt-PT/assets/fixtures/README.md`](../../pt-PT/assets/fixtures/README.md).**

The documents in [`../corpus/`](../corpus/) are claims about a business. These are claims about
the schema: that a state it admits validates, comes back out of the Rust types as it went in, and is
handled by the queries. Nothing here says anything about a business, and nothing here is cited as
if it did.

## Why they are kept apart

An empty state means opposite things in the two directories. In the corpus, a state no document
files is a finding about the evidence: nobody filing has done that yet. No stack there files its
couplings as `none`, because nobody filing there tested whether their layers move independently,
and that is worth knowing. Here, a state no document files is a gap in coverage, and a defect.

Add one `none` to the corpus to fill that state and the finding becomes false. Put it here instead,
and the state is tested while the finding stays true.

| | `assets/corpus/` | `assets/fixtures/` |
|---|---|---|
| answers | can this describe a real business? | does every state the schema admits work? |
| a document is | a claim about a business | a claim about the schema |
| an empty state means | nobody has filed that yet: a finding | a gap in coverage: a defect |
| may be edited to fill a state | never | that is its job |
| cited as evidence about a business | yes | never |

The class census counts the same classes over each directory on its own:

```sh
psql -d process_modulus -f assets/sql/reports/classes_in_the_corpus.sql
psql -d process_modulus -f assets/sql/reports/classes_in_the_fixtures.sql
```

A class at zero in the first is a document worth having. A class at zero in the second is a
fixture owed.

## What each one fills

| file | the states it files |
|---|---|
| `every-absence.xml` | the typed blanks no filing in the corpus uses: couplings filed `none`, `StatedFit`'s blank both ways (`unmeasured` and `notApplicable`), an operation's place in the process model filed `unmeasured` and `notApplicable`, and a chart filed `none`, with an absorber, a remainder and a measurement basis filed `unmeasured` |
| `every-elimination.xml` | eliminations filed `none` and filed `unmeasured`. Under `none` the composed figure must equal the sum of its converted parts; under `unmeasured` nothing is owed |
| `every-claimed.xml` | `Claimed/partial`: a witness that answers part of a question and says which part, which no witness in the corpus does |
| `every-local-part.xml` | three layers: the member's, the parent's own, and one made of both; and `StatedNotation/uri` under a local part |
| `every-partial-elimination.xml` | an elimination that is neither zero nor a whole part, so it removes an amount rather than a layer |
| `every-inverting-elimination.xml` | an elimination wider than the sum it corrects: the parts are exact and the shared block is a range. Removed bound by bound, the low would end above the high, so the filed figure pairs the sum's low with the elimination's high |
| `every-derived-elimination.xml` | an elimination the parent names as `sharedParts` and leaves to the receiver. Nothing computes a filed derivation, so the nameplate sum is suspended and the composed nameplate stands on the parent's word. The demand elimination beside it is stated at zero, and its sum is owed exactly. One fusion: one quantity checked, one not |
| `every-unserved-excess.xml` | an excess with nowhere to go: an `interference` fit whose three buffers are all stated empty, so every holder must be one of the two that carry unserved demand, and the exposure, the shortfall at its worst, is held against the shares they admit |
| `every-unsized-conversion.xml` | `Part/factor` left blank: a conversion nobody measured, which is not a part that needs none |
| `every-draft.xml` | `StatedNotation/unmeasured`, `StatedScope/unmeasured` and `StatedEvidence/unmeasured`: the document a first-time adopter actually has, down to the one state where it will not say whether it observed anything |
| `every-unit-cycle.xml` | three layers whose conversions run from GPU to GPU-hour to node-hour and back to GPU, so a round trip through the units can be asked about at all. The parts stay a chain; it is the units that come round |
| `every-nested-conversion.xml` | a conversion with a range beneath another conversion with a range, three layers chained. The composed remainder has to be worked out through both levels at once, and the filed shares agree with that figure, so a reader that stops one level early accuses a correct filing |
| `every-derived-quantity.xml` | a composed figure filed as a `fusionSum` derivation, which the receiver computes rather than reading it as a gap. A composed demand that is only its fusion's output is a part of another composed layer, so the outer sum needs the inner one first. Beside it sit a composed draw filed as a derivation over a part nobody metered, which cannot be computed and says why, and a fusion built on that layer, whose draw sum is lifted for the same reason and whose nameplate is itself a derivation |

## Where they stop

A fixture shows that a state can be reached, never that it is handled well. That takes three more
things. A validator does the validating. `tests/roundtrip.rs` writes every document here and in the
corpus back out through the Rust types and reads it in again. The queries are the third. Beside
them, the negative controls in `tests/fixtures.rs` edit a parsed document rather than read a file,
because what they check is that the checker bites.
