//! A schema for expressing a business process flow truthfully and evaluatably.
//!
//! Every type here is **generated from `schema/process-modulus.xsd`**, including the
//! documentation: the schema's `xs:documentation` blocks are what you are reading.
//! Change the schema, not this crate, and the types and their docs follow.
//!
//! The schema is the artifact; this crate is a reference implementation of it.
//!
//! The generated types live in [`pm`], after the schema's namespace prefix.
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
