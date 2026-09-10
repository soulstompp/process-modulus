Before the arithmetic: may you compute here at all?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

`xmllint` says a filing is well formed. `assets/sql/checks/` says it does not contradict
the model. Neither answers the question this program asks, which is whether the numbers in
front of you can be put together at all, whether both operands were stated, and whether
they are numbers of the same thing.

⭐⭐⭐ THE COLUMN THAT MATTERS IS THE EMPTY ONE. `arithmetic/roster.sqlc` names every place
this model combines two magnitudes and, beside each, the rule that checks they are
commensurable. Six of the nine are blank, a seventh is `(forbidden)`, and two name a rule.
`r = n − d` is one of the blank ones: thirty-nine layers
deep, and `layers/remainder.sqlc` carries `d_unit` and `n_unit` as two separate columns and
subtracts across them with no predicate anywhere.

⛔ A BLANK GUARD BESIDE A ZERO IS NOT A PASS. Every unguarded site is clean in this corpus
today, which is precisely the state that reads as safe and is not. `NOT CHECKED` is printed
as `not checked`, never as `ok`, and that distinction is the whole reason this example
exists.

⭐⭐ SUSPENDED IS A THIRD OUTCOME BESIDE PASSED AND FAILED. Ninety-one instances cannot be
computed because somebody declined to measure an operand. That is not a defect in the
document and not a pass either, and the gated relations cannot report it: a row dropped by
a `WHERE` cannot say why it went.

Run it with a loaded database:

```text
psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example readiness
```

⛔ There is no silent skip. No database means it fails to run.
