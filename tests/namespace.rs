//! Two namespaces, several files, and they must agree.
//!
//! ⚠️ BOTH URIs ARE PROVISIONAL. `https://example.invalid/…` is a placeholder for URIs
//! the author controls, and changing them is a deliberate future edit rather than an
//! oversight. This test exists so that the edit is a CHECKED one.
//!
//! Without it the change fails confusingly: `build.rs` asks the generator for a root
//! element in a namespace that no longer exists, so the failure is either a wall of
//! missing types or, worse, a schema that silently generates nothing. With it, one
//! assertion names every file still out of step.
//!
//! Each schema's own `targetNamespace` is the authority. Everything else quotes it.

use std::collections::BTreeMap;
use std::fs;

/// Pull the value of `attr="..."` out of `src`, once.
fn attr_value<'a>(src: &'a str, attr: &str) -> &'a str {
    let needle = format!("{attr}=\"");
    let start = src
        .find(&needle)
        .unwrap_or_else(|| panic!("no `{attr}=\"...\"` found"))
        + needle.len();
    let rest = &src[start..];
    let end = rest.find('"').expect("unterminated attribute value");
    &rest[..end]
}

const BASE: &str = include_str!("../schema/process-modulus.xsd");
const ASSERTION: &str = include_str!("../schema/assertion.xsd");
const BUILD_RS: &str = include_str!("../build.rs");

/// Every instance, and the prefix whose namespace it must match.
const INSTANCES: [(&str, &str, &str); 7] = [
    (
        "examples/enterprise-contract.xml",
        "pm",
        include_str!("../examples/enterprise-contract.xml"),
    ),
    (
        "examples/refutation.xml",
        "pm",
        include_str!("../examples/refutation.xml"),
    ),
    (
        "examples/unstated.xml",
        "pm",
        include_str!("../examples/unstated.xml"),
    ),
    (
        "examples/coverage-us-gaap.xml",
        "asrt",
        include_str!("../examples/coverage-us-gaap.xml"),
    ),
    (
        "examples/coverage-pt-ncrf-pe.xml",
        "asrt",
        include_str!("../examples/coverage-pt-ncrf-pe.xml"),
    ),
    (
        "examples/dependence-group-consolidation.xml",
        "asrt",
        include_str!("../examples/dependence-group-consolidation.xml"),
    ),
    (
        "examples/run-2026-08-30.xml",
        "asrt",
        include_str!("../examples/run-2026-08-30.xml"),
    ),
];

fn namespaces() -> BTreeMap<&'static str, &'static str> {
    BTreeMap::from([
        ("pm", attr_value(BASE, "targetNamespace")),
        ("asrt", attr_value(ASSERTION, "targetNamespace")),
    ])
}

#[test]
fn each_schema_binds_its_own_prefix_to_its_own_target_namespace() {
    for (prefix, src, file) in [
        ("pm", BASE, "process-modulus.xsd"),
        ("asrt", ASSERTION, "assertion.xsd"),
    ] {
        let target = attr_value(src, "targetNamespace");
        assert!(!target.is_empty(), "{file}: no target namespace");
        assert_eq!(
            attr_value(src, &format!("xmlns:{prefix}")),
            target,
            "{file}: `xmlns:{prefix}` and `targetNamespace` disagree, so every \
             `{prefix}:` reference inside it points somewhere else"
        );
    }
}

#[test]
fn the_assertion_schema_imports_the_namespace_the_base_actually_declares() {
    let ns = namespaces();
    assert_eq!(
        attr_value(ASSERTION, "xs:import namespace"),
        ns["pm"],
        "assertion.xsd imports a namespace the base schema does not declare, so \
         `pm:BorrowedTerm` resolves to nothing and the shared types stop being shared"
    );
}

#[test]
fn build_rs_names_both_namespaces_exactly() {
    for (prefix, ns) in namespaces() {
        assert!(
            BUILD_RS.contains(&format!("b\"{ns}\"")),
            "build.rs has no byte string for the `{prefix}` namespace ({ns}). The \
             generator will find no root element there and emit no types for it, \
             quietly, which is the failure mode this test exists for"
        );
    }
}

#[test]
fn every_instance_declares_the_schema_it_validates_against() {
    let ns = namespaces();
    for (name, prefix, src) in INSTANCES {
        assert_eq!(
            attr_value(src, &format!("xmlns:{prefix}")),
            ns[prefix],
            "{name}: declares a different `{prefix}` namespace than the schema, so it \
             will not validate against it"
        );
    }
}

/// The placeholder is loud on purpose. When it goes, this test goes quiet with it.
#[test]
fn provisional_uris_are_still_flagged_as_provisional() {
    for (src, file) in [(BASE, "process-modulus.xsd"), (ASSERTION, "assertion.xsd")] {
        if !attr_value(src, "targetNamespace").contains("example.invalid") {
            continue; // real now; nothing to warn about
        }
        assert!(
            src.contains("PROVISIONAL NAMESPACE URI"),
            "{file}: the namespace is still a placeholder, so the schema must say so \
             where a reader will see it. Silently shipping `example.invalid` is how a \
             placeholder becomes permanent"
        );
    }
}

/// ⛔ THE GATE ABOVE IS A HAND-WRITTEN LIST, SO IT CAN SILENTLY STOP COVERING THINGS.
/// It did: `unstated.xml` was added to `examples/` and not to `INSTANCES`, which left
/// the one document exercising `Regime/chart` as the one document exempt from the
/// namespace check. A list that quietly omits a file is worse than no list, because it
/// reads as coverage.
#[test]
fn no_example_is_exempt_from_the_namespace_gate() {
    let dir = format!("{}/examples", env!("CARGO_MANIFEST_DIR"));
    let mut on_disk: Vec<String> = fs::read_dir(&dir)
        .unwrap_or_else(|e| panic!("{dir}: {e}"))
        .map(|e| format!("examples/{}", e.unwrap().file_name().to_string_lossy()))
        .filter(|n| n.ends_with(".xml"))
        .collect();
    on_disk.sort();

    let mut listed: Vec<String> = INSTANCES.iter().map(|(n, _, _)| n.to_string()).collect();
    listed.sort();

    assert_eq!(
        on_disk, listed,
        "every document in examples/ must be in INSTANCES, or it is not checked at all"
    );
}
