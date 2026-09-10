Does a run of the model file at all?

> **Também disponível em português europeu:** `README.pt.md`, nesta pasta.

`examples/resolution/main.rs` measures what an instrument throws away, but it measures it in a
struct this repository invented for the purpose. Nothing about that reaches the schema. This
one takes the same readings, writes them out as `pm:processModulus`, and puts them through the
two gates every document in `assets/corpus/` goes through: `xmllint` against the XSD, and the
conformance rules in `assets/sql/checks/`.

⭐⭐⭐ THE POINT IS NOT THAT A GENERATED FILE VALIDATES. It is that a simulator written by
other people for other reasons, driven by a bench that knows nothing about accounting, fills
these fields WITHOUT STRAIN. `tests/independence.rs` holds that corroboration between two
things sharing a code path is worth nothing; `examples/matrices/main.rs` corroborates the
arithmetic. This is what corroborates the MODELLING. A field that has to be bent to take a
simulated fact is a finding about the field.

⛔⛔ AND THE SECOND FILING IS THE ONE TO WATCH. Every run is filed twice, once from the whole
history and once from what a stock-and-flow log records. The blinder filing is not a worse
document, it is a HONEST REPORT OF LESS. If the rules accuse it, they are accusing a filer for
not owning an instrument, which is the failure mode `a rule that fires on a correct filing`
exists to hunt. Zero violations on both is the schema's typed absences doing their whole job.

Run it against a loaded database:

```text
DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
  cargo run --example generation
```

⛔ There is no silent skip. No database means it fails to run. The ingest below happens
   inside a transaction that is ROLLED BACK, so a loaded corpus is left exactly as it was.
