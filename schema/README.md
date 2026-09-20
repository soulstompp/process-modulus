# `schema/`: the deliverable itself, and the five documents it lets anybody write

> **Também disponível em português europeu: [`README.pt.md`](README.pt.md).**

⛔ **This directory is the artifact.** Everything else in the repository is a reference
implementation of what is here, a body of evidence about it, or a proof that it says what it
claims. Anything that cannot be said in these two files is not part of the model.

## Two files, and the second one imports the first

| file | prefix | what it declares |
|---|---|---|
| `process-modulus.xsd` | `pm` | the model: a supply, what it divides into, what the division leaves over, and who carries it |
| `assertion.xsd` | `asrt` | what a SECOND party says about a filing, which is a different genre and needs its own roots |

The split is not tidiness. A filing is signed by the entity it describes; a coverage answer, a
promoted run, a cross-filing dependence and a consolidation are signed by somebody else, and a
claim *about* a filing cannot live inside the filing it judges.

Five root elements, so five kinds of document:

| element | filed by |
|---|---|
| `pm:processModulus` | the entity, about itself |
| `asrt:coverage` | a witness, answering a corpus of questions |
| `asrt:run` | a witness, promoting one dated trial to something a report may cite |
| `asrt:dependence` | somebody who read two filings, neither of them their own |
| `asrt:composition` | a parent, publishing a stack built out of other people's filings |

## Validate it with anything

XSD 1.0, deliberately, and no `xs:assert`. The tempting 1.1 feature would collapse three types
into zero, and it was tested rather than assumed: a stock JDK ships no 1.1 validator, and
`libxml2` has never implemented 1.1, which is what `xmllint`, `lxml`, PHP and Nokogiri all wrap.
⛔ A schema whose whole purpose is that several organisations can check a document against it does
not get to require an installation first, and that cost lands hardest on the smallest party in the
chain.

```bash
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
```

⚠️ **Deserializing is not validating**, in either direction. The generated Rust accepts a document
`xmllint` refuses, and writes one too. Use a validator.

## What the annotations are for, and what they are not

Every declaration documents itself, in English and in European Portuguese, under four headings:

| heading | |
|---|---|
| `WHAT IT IS` | the fact this position carries |
| `WHAT IT CONTAINS` | its children, held against the content model by `tests/annotations.rs` |
| `WHAT IT OBLIGES` | what a sender must do to file it honestly |
| `WHAT IT REFUSES` | the reading a competent filer would otherwise reach, and why it is wrong |

⛔ **They describe the DATA.** Why the model is shaped this way, what was tried and withdrawn, and
how any of it was found are a different subject with a different audience, and they belong
alongside the argument rather than inside the artifact.

**`NOT REACHABLE BY A VALIDATOR` marks the rules XSD 1.0 cannot express**, which are mostly
comparisons across elements or across documents. The marker sits at the declaration that states
the rule, so a reader can always tell a gated rule from an ungated one.
[`../conformance/README.md`](../conformance/README.md) lists them and names what runs each one
that runs; [`../assets/sqlc/README.md`](../assets/sqlc/README.md) is where they are expressed as
queries.

⚠️ **The namespace URIs are placeholders** until the author's hosting domain is settled.
`tests/namespace.rs` makes changing them a checked operation. Nothing else here is provisional.
