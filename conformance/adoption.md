# Recognising a restated set in a corpus you already have

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
`BorrowedTerm` makes and which had until then been made from first principles rather than
from instances.

What a fork costs is not immediate. A restated set does not drift on the day it is copied.
It drifts when the authority revises theirs, and nothing in the copy can notice.

## The correction, which matters more than the finding

The first reading of the table above was that those authors had restated a set without its
authority. That was wrong, and the corrected version is the more useful finding.

Beside the largest of the three sat a source note recording the authority completely: the
statutory instrument and its annexes, the issuing body, three artifacts each with a
checksum, which of the three is the law, the page ranges, and an explicit rule about which
date to cite.

> So the authority was not missing. It was in prose, in a sibling file, and unreachable from
> the value.

A source note beside a table is to `BorrowedTerm` exactly what a long explanatory note is to
`Absence`: excellent, correct, and unjoinable. It is `Absence`'s own rule, that a reason no
query can reach is not a typed absence, arriving one type over.

That makes the repair small, and it makes the adopter look good rather than careless. They
had the authority all along and no slot to put it in. Adding the slot is the cheapest kind
of adoption gap to close.

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

## On the measurements behind this

The counts that produced these signatures were scoped to tabular registers, meaning columns
in CSV-shaped files, and were generalised in error on first reporting. No figures are
restated here, deliberately. The signatures are the transferable part, and a number measured
against one corpus's tables is not a fact about what any adopter knows.

Two dates, one number and a named corpus would all be more precise and less true. If a
figure is wanted, measure the corpus in front of you.
