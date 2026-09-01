//! Generate the Rust types from `schema/process-modulus.xsd`.
//!
//! The schema is the source of truth for the types AND for their documentation:
//! `RendererFlags`'s five doc flags emit every `xs:documentation` block as rustdoc,
//! so the annotations in the schema are what `cargo doc` shows.

use std::fs::write;
use std::path::PathBuf;

use anyhow::{Context, Error};
use xsd_parser::config::{
    GeneratorFlags, InterpreterFlags, NamespaceIdent, OptimizerFlags, RendererFlags,
};
use xsd_parser::{generate, Config, IdentType};

const MODEL_NS: &[u8] = b"https://example.invalid/process-flow/1.0";
const ASSERTION_NS: &[u8] = b"https://example.invalid/assertion/1.0";

fn main() -> Result<(), Error> {
    let out_dir = env_path("OUT_DIR");
    let schema_dir = env_path("CARGO_MANIFEST_DIR")
        .canonicalize()
        .context("Missing CARGO_MANIFEST_DIR")?
        .join("schema");

    // Two schemas, ONE generate call. `assertion.xsd` xs:imports the base, so a
    // second call would emit the base's types twice under two module trees and the
    // shared BorrowedTerm would stop being shared.
    let mut schemas = Vec::new();
    for name in ["process-modulus.xsd", "assertion.xsd"] {
        println!("cargo:rerun-if-changed=schema/{name}");
        schemas.push(
            schema_dir
                .join(name)
                .canonicalize()
                .with_context(|| format!("Missing or invalid schema file: {name}"))?,
        );
    }

    let config = Config::default()
        .with_schemas(schemas)
        .set_interpreter_flags(InterpreterFlags::all() - InterpreterFlags::WITH_NUM_BIG_INT)
        .set_optimizer_flags(OptimizerFlags::all())
        .set_generator_flags(GeneratorFlags::all() - GeneratorFlags::ADVANCED_ENUMS)
        // Every xs:documentation block becomes rustdoc.
        .set_renderer_flags(RendererFlags::all())
        // The generator derives only Debug. A consumer of this model compares
        // documents and holds values taken out of them, so the enums in particular
        // are unusable without PartialEq. Eq is not available: Claim holds f64.
        .with_derive(["Debug", "Clone", "PartialEq"])
        .with_quick_xml()
        .with_generate([
            (
                IdentType::Element,
                NamespaceIdent::namespace(MODEL_NS),
                "processModulus",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "coverage",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "run",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "dependence",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "composition",
            ),
        ]);

    write(out_dir.join("schema.rs"), generate(config)?.to_string())?;
    Ok(())
}

fn env_path(var: &str) -> PathBuf {
    PathBuf::from(std::env::var(var).unwrap_or_else(|_| panic!("Missing `{var}`")))
}
