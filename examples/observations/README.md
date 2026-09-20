What the corpus actually says, and whether anything is looking.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

`examples/matrices/main.rs` proves the arithmetic agrees with itself. `examples/readiness/main.rs`
asks whether it may be performed. This one asks the corpus questions and prints the answers,
because a relation whose product is knowledge rather than a verdict has nowhere else to land and
gets written and read by nobody.

⭐⭐⭐ EVERY NUMBER A COMMENT IN THIS REPOSITORY QUOTES SHOULD BE PRINTED BY A PROGRAM. A
figure written into a header is correct on the day it is written and answers to nothing
afterwards: the corpus moves and the sentence does not. This is where the ones that would
otherwise sit in prose get printed.

⛔⛔ THE TEETH ARE ON THE UNASKED QUESTION, NEVER ON THE ANSWER. Two assertions:
that no relation and no document is reached by nothing, and that every remainder has had
the closure question put to it. Neither judges a filing. `unbounded` is the honest state
for a document written to argue about three layers, and a spillover is a REFERRAL, a
filing is not the system, and a second document's observation is a projection onto this one
rather than an accusation against it.

# Identity elements, and where an absence can impersonate one

§14 below asks which of the four absence reasons each question has ever taken. This is the
rule that decides which of them a schema position may offer at all.

Every quantity in this model enters either a sum or a product. The three buffer slacks are
substitutes and they add: `inventory + capacity + time`, identity 0. A duty cycle multiplies:
`delivered = rate × window ÷ period`, identity 1. A conversion factor and a quantum multiply
too.

Where a grammar admits both a value and a typed absence at one position, and the absence can
be read as that operation's identity, the two are two spellings of one fact. **The absence is
the lossy spelling.** It carries no unit, no author for the exactness, and no origin, so a
receiver cannot compare it as arithmetic with the filers who reached for a number.

⭐⭐ **The rule that follows: wherever the value arm names the degenerate case, the absence arm
must not be able to say the same thing.** A slack of zero is the smallest slack and is filed
`[0, 0, 0]` in the unit it is zero in. A supply that runs continuously has a duty fraction of
one and is filed as one whole period, quoted in the period's own unit, carrying the origin that
says who could shorten it. A remainder of zero is a clearance fit, filed with a sign and a
quantity of `[0, 0, 0]`, because `Fit` reads it as clearance, extending ISO 286's line-to-line
case, where minimum clearance is zero, to the one pair ISO's clauses do not separate.

An identity element may sit in an absence, but only when the identity is **forced**. Two
conditions, and both are required: the identity must follow from structure the document already
states, so there is no author to name and nothing for anybody to sign; and the absence must
discard nothing else the value would have carried. A conversion factor between two identical
units is forced, because the units being equal is what makes it one, and a factor carries
nothing else. A duty fraction of one is **not** forced: a line may run continuously because it
cannot stop, because somebody promised it, or because somebody staffed it, and the absence
loses which. A remainder of zero is forced by a nameplate equal to a demand, and still may not
be an absence, because the absence throws away the sign and the holders.

⛔ And "forced" is a claim about which documents can REACH the absence, so it is only true
where a rule makes it true. A conversion is required wherever the units differ, which leaves an
omitted factor meaning one thing: the units already agree. Where no rule confines an absence to
the forced case, the value belongs in the document.

⭐ **The residue is the honest case, and it is a third operation rather than an exception.** A
selection from a closed set has identity ∅: no buffer absorbed the remainder, nobody sets this
bound, somebody looked for couplings and the layers move independently. Nothing there has a
size, a unit or an author, so nothing is lost by declining the element, and those positions keep
the whole four-member absence vocabulary. §14 is where you can see which ones actually do.

Run it with a loaded database:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example observations
```
