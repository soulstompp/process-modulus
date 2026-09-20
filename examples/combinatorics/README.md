What can be read off a classification, and does each law here read what it is trusted to?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

## What it does

Every relation in `assets/sqlc/` that sorts rows into classes is a function from its rows to a set
of classes: a verdict per arithmetic site, a standing per remainder, a question per absence, a
child per splice site. What can be read off such a function is a closed problem, the **twelvefold
way** (credited to Gian-Carlo Rota; Stanley, *Enumerative Combinatorics* vol. 1, §1.9): three
conditions on the function crossed with four readings of it.

This program checks that table by a route that knows nothing about this repository, then reads
the repository with it. `soundness` asks whether each set operation computes what it says; this
one asks which part of a function each law actually reads, and so which failures it cannot see.
Neither accuses anybody's filing.

## The table

Balls are rows and boxes are classes: `n` balls, `x` boxes.

| reading | in SQL | any | injective | surjective |
|---|---|---|---|---|
| labelled | the rows | `xⁿ` | `x(x−1)…(x−n+1)` | `x!·S(n,x)` |
| up to the balls | `GROUP BY box, count(*)` | `C(x+n−1, n)` | `C(x, n)` | `C(n−1, x−1)` |
| up to the boxes | a self-join on the box | `Σ_{k≤x} S(n,k)` | `[n ≤ x]` | `S(n,x)` |
| up to both | the profile of the counts | `p_x(n+x)` | `[n ≤ x]` | `p_x(n)` |

- `S(n,k)` counts set partitions into `k` blocks.
- `p_k(m)` counts integer partitions of `m` into `k` parts.
- Injective means at most one row per class; surjective means every class is used.

### How the table is checked

Section 1 of the program checks every cell for every `n` and `x` from 0 to 4, three ways:

1. the closed form;
2. the number of distinct values of the reading, computed the way the SQL computes it;
3. the number of orbits, found by applying every permutation of the balls and the boxes by brute
   force.

It also checks, function by function, that every reading is constant on each orbit and separates
any two. So a `GROUP BY … count(*)` reads a function exactly up to renaming its rows, a self-join
exactly up to renaming its classes, and neither can see what the other throws away.

## What follows from the table

### A partition law says nothing about the classes

"Every row in exactly one class" survives any renaming of the classes, a misspelt one included. A
class misspelt in one arm passes such a law, and any tally that selects classes by name then drops
it. The `not comparable` count that `examples/readiness/main.rs` pins at zero is one such tally.

The set of classes is part of the function. The classes the queries sort into are enums in schema
`public`, and a literal cast to an enum is checked when the query is parsed, so a misspelt class
fails on every run whether or not any row reaches its arm.

### `GROUP BY` cannot show an empty class

`GROUP BY` lists the classes some row took, never the classes that exist: it reads a function onto
its image. An empty class has nowhere to appear, and an empty class is often the finding. Drive
from the declared set and `LEFT JOIN` the rows, counting a column of the rows rather than `*`, and
the zero becomes a row. Section 3 does this for every classification.

### A sum needs the function to be injective; a union does not

`Σ_rows w(f(row)) = Σ_class |f⁻¹(class)|·w(class)`.

- Under an idempotent fold (a union, `max`, `bool_or`, `EXISTS`) the multiplicity of each class
  vanishes and only the image counts.
- Under `+` every multiplicity counts, and the excess over the image is `Σ (k − 1)·w`.

That excess is the elimination `e` in `x_composed = Σ x_parts − e`. It is why a template composing
a child twice is ordinary while a fusion reaching one layer twice is a violation: a query is
idempotent and a supply is not.

### A self-join's size is fixed by its group sizes

On a key whose groups have sizes `k`, a self-join returns:

| pairing | rows |
|---|---|
| ordered, reflexive pair kept | `Σ k²` |
| ordered, reflexive pair dropped | `Σ k(k−1)` |
| unordered, each pair once | `Σ C(k,2)` |

A pair is not a double count once a group holds three. Summing every total that shares a part
counts it `k` times, an excess of `k − 1` over counting it once, while the pairs number `C(k,2)`;
the excess and the pairs agree only when `k` is 1 or 2. Proven in `src/proofs/README.md`, entries
`self_join_sizes` and `excess`.

### A relabelling never merges

A relabelling is a permutation of the classes. Swapping two classes on a row that holds both
exchanges their words and keeps every figure. Those rows are the sharpest test of a claim that a
rule must not notice the word, because they are the only rows where a rule could compare the two.

## The sections

1. **The table itself**, three ways. This part needs no database.
2. **The compositions**: the compose DAG read as *splice site → template*. It prints the edges,
   how many sites land in each template, which parents compose an identical set of children, and
   the profile. The templates nothing composes are found by reading the directory, because no edge
   can name them.
3. **Every classification against the classes it declares**, empty classes included. It asserts
   that every class set declared in schema `public` is read here, taking that list from the
   catalog. An empty class is printed as a referral, never asserted.
4. **The absence census, one question at a time.** `epistemics/absences.sqlc` claims every typed
   absence in the schema, and `reports/integrity.sqlc` holds its roster of questions against every
   column of type `absence_reason`. This section counts each question's rows against the absences
   filed in the column it names, using a query built from the catalog that shares nothing with the
   arm it checks. A question with nothing filed is zero against zero, and is printed apart rather
   than counted as agreement.
5. **The two self-joins of `F`**, against the group sizes that fix their row counts. Both relations
   argue their join condition in their headers, and this section is what makes those statements
   fail when the condition changes.

## Running it

It needs the proof database. It reads that database and writes nothing.
