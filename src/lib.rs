//! A schema for expressing a business process flow truthfully and evaluatably.
//!
//! Every type here is **generated from the two schemas in `schema/`**, including the
//! documentation: their `xs:documentation` blocks are what you are reading. Change a
//! schema, not this crate, and the types and their docs follow.
//!
//! The schema is the artifact; this crate is a reference implementation of it.
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
// are separate compilation units and stay fully linted.
#![allow(clippy::all)]

include!(concat!(env!("OUT_DIR"), "/schema.rs"));
