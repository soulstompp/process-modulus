# Recognising a restated set in a corpus you already have

> **Também disponível em português europeu: [`pt-PT/conformance/adoption.md`](../pt-PT/conformance/adoption.md).**

This is guidance, not a schema change. An adopter cannot fix a rule they do not recognise
themselves breaking, and the rules this schema stands on are broken by work that is locally
correct. Nothing below is a defect in the project it was found in.

The rules themselves are `BorrowedTerm` and `Absence` in the base schema. This page is about what
breaking them looks like from inside.

## The signature of a restated set

> A column named for a taxonomy, holding values, with no URI anywhere in the file.

That is the whole tell, and it is worth searching for. One corpus carried a column named
`taxonomy_reference` holding bare values on every row, with no naming authority anywhere in the
file.

### Three authors, one mistake

The same borrowed four-value set was restated three ways, by people who had not read each other:

| | the restatement |
|---|---|
| a reference table | a column named for a taxonomy, holding bare values |
| a program | a four-variant enumeration of the same set |
| a register | a national statutory legal form, as free text |

Each is locally correct, and its values mean exactly what its authors intended. The copy is visible
only from outside, which is the argument `BorrowedTerm` makes. A restated set does not drift on the
day it is copied. It drifts when the authority revises theirs, and nothing in the copy notices.

## The authority is not missing, it is unjoinable

Beside the largest of the three sits a source note that records the authority completely: the
statutory instrument and its annexes, the issuing body, three artifacts with their checksums, which
of the three is the law, the page ranges, and which date to cite.

> The authority is not missing. It is in prose, in a sibling file, and no value reaches it.

A source note beside a table is to `BorrowedTerm` what a long explanatory note is to `Absence`:
correct, careful, and impossible to join on. A reason no query can reach is not a typed absence.

So the repair is small, and it makes the adopter look good rather than careless. They have the
authority and no slot to put it in, and adding the slot is the cheapest gap there is to close.

## The companion signature, for `Absence`

> A blank whose explanation lives in a free-text note rather than in a column a query can join on.

The clearest case so far is a register that leaves one legal form empty on purpose, with an
excellent paragraph beside it saying why. Nothing can join on the paragraph. An adopter who puts
the reason in a note has met the schema's letter and lost its benefit.

A blank whose meaning a checker enforces is still not a reason the row carries. That does not mean
the adopter does not know what their blanks mean. It means the knowledge is not in the document,
which is a different and far more fixable problem.

## A third signature, for a role rather than a value

> A repeating element whose emptiness has to mean two things, with no sibling that says which.

The first two signatures are about a value: a term with no authority, a blank with no reason. This
one is about a role. A role modelled as a bare repeating element is valid and idiomatic XSD, and a
document carrying none of it is ordinary, often the finding itself.

The cost appears when something other than the filer assembles the document. A reader drawing on
sources it does not control can come back empty three ordinary ways. The source was not there, the
source lacked a field the role needs, or a closed vocabulary refused the value. Each looks exactly
like a source that truly reported nothing. A true zero reported as a failure is a false alarm, and
it announces itself. A failure reported as a true zero is false confidence, and nobody looks.

The remedy is not a schema change. The base schema shows the shape twice, at `StatedCouplings` and
at `asrt:StatedEliminations`: a choice between the repeating element and an `Absence`, required on
its parent, so the position exists before the rows do. The `Absence` carries the reason, and its
`provenance` tells a reader's gap from a filer's zero. "Nobody looked" and "somebody looked and
found none" become two filings rather than one empty list.

Requiring the wrapper is cheap: an element costs a sender something only when they must invent a
value for it, and a typed absence is always an honest answer.

A role whose emptiness can mean only one thing needs no wrapper. A filer who writes their own
document knows what they left out, and their silence says so. The signature matters most in a
profile whose documents a program assembles.

## The measurements behind this

The cases above come from tabular registers, columns in CSV-shaped files, and the counts stay with
them. The signatures are what transfers. If a figure is wanted, measure the corpus in front of you.
