//! Two namespaces, several files, and they must agree.
//!
//! Both URIs are provisional. `https://example.invalid/…` is a placeholder for URIs
//! the author controls, and changing them is an edit still to come rather than an
//! oversight. This test makes that edit a checked one.
//!
//! Without it the change fails confusingly: `build.rs` asks the generator for a root
//! element in a namespace that has gone, so the failure is either a wall of missing
//! types or, worse, a schema that silently generates nothing. With it, one assertion
//! names every file still out of step.
//!
//! Each schema's own `targetNamespace` is the authority. Everything else quotes it.

use std::collections::BTreeMap;
use std::fs;

/// Pull the value of `attr="..."` out of `src`, if it is there at all.
///
/// Absence is a real answer here rather than a failure: a document that carries no
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
const INSTANCES: [(&str, &str, &str); 25] = [
    // The same filing in European Portuguese: the same layers and the same argument,
    // declared by a microentity under IES's AnexoASNC instead of US-GAAP.
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
    // A document whose second prefix carries real content. A composition embeds a whole
    // `pm:processModulus`, so most of this file is base-schema elements. It is listed
    // under `asrt` because that is its root; both of its prefixes are checked.
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
    // The stipulations. They are not filings and are never cited as evidence about a
    // business, but they are XML in this repository under these prefixes, and the gate below
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
        "assets/fixtures/every-unserved-excess.xml",
        "pm",
        include_str!("../assets/fixtures/every-unserved-excess.xml"),
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
    (
        "assets/fixtures/every-partial-elimination.xml",
        "asrt",
        include_str!("../assets/fixtures/every-partial-elimination.xml"),
    ),
    (
        "assets/fixtures/every-inverting-elimination.xml",
        "asrt",
        include_str!("../assets/fixtures/every-inverting-elimination.xml"),
    ),
    // An eliminated quantity filed as a derivation, the arm of `pm:StatedEliminatedQuantity`
    // beside a claim and an absence, so the nameplate sum is suspended while the demand sum
    // beside it is owed and exact.
    (
        "assets/fixtures/every-derived-elimination.xml",
        "asrt",
        include_str!("../assets/fixtures/every-derived-elimination.xml"),
    ),
    // A part whose conversion nobody measured: `asrt:Part/factor` filed as a typed absence
    // rather than omitted. The third state of an optional `pm:StatedClaim`, which `pm.part`
    // stores in `factor_absent`.
    (
        "assets/fixtures/every-unsized-conversion.xml",
        "asrt",
        include_str!("../assets/fixtures/every-unsized-conversion.xml"),
    ),
    (
        "assets/fixtures/every-unit-cycle.xml",
        "asrt",
        include_str!("../assets/fixtures/every-unit-cycle.xml"),
    ),
    (
        "assets/fixtures/every-nested-conversion.xml",
        "asrt",
        include_str!("../assets/fixtures/every-nested-conversion.xml"),
    ),
    (
        "assets/fixtures/every-derived-quantity.xml",
        "asrt",
        include_str!("../assets/fixtures/every-derived-quantity.xml"),
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

/// Every prefix a document declares, not only the one it is rooted in.
///
/// A composition embeds a whole `pm:processModulus`, so most of
/// `merge-group-composition.xml` is base-schema elements under a prefix other than its root's.
/// A stale `pm` binding there would leave the entire embedded filing pointing at a namespace
/// the base schema does not declare, while a check of the root prefix alone went on reporting
/// success about the `asrt` half. That is the same shape of failure as
/// `no_example_is_exempt_from_the_namespace_gate` below, one level down.
///
/// The root prefix is still checked on its own, because it must be present. The loop checks
/// only the prefixes a document declares, so a file with no `pm:` content is skipped rather
/// than made to invent a binding.
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
            src.contains("Provisional namespace URI"),
            "{file}: the namespace is still a placeholder, so the schema must say so \
             where a reader will see it. Silently shipping `example.invalid` is how a \
             placeholder becomes permanent"
        );
    }
}

