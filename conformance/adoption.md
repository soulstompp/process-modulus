# Recognising a restated set in a corpus you already have

> **Também disponível em português europeu: [`adoption.pt.md`](adoption.pt.md).**

**Guidance, not a schema change.** An adopter cannot act on a rule they do not recognise
themselves breaking, and the rules this schema is built on are all broken by work that is
locally correct. Nothing below is a defect in the project it was found in.

See `BorrowedTerm` and `Absence` in the base schema for the rules themselves. This file is
only about what breaking them looks like from inside.

## The signature of a restated set

> A column named for a taxonomy, holding values, with no URI anywhere in the file.

That is the whole tell, and it is worth grepping for. One measured corpus carried a column
literally named `taxonomy_reference` holding bare values across roughly a thousand rows,
with no naming authority in the file at all.

### Three unrelated authors made one mistake, and that is the evidence

The same borrowed four-value set was restated three ways by people who had not read each
other:

| | the restatement |
|---|---|
| a reference table | a column named for a taxonomy, holding bare values |
| a program | a four-variant enumeration of the same set |
| a register | a national statutory legal form, as free text |

None of the three is a bug in its own project. Each is locally correct and locally
unambiguous. The values mean exactly what their authors intended, and nothing inside those
projects is wrong. The fork is only visible from outside, which is precisely the argument
`BorrowedTerm` makes, and here it is an instance rather than a derivation from first
principles.

What a fork costs is not immediate. A restated set does not drift on the day it is copied.
It drifts when the authority revises theirs, and nothing in the copy can notice.

## The authority is not missing, it is unjoinable, and that is the sharper finding

Beside the largest of the three sits a source note recording the authority completely: the
statutory instrument and its annexes, the issuing body, three artifacts each with a
checksum, which of the three is the law, the page ranges, and an explicit rule about which
date to cite.

> The authority is not missing. It is in prose, in a sibling file, and unreachable from the
> value.

A source note beside a table is to `BorrowedTerm` exactly what a long explanatory note is to
`Absence`: excellent, correct, and unjoinable. It is `Absence`'s own rule, that a reason no
query can reach is not a typed absence, arriving one type over.

That makes the repair small, and it makes the adopter look good rather than careless. They
have the authority and no slot to put it in. Adding the slot is the cheapest kind of adoption
gap to close.

## The companion signature, for `Absence`

> A blank whose explanation lives in a free-text note rather than in a sibling column a
> query can join on.

The clearest specimen met so far is a register that files one legal form empty on purpose,
with an excellent paragraph beside it saying why. Nothing can join on that paragraph. An
adopter who puts the reason in a note has met this schema's letter and lost its entire
benefit.

The counter-caveat travels with it. A blank whose meaning is enforced by a rule in a checker
is still not a reason reachable from the row, but that does not mean the adopter does not
know what their blanks mean. It means the knowledge is not in the document, which is a
different and far more fixable problem.

## A third signature, for a role rather than a value

> A repeating element whose emptiness has to mean two things, with no sibling that says
> which.

The first two signatures are about a value: a term with no authority, a blank with no
reason. This one is about a role. An adopter who models a role as a bare repeating element,
or as an unbounded choice at the root of a profile, has written valid and idiomatic XSD, and
nothing inside their project is wrong. A document carrying none of that role is ordinary and
frequently the finding.

The cost appears only when something other than the filer assembles the document. A reader
that goes to sources it does not control has three ordinary ways to come back with nothing:
the source was not there, the source lacked a field the role requires, or a closed
vocabulary refused the value by name. Each emits the same empty role as a source that
genuinely reported nothing, and those are opposite claims. The asymmetry is what prices it:
a true zero reported as a failure is a false alarm and announces itself, while a failure
reported as a true zero is false confidence and nobody investigates, because nothing looks
wrong.

⛔ The remedy is not a schema change. The base schema demonstrates the shape twice, at
`StatedCouplings` and at `asrt:StatedEliminations`: a choice between the repeating element
and an `Absence`, each required on its parent, so the position exists before the rows do.
`Absence` then carries the reason, and its `provenance` separates a reader's gap from a
filer's zero, because who says a thing is unmeasured is itself information. "Nobody looked"
and "somebody looked and found none" become two filings rather than one empty list.

Requiring the wrapper is cheap for the reason `AbsenceReason` gives: an element is expensive
to require only when the sender must invent a value to satisfy it, and once a typed absence
is a legitimate answer a sender can always answer honestly. The base schema priced the
alternative once already, at `Coupling/strength`, where an optional element and a typed
absence said the same thing two ways, and the annotation there records which of the two a
corpus reached for.

The counter-caveat travels with this one too. A role whose emptiness can only mean one thing
needs no wrapper, and a corpus nobody assembles does not have the problem at all: a filer
who writes their own document knows what they left out, and their silence is a statement.
The signature is worth grepping for in a profile whose documents are built by a program.

## On the measurements behind this

The counts behind these signatures are scoped to tabular registers, meaning columns in
CSV-shaped files, and they do not generalise past that. ⛔ No figures are restated here,
deliberately. The signatures are the transferable part, and a number measured against one
corpus's tables is not a fact about what any adopter knows.

Two dates, one number and a named corpus would all be more precise and less true. If a
figure is wanted, measure the corpus in front of you.
