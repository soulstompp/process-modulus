Where does every row land, and does each law read what it is trusted to?

> **Também disponível em português europeu:** `pt-PT/examples/combinatorics/README.md`.

Many queries sort rows into classes: a verdict for each place a figure is computed, a standing for
each remainder, a question for each blank. This program reads every one of those classifications
and asks what a law reading it can see, and what it cannot. It accuses no filing.

## What it prints

1. **The counting on its own.** Every way of counting rows into classes, for small cases, worked
   out three ways that must agree: by formula, by reading the rows as a query would, and by trying
   every relabelling by hand. This part needs no database.
2. **Which queries compose which**, as rows: how many places use each query, and which parents
   compose the same children. The queries nothing composes are found from the directory, since no
   row can name them.
3. **Every classification against the classes it declares**, empty classes included. An empty
   class is printed for a person to read, never asserted.
4. **Every blank, one question at a time.** Each question about a typed blank is counted against
   the blanks filed in the column it names, by a query built from the catalog that shares nothing
   with the one it checks. A question with nothing filed is printed apart, never counted as
   agreement.
5. **The two pairings of parts**, against the group sizes that fix how many rows each returns.

## What it shows

- **A law that every row lands in one class cannot see a misspelt class.** So the classes are
  declared as types, and a misspelt one fails when the query is parsed, whether or not a row
  reaches it.
- **`GROUP BY` lists the classes some row took, never the ones that exist.** Section 3 starts from
  the declared classes and joins the rows to them, so an empty class comes back as a row with zero.
- **Adding up needs each row counted once, and a union does not.** That is why a query composing
  another twice is ordinary, while a parent reaching one layer twice is a violation.
- **Renaming a class never merges two.** The rows that hold both of two swapped classes are the
  sharpest test of a rule that must not notice a word.

## Running it

It needs the database, reads it, and writes nothing:

```text
DATABASE_URL="postgres://$USER@localhost/process_modulus?host=/var/run/postgresql" \
  cargo run --example combinatorics
```