/// The gate above is a hand-written list, so it can stop covering things in silence: a
/// document added to `assets/corpus/` and not to `INSTANCES` is exempt from the namespace
/// check. A list that quietly omits a file is worse than no list, because it reads as
/// coverage.
#[test]
fn no_example_is_exempt_from_the_namespace_gate() {
    // Both directories. A directory of documents the hand-written list does not know about is
    // the same silent exemption as a new file in a known one, and the fixtures are the
    // documents most likely to be forgotten, because they are stipulations rather than filings
    // and a reader skims past them.
    // Sweeping the parent would be wrong: `assets/sql/` holds no XML, and another directory
    // beside it might hold XML that is invalid on purpose. Each directory is opted in by name.
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

/// The crate's major.minor follows the schema's.
///
/// The schema is the artifact and this crate is a rendering of it, so a consumer holding
/// `process-modulus 0.1.x` is entitled to assume it renders schema 0.1.x. The patch digit is
/// the crate's own: a codegen fix or a new test moves it and the schema does not.
///
/// Three places declare a version, and nothing but this holds them together:
/// `xs:schema/@version`, `Cargo.toml`, and the namespace URI ending `/1.0`. The first two are
/// held together here. The third is left out on purpose, because a namespace URI answers a
/// different question: by convention it changes only when documents written against the old
/// one stop being valid, which is why BPMN's has been a fixed date since 2010. What this
/// model's URI carries is an open question, settled with its host rather than in this test.
#[test]
fn the_crate_version_tracks_the_schema_version() {
    // `tests/independence.rs` also reads the manifest, and each test file is its own
    // compilation unit, so sharing the constant would take a shared module. Two readers of
    // one file is the right amount of duplication here: a shared module would couple two
    // tests that are about different properties on purpose.
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

/// Every corpus document with a stack is ingested by `assets/sql/ingest.sql`, or no rule
/// examines it.
///
/// `ingest.sql` names its files one `\set` at a time, which is the right shape, since a glob
/// would load whatever happened to be in the directory. But it means a document added to the
/// corpus and not to this file is checked by the validator and the Rust tests and examined by
/// none of the rules the SQL runs.
///
/// Such a document passes `no_example_is_exempt_from_the_namespace_gate` above and the sweep in
/// `corpus_parse.rs`, and is still missing from every count the SQL makes. This is that gate
/// one directory over, and it needs no database.
#[test]
fn every_corpus_document_is_ingested_by_the_sql() {
    let root = env!("CARGO_MANIFEST_DIR");
    let ingest =
        fs::read_to_string(format!("{root}/assets/sql/ingest.sql")).expect("assets/sql/ingest.sql");

    let dir = format!("{root}/assets/corpus");
    let mut on_disk: Vec<String> = fs::read_dir(&dir)
        .unwrap_or_else(|e| panic!("{dir}: {e}"))
        .map(|e| e.unwrap().file_name().to_string_lossy().into_owned())
        .filter(|n| n.ends_with(".xml"))
        .collect();
    on_disk.sort();

    // Only documents with a stack are in scope. A coverage file, a run record and a
    // dependence statement carry no quantities and have no layer, so there is nothing for a
    // join to do and nothing for a rule to examine.
    let missing: Vec<&String> = on_disk
        .iter()
        .filter(|n| {
            let body = fs::read_to_string(format!("{dir}/{n}")).expect("corpus document");
            body.contains("<pm:stack") && !ingest.contains(&format!("assets/corpus/{n}"))
        })
        .collect();

    assert!(
        missing.is_empty(),
        "these corpus documents are not read by assets/sql/ingest.sql, so every rule in \
         rules.sql silently skips them: {missing:?}"
    );
}

// ── A qualified name in prose is a pointer, and a pointer is followed ──────────────────────

/// Every name a schema declares, and so reachable as `pm:` or `asrt:`: elements and types,
/// plus the identity constraints a `refer=` points at.
///
/// `elementFormDefault="qualified"` on both schemas puts a local element in its schema's
/// namespace too, so `pm:absent` is a name even though `absent` is declared deep inside
/// another type.
fn declared(schema: &str) -> Vec<&str> {
    let mut out = Vec::new();
    for kind in [
        "<xs:element name=\"",
        "<xs:complexType name=\"",
        "<xs:simpleType name=\"",
        "<xs:group name=\"",
        "<xs:attributeGroup name=\"",
        "<xs:key name=\"",
        "<xs:keyref name=\"",
        "<xs:unique name=\"",
    ] {
        let mut rest = schema;
        while let Some(i) = rest.find(kind) {
            rest = &rest[i + kind.len()..];
            let end = rest.find('"').expect("unterminated name");
            out.push(&rest[..end]);
        }
    }
    out
}

/// Every prefixed schema name written in `body`, with the line it sits on.
fn qualified_names(body: &str) -> Vec<(usize, &str, &str)> {
    let bytes = body.as_bytes();
    let mut out = Vec::new();
    for prefix in ["pm:", "asrt:"] {
        let mut at = 0usize;
        while let Some(i) = body[at..].find(prefix) {
            let start = at + i;
            at = start + prefix.len();
            // `xmlns:pm` and `Xpm:` are not references; a leading `/` or `<` is.
            let before = bytes[..start].iter().rev().next().copied().unwrap_or(b' ');
            if before.is_ascii_alphanumeric() || before == b'_' {
                continue;
            }
            let name = &body[at..];
            let len = name
                .find(|c: char| !c.is_ascii_alphanumeric() && c != '_')
                .unwrap_or(name.len());
            if len == 0 || !name.as_bytes()[0].is_ascii_alphabetic() {
                continue;
            }
            let line = body[..start].matches('\n').count() + 1;
            out.push((line, prefix.trim_end_matches(':'), &name[..len]));
        }
    }
    out
}

/// Every tracked file whose prose points at the schemas, under the roots that carry argument.
///
/// `assets/sql/` is out on purpose: it is generated from `assets/sqlc/`, so a finding there
/// is the same finding twice, and it names the copy nobody edits.
fn files_that_cite_the_schemas() -> Vec<String> {
    fn walk(dir: &str, out: &mut Vec<String>) {
        let entries = match fs::read_dir(dir) {
            Ok(e) => e,
            Err(_) => return,
        };
        for entry in entries.flatten() {
            let path = entry.path();
            let name = entry.file_name().to_string_lossy().into_owned();
            if path.is_dir() {
                if name != "plans" && name != "sql" && name != "target" {
                    walk(&path.to_string_lossy(), out);
                }
            } else if ["sqlc", "rs", "md", "ddl", "xsd"]
                .contains(&path.extension().unwrap_or_default().to_string_lossy().as_ref())
            {
                out.push(path.to_string_lossy().into_owned());
            }
        }
    }
    let root = env!("CARGO_MANIFEST_DIR");
    let mut out = Vec::new();
    for sub in [
        "assets/sqlc", "assets/ddl", "assets/fixtures", "conformance", "docs", "examples", "pt-PT",
        "schema", "src", "tests",
    ] {
        walk(&format!("{root}/{sub}"), &mut out);
    }
    for top in ["README.md", "build.rs"] {
        out.push(format!("{root}/{top}"));
    }
    out.sort();
    out
}

/// A `--` line, a `#` header and a doc comment all name schema elements so that a reader can go
/// and read them. A name that resolves to nothing sends them looking for an element that is not
/// there, and the two namespaces make that easy: `Part`, `Fusion` and `Composition` live in
/// `assertion.xsd`, and every type they compose lives in `process-modulus.xsd`.
///
/// It also holds the case, which carries a fact: a capital is a type and a lowercase name is
/// an element. The absence wrapper is the element `pm:absent`, of type `pm:Absence`, so the
/// capitalised spelling of the element is neither, and a reader who searches for it finds
/// nothing.
///
/// And it reaches the XPath in `ingest.sqlc`, the one place a wrong name is more than
/// misleading: a `PATH 'pm:demand/pm:amount'` that names an element the schema does not
/// declare extracts NULL from every document, and the load still succeeds.
#[test]
fn every_qualified_name_in_the_prose_is_one_a_schema_declares() {
    let base = declared(BASE);
    let assertion = declared(ASSERTION);
    assert!(
        base.len() > 100 && assertion.len() > 40,
        "only {} and {} names were read out of the schemas, so the declaration syntax moved and \
         this test is now checking every pointer against almost nothing",
        base.len(),
        assertion.len()
    );

    let root = env!("CARGO_MANIFEST_DIR");
    let mut dangling: Vec<String> = Vec::new();
    for path in files_that_cite_the_schemas() {
        let body = match fs::read_to_string(&path) {
            Ok(b) => b,
            Err(_) => continue,
        };
        let short = path.strip_prefix(root).unwrap_or(&path).trim_start_matches('/');
        for (line, prefix, name) in qualified_names(&body) {
            let known = if prefix == "pm" { &base } else { &assertion };
            if !known.contains(&name) {
                let elsewhere = if prefix == "pm" { &assertion } else { &base };
                let hint = if elsewhere.contains(&name) {
                    let other = if prefix == "pm" { "asrt" } else { "pm" };
                    format!(" (it is `{other}:{name}`)")
                } else {
                    String::new()
                };
                dangling.push(format!("{short}:{line} `{prefix}:{name}`{hint}"));
            }
        }
    }

    assert!(
        dangling.is_empty(),
        "these point at schema names that do not exist, so a reader who follows one finds \
         nothing:\n  {}",
        dangling.join("\n  ")
    );
}
