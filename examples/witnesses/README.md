Whether each rule has ever been SEEN TO SAY NO.

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

⭐⭐⭐ THE OTHER EXAMPLES ASK WHETHER THE RULES ARE RIGHT. THIS ONE ASKS WHETHER THEY CAN BE
   WRONG. The `soundness` example checks that each query computes what it claims and `readiness`
   checks that each rule has a population, and a rule can pass both while being incapable
   of failing: a predicate true by construction examines a thousand rows and concludes
   nothing. Measured before this file existed, the corpus and fixtures put 22 of 24 rules
   over real rows and NOT ONE RULE HAD EVER BEEN OBSERVED TO FIRE. The violated column of
   the rule x {passed, violated} matrix was empty end to end.

⭐⭐ A WITNESS IS A MINIMAL MUTATION OF A REAL FILING THAT TRIPS EXACTLY ONE RULE. Minimal
   matters: a mutation that trips six rules has shown that something is checked, not that
   THIS rule is. Each is a single string substitution against a corpus or fixture document,
   and the mutant must still validate against the XSD, because a document the grammar
   rejects proves nothing about a rule the grammar never reaches.

⛔ A RULE WITH NO WITNESS IS THE FINDING AND NOT A GAP IN THIS FILE. Two have none, and
   they are exactly the two that examine nothing: `share_exceeds_slack` and
   `exposure_unaccounted`. That is not a coincidence and it is the useful half of the
   result. A rule can only be falsified where it has rows, so an empty population and an
   unfalsifiable rule are one fact seen from two sides, and no edit to a document these
   rules do not look at will ever produce a witness.

⚠️ SUBSTITUTION, NOT ADDITION. The mutant REPLACES its source document in the ingest rather
   than joining it, so the corpus keeps its shape: same thirteen filings, same notation
   URNs, same part references. Adding a mutated copy would collide on `filing_identity`
   and would change what every composition rule is looking at.

⚠️ AND THE ANCHOR COUNT IS ASSERTED. Each witness names the occurrence it edits and this
   file checks how many there are. A document edit that changes the count fails loudly
   here rather than silently mutating a different claim and still going green.

Run it with:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
    cargo run --example witnesses
```
