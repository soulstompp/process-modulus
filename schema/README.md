# `schema/`: the deliverable itself, and the five documents it lets anybody write

> **Também disponível em português europeu: [`pt-PT/schema/README.md`](../pt-PT/schema/README.md).**

These two files are process-modulus. Everything else in the repository reads them: the documents
in [`../assets/corpus/`](../assets/corpus/), the SQL that checks those documents, and the Rust
crate generated from the schemas.

## Two files, five documents

| file | prefix | what it declares |
|---|---|---|
| `process-modulus.xsd` | `pm` | a filing: a business's layers, each one a demand, a supply, what the division leaves and who carries it |
| `assertion.xsd` | `asrt` | what somebody else says about filings. It imports the first file for the codes and regimes they share |

Each root element is one kind of document:

| element | filed by |
|---|---|
| `pm:processModulus` | the business, about itself |
| `asrt:composition` | a parent, publishing one stack built from its members' filings |
| `asrt:dependence` | somebody who read two filings, neither of them their own |
| `asrt:coverage` | a witness, answering a set of questions |
| `asrt:run` | a witness, promoting one dated run to evidence a report may cite |

A filing is signed by the business it describes: its own commitments, in its own words. The other
four are signed by somebody else, because a claim about a filing cannot live inside the filing it
judges. A parent sits one cycle up. Its composition reads the members' filings the way management
reads its team leads, and signs what it concludes. Kept in a document of its own, a parent's
judgement is never read as a member's own word.

## Validate with what you already have

The schemas are XSD 1.0, so the validators people already have read them, with nothing to
install. That includes `xmllint` and the libraries built on the same engine (`lxml`, PHP,
Nokogiri), and the validator that ships with Java. This matters most to the smallest party in the
chain, which is often the one being asked to file.

```sh
xmllint --noout --schema schema/process-modulus.xsd assets/corpus/enterprise-contract.xml
xmllint --noout --schema schema/assertion.xsd       assets/corpus/merge-group-composition.xml
```

## Reading an annotation

Every declaration explains itself in English and in European Portuguese, under the same headings,
each using the ones it needs:

| heading | what it says |
|---|---|
| `# What it is` | the fact this position carries |
| `# What it contains` | its children, one line each |
| `# What it obliges` | what a sender must do to file it honestly |
| `# What it does not admit` | the states and readings it rules out, and why |
| `# What no validator reaches` | the rules XSD 1.0 cannot check here |

An enumeration lists its values under `# The members`, `# Where it is checked` names the query that
runs a rule, and `# See also` points to the neighbouring types. Each `# What it contains` list is
checked against the element's real content, so it can be filed against. `cargo doc --open` shows the
same annotations as the generated crate's documentation.

## What a validator cannot reach

Some rules compare one element with another, or one document with another, and XSD 1.0 has no way
to say that. The schema states those rules under `# What no validator reaches`, in the type they
belong to. [`../conformance/README.md`](../conformance/README.md) lists them, and
[`../assets/sqlc/README.md`](../assets/sqlc/README.md) runs each one as a query.

The namespace URIs are `https://example.invalid/…` until the hosting domain is settled. Changing
them is a checked step, held by `tests/namespace.rs`.
