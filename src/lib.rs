//! A schema for describing how a business meets demand: what it committed, what the
//! commitment divides into, and what the division leaves over.
//!
//! Supply arrives in whole units and demand does not. **The whole unit you have to divide by is
//! the modulus**, and the division always leaves something. That leftover splits once, and only
//! once: whole units, which are somebody's decision and move when they decide differently, and a
//! residue that no choice of unit removes. The residue is the subject. The part of it absorbed by
//! the people doing the work has no transaction behind it, so nothing that starts from
//! transactions can see it, and this schema is built so that "nobody measured this" is a claim a
//! sender files rather than a cell they leave blank.
//!
//! Every type here is **generated from the two schemas in `schema/`**, including the
//! documentation: their `xs:documentation` blocks are what you are reading. Change a
//! schema, not this crate, and the types and their docs follow.
//!
//! The schema is the artifact; this crate is a reference implementation of it.
//!
//! The equations the model states are proven in [`proofs`]: each one with a block `cargo test`
//! runs against real documents, and the law or rule that holds it for every document the
//! database loads.
//!
//! The generated types live in [`pm`] and [`asrt`], after the two namespace prefixes:
//! the model itself in [`pm`], and what a second party asserts about a filing in
//! [`asrt`]. One `generate` call emits both, so the types they share are shared.
//!
//! The same bargain covers the examples. `build.rs` reads `examples/` on every build and
//! writes the table below from what it finds, so the roster is the directory rather than a
//! sentence about it. A named list of examples reads like a complete one, which is what makes
//! it dangerous when it stops being one.
#![doc = include_str!(concat!(env!("OUT_DIR"), "/examples.md"))]
#![forbid(unsafe_code)]
// Everything below the `include!` is machine-written: the generator emits a
// `Phantom__` variant per serializer state and unused bindings in the deserializers.
// Allowed deliberately rather than tolerated, so that a warning here means something.
#![allow(dead_code, unused_mut, unused_variables)]
// Same reason, for clippy: `src/lib.rs` contains no hand-written code below this
// line, so every lint here would be a complaint about a code generator. The tests
// are separate compilation units and stay fully linted. `proofs` is the one
// hand-written item, and it is a page with no items of its own.
#![allow(clippy::all)]

// The proofs page, in both languages. Only the English blocks run as doctests: the
// Portuguese page carries the same code, and running it twice would prove nothing twice.
#[doc = include_str!("proofs/README.md")]
#[cfg_attr(not(doctest), doc = include_str!("proofs/README.pt.md"))]
pub mod proofs {}

include!(concat!(env!("OUT_DIR"), "/schema.rs"));
