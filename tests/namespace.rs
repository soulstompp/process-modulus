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

/// Pull the value of `attr="..."` out of `src`, if it is there at all.
///
/// ⚠️ Absence is a real answer here rather than a failure: a document that carries no
/// `pm:` content declares no `pm:` prefix, and asking it to is how a gate starts
/// demanding invented values.
fn attr_value_opt<'a>(src: &'a str, attr: &str) -> Option<&'a str> {
    let needle = format!("{attr}=\"");
    let start = src.find(&needle)? + needle.len();
    let rest = &src[start..];
    let end = rest.find('"').expect("unterminated attribute value");
    Some(&rest[..end])
}

/// Pull the value of `attr="..."` out of `src`, once.
fn attr_value<'a>(src: &'a str, attr: &str) -> &'a str {
    attr_value_opt(src, attr).unwrap_or_else(|| panic!("no `{attr}=\"...\"` found"))
}

const BASE: &str = include_str!("../schema/process-modulus.xsd");
const ASSERTION: &str = include_str!("../schema/assertion.xsd");
const BUILD_RS: &str = include_str!("../build.rs");

/// Every instance, and the prefix whose namespace it must match.
const INSTANCES: [(&str, &str, &str); 17] = [
    // The same filing in European Portuguese: same three layers, same argument, declared
    // by a microentity under IES's AnexoASNC instead of US-GAAP.
    (
        "assets/corpus/contrato-empresarial.xml",
        "pm",
        include_str!("../assets/corpus/contrato-empresarial.xml"),
    ),
    (
        "assets/corpus/enterprise-contract.xml",
        "pm",
        include_str!("../assets/corpus/enterprise-contract.xml"),
    ),
    (
        "assets/corpus/refutation.xml",
        "pm",
        include_str!("../assets/corpus/refutation.xml"),
    ),
    (
        "assets/corpus/unstated.xml",
        "pm",
        include_str!("../assets/corpus/unstated.xml"),
    ),
    (
        "assets/corpus/merge-us-member.xml",
        "pm",
        include_str!("../assets/corpus/merge-us-member.xml"),
    ),
    (
        "assets/corpus/merge-pt-member.xml",
        "pm",
        include_str!("../assets/corpus/merge-pt-member.xml"),
    ),
    (
        "assets/corpus/coverage-us-gaap.xml",
        "asrt",
        include_str!("../assets/corpus/coverage-us-gaap.xml"),
    ),
    (
        "assets/corpus/coverage-pt-ncrf-pe.xml",
        "asrt",
        include_str!("../assets/corpus/coverage-pt-ncrf-pe.xml"),
    ),
    (
        "assets/corpus/dependence-group-consolidation.xml",
        "asrt",
        include_str!("../assets/corpus/dependence-group-consolidation.xml"),
    ),
    (
        "assets/corpus/run-2026-08-30.xml",
        "asrt",
        include_str!("../assets/corpus/run-2026-08-30.xml"),
    ),
    // ⚠️ THE FIRST DOCUMENT WHOSE SECOND PREFIX CARRIES REAL CONTENT, and the reason the
    // gate below stopped checking one prefix per file. A composition embeds a whole
    // `pm:processModulus`, so most of this file is base-schema elements. It is listed
    // under `asrt` because that is its ROOT; both of its prefixes are checked.
    (
        "assets/corpus/merge-group-composition.xml",
        "asrt",
        include_str!("../assets/corpus/merge-group-composition.xml"),
    ),
    (
        "assets/corpus/merge-holding-composition.xml",
        "asrt",
        include_str!("../assets/corpus/merge-holding-composition.xml"),
    ),
    // ⭐ The stipulations. They are not filings and must never be cited as evidence about a
    // business — but they are XML in this repository under these prefixes, and the gate below
    // is about bindings rather than about standing.
    (
        "assets/fixtures/every-absence.xml",
        "pm",
        include_str!("../assets/fixtures/every-absence.xml"),
    ),
    (
        "assets/fixtures/every-draft.xml",
        "pm",
        include_str!("../assets/fixtures/every-draft.xml"),
    ),
    (
        "assets/fixtures/every-claimed.xml",
        "asrt",
        include_str!("../assets/fixtures/every-claimed.xml"),
    ),
    (
        "assets/fixtures/every-elimination.xml",
        "asrt",
        include_str!("../assets/fixtures/every-elimination.xml"),
    ),
    (
        "assets/fixtures/every-local-part.xml",
        "asrt",
        include_str!("../assets/fixtures/every-local-part.xml"),
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

/// ⛔⛔ EVERY PREFIX A DOCUMENT DECLARES, NOT ONLY THE ONE IT IS ROOTED IN.
///
/// Checking the root prefix alone was enough while every document lived in one namespace
/// from top to bottom. `merge-group-composition.xml` ended that: a composition EMBEDS A
/// WHOLE `pm:processModulus`, so most of that file is base-schema elements under a prefix
/// this gate was not looking at. A stale `pm` binding there would have left the entire
/// embedded filing pointing at a namespace the base schema no longer declares, while this
/// test went on reporting success about the `asrt` half — which is the same shape of
/// failure as `no_example_is_exempt_from_the_namespace_gate` below, one level down.
///
/// ⭐ The root prefix is still checked separately, because it must be PRESENT. The loop
/// only checks prefixes a document actually declares, so a file with no `pm:` content is
/// skipped rather than made to invent a binding.
#[test]
fn every_instance_declares_the_schema_it_validates_against() {
    let ns = namespaces();
    for (name, root, src) in INSTANCES {
        assert_eq!(
            attr_value_opt(src, &format!("xmlns:{root}")),
            Some(ns[root]),
            "{name}: is rooted in `{root}:` and does not bind that prefix to the \
             namespace its schema declares, so it will not validate against it"
        );

        for (prefix, uri) in &ns {
            let Some(declared) = attr_value_opt(src, &format!("xmlns:{prefix}")) else {
                continue;
            };
            assert_eq!(
                declared, *uri,
                "{name}: binds `{prefix}:` to `{declared}`, and that is not the namespace \
                 the `{prefix}` schema declares as its target. Every element under that \
                 prefix in this document resolves to nothing — including, in a \
                 composition, the whole embedded filing"
            );
        }
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
/// It did: `unstated.xml` was added to `assets/corpus/` and not to `INSTANCES`, which left
/// the one document exercising `Regime/chart` as the one document exempt from the
/// namespace check. A list that quietly omits a file is worse than no list, because it
/// reads as coverage.
#[test]
fn no_example_is_exempt_from_the_namespace_gate() {
    // ⛔⛔ BOTH DIRECTORIES, AND `assets/fixtures/` IS EXACTLY THE CASE THIS TEST WAS WRITTEN
    // FOR, ARRIVING A SECOND TIME. A new directory of documents that the hand-written list
    // does not know about is the same silent exemption as a new file in an old one — and the
    // fixtures are the documents MOST likely to be forgotten, because they are stipulations
    // rather than filings and a reader skims past them.
    // ⚠️ Sweeping the parent would be wrong: `assets/sql/` holds no XML and a future sibling
    // might hold XML that is deliberately invalid. Each directory is opted in by name.
    let mut on_disk: Vec<String> = Vec::new();
    for sub in ["corpus", "fixtures"] {
        let dir = format!("{}/assets/{sub}", env!("CARGO_MANIFEST_DIR"));
        on_disk.extend(
            fs::read_dir(&dir)
                .unwrap_or_else(|e| panic!("{dir}: {e}"))
                .map(|e| format!("assets/{sub}/{}", e.unwrap().file_name().to_string_lossy()))
                .filter(|n| n.ends_with(".xml")),
        );
    }
    on_disk.sort();

    let mut listed: Vec<String> = INSTANCES.iter().map(|(n, _, _)| n.to_string()).collect();
    listed.sort();

    assert_eq!(
        on_disk, listed,
        "every document in assets/corpus/ and assets/fixtures/ must be in INSTANCES, or it is \
         not checked at all"
    );
}

/// The schema's own `version`, read off the `<xs:schema>` element rather than the XML
/// declaration one line above it, which is always `1.0` and means something else entirely.
fn schema_version(src: &str, what: &str) -> (u32, u32) {
    let after = src
        .split_once("<xs:schema")
        .unwrap_or_else(|| panic!("{what}: no <xs:schema> element"))
        .1;
    let element = after
        .split_once('>')
        .unwrap_or_else(|| panic!("{what}: unterminated <xs:schema> element"))
        .0;
    let v = element
        .split_once("version=\"")
        .unwrap_or_else(|| panic!("{what}: <xs:schema> carries no version attribute"))
        .1
        .split_once('"')
        .unwrap()
        .0;
    let mut parts = v.split('.');
    let major = parts.next().and_then(|p| p.parse().ok());
    let minor = parts.next().and_then(|p| p.parse().ok());
    match (major, minor) {
        (Some(a), Some(b)) => (a, b),
        _ => panic!("{what}: version {v:?} is not major.minor.patch"),
    }
}

/// ⛔⛔ THE CRATE'S major.minor LOCKS TO THE SCHEMA'S, AND UNTIL THIS TEST NOTHING SAID SO.
///
/// The schema is the artifact and this crate is a rendering of it, so a consumer holding
/// `process-modulus 0.1.x` is entitled to assume it renders schema 0.1.x. The patch digit is
/// the crate's own: a codegen fix or a new test moves it and the schema does not.
///
/// ⚠️ THREE PLACES DECLARED A VERSION AND ALL THREE DISAGREED when this was written.
/// `xs:schema/@version` said `0.1.0`, `Cargo.toml` said `0.0.1`, and the namespace URI ends
/// `/1.0`. The first two are locked here. The third is deliberately NOT, because a namespace
/// URI answers a different question — by convention it changes only when documents written
/// against the old one stop being valid, which is why BPMN's has been a fixed date since 2010.
/// Deciding what this model's URI carries is a live question and belongs with settling the
/// host, not with this test.
#[test]
fn the_crate_version_tracks_the_schema_version() {
    // ⚠️ `tests/independence.rs` also reads the manifest, and each test file is its own
    // compilation unit, so the constant cannot be shared. Two readers of one file is the
    // right amount of duplication here: the alternative is a shared module that couples
    // two tests which are deliberately about different properties.
    const MANIFEST: &str = include_str!("../Cargo.toml");

    let cargo_v = MANIFEST
        .lines()
        .find_map(|l| {
            let l = l.trim();
            l.strip_prefix("version")?
                .trim_start()
                .strip_prefix('=')?
                .trim()
                .strip_prefix('"')?
                .split_once('"')
                .map(|(v, _)| v)
        })
        .expect("Cargo.toml declares no package version");
    let mut parts = cargo_v.split('.');
    let crate_mm: (u32, u32) = (
        parts.next().unwrap().parse().unwrap(),
        parts.next().unwrap().parse().unwrap(),
    );

    let pm = schema_version(
        include_str!("../schema/process-modulus.xsd"),
        "process-modulus.xsd",
    );
    let asrt = schema_version(include_str!("../schema/assertion.xsd"), "assertion.xsd");

    assert_eq!(
        pm, asrt,
        "the two schemas are published together and must carry one version between them; \
         process-modulus.xsd says {pm:?} and assertion.xsd says {asrt:?}"
    );
    assert_eq!(
        crate_mm, pm,
        "the crate is {}.{} and the schema is {}.{}. The crate renders the schema, so a \
         consumer holding one is entitled to assume the other. Move both or neither; the \
         patch digit is the crate's alone",
        crate_mm.0, crate_mm.1, pm.0, pm.1
    );
}
