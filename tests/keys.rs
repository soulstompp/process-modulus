//! Every key in `assets/ddl/schema.ddl`, and the ground it stands on.
//!
//! A primary key or a unique constraint is a claim that two rows with the same values are the same
//! thing. Where the XSD makes that claim, the key is its image. Where the XSD admits two and the
//! database keeps one, a key is either a refusal no document should meet or, worse, a `DISTINCT`
//! that merges them: an operation's label was keyed here and in no schema, and two operations
//! sharing a label loaded as one operation carrying both operations' draws.
//!
//! ⛔ So every key names its ground, and the ground is checked: an XSD identity constraint that
//! exists, document order, a child the XSD admits once, or a table that is not read from a document.
//! A key added with no ground fails here, and so does an XSD key over a loaded document that has no
//! key here.

use std::collections::BTreeSet;
use std::fs;

const PM: &str = "process-modulus.xsd";
const ASRT: &str = "assertion.xsd";

/// Why two rows with the same key values are the same thing.
#[derive(Debug)]
enum Ground {
    /// The XSD's own identity constraints, by schema file and name.
    Xsd(&'static [(&'static str, &'static str)]),
    /// Document order: the Nth element, read with `FOR ORDINALITY`.
    Positional,
    /// The XSD admits at most one such element in its parent.
    OnePer(&'static str),
    /// Not read from a document at all.
    Outside(&'static str),
}
use Ground::{OnePer, Outside, Positional, Xsd};

/// Every key in the DDL, as (table, `primary` or `unique`, columns), with its ground.
const KEYS: &[(&str, &str, &str, Ground)] = &[
    ("public.compose_edge", "primary", "parent, child", Outside("the compose DAG, one row per parent and child template")),
    ("source", "primary", "name", Outside("one row per document file loaded, by its name")),
    ("filing", "primary", "name", OnePer("root element per document")),
    ("regime", "primary", "filing, seq", Positional),
    ("regime", "unique", "filing, id", Xsd(&[(PM, "regimeId")])),
    ("composition_regime", "primary", "composition, seq", Positional),
    ("composition_regime", "unique", "composition, id", Xsd(&[(ASRT, "compositionRegimeId")])),
    ("layer", "primary", "filing, layer", Xsd(&[(PM, "layerName"), (ASRT, "composedLayerName")])),
    ("nameplate", "primary", "filing, layer", OnePer("`supply` per layer and `nameplate` per supply")),
    ("claim", "primary", "filing, seq", Positional),
    ("narrowing", "primary", "filing, seq", OnePer("`narrowsWhen` per claim, keyed by the claim's position")),
    ("bound_origin", "primary", "filing, seq", OnePer("`boundOrigin` per claim, keyed by the claim's position")),
    ("absence", "primary", "filing, seq", Positional),
    ("derivation", "primary", "filing, seq", Positional),
    ("slack", "primary", "filing, layer, buffer", OnePer("each of the three slack elements per layer")),
    ("holder", "primary", "filing, layer, kind", Xsd(&[(PM, "holderKind")])),
    ("operation", "primary", "filing, label", Xsd(&[(PM, "operationLabel")])),
    ("draw", "primary", "filing, operation, layer", Xsd(&[(PM, "operationDraw")])),
    ("induction", "primary", "filing, operation, layer", Xsd(&[(PM, "operationInduction")])),
    ("stack_scope", "primary", "filing", OnePer("`scope` per stack, and one stack per document")),
    ("coupling_search", "primary", "filing", OnePer("`couplings` per stack")),
    ("coupling", "primary", "filing, from_layer, to_layer", Xsd(&[(PM, "couplingPair")])),
    ("buffer_term", "primary", "taxonomy, value", Outside("a reader's mapping between vocabularies")),
    ("filing_identity", "primary", "filing", OnePer("`notation` per document")),
    ("filing_identity", "unique", "notation", Outside("across documents: one notation names one filing, which no single document's schema can say")),
    ("fusion", "primary", "composition, composed_layer", Xsd(&[(ASRT, "fusionTarget")])),
    ("part", "primary", "composition, composed_layer, part_filing, part_layer", Xsd(&[(ASRT, "partIdentity")])),
    ("part", "unique", "composition, part_filing, part_layer", Xsd(&[(ASRT, "partIdentity")])),
    ("elimination_search", "primary", "composition, composed_layer", OnePer("`eliminations` per fusion")),
    ("elimination", "primary", "composition, composed_layer, quantity", Xsd(&[(ASRT, "eliminationAgainst")])),
    ("elimination_between", "primary", "composition, composed_layer, quantity, seq", Positional),
    ("elimination_between", "unique", "composition, composed_layer, quantity, notation, layer", Xsd(&[(ASRT, "betweenLayer")])),
    ("composition_citation", "primary", "composition, seq", Positional),
];

/// XSD identity constraints over documents the ingest does not load, so no key here images them.
const NOT_LOADED: &[(&str, &str, &str)] = &[
    (ASRT, "resultKey", "a `run` document"),
    (ASRT, "entryKey", "a `coverage` document"),
    (ASRT, "regimeId", "a `coverage` document; the loaded `regimeId` is process-modulus.xsd's"),
    (ASRT, "dependenceRegimeId", "a `dependence` document"),
    (ASRT, "dependencePair", "a `dependence` document"),
];

fn read(rel: &str) -> String {
    let path = format!("{}/{rel}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

fn columns(list: &str) -> String {
    list.split(',').map(str::trim).collect::<Vec<_>>().join(", ")
}

/// Every `PRIMARY KEY` and `UNIQUE` in a DDL text, table level or column level.
fn ddl_keys(ddl: &str) -> BTreeSet<(String, String, String)> {
    let text: String = ddl
        .lines()
        .map(|l| l.split("--").next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");
    let mut keys = BTreeSet::new();
    let mut rest = text.as_str();
    while let Some(i) = rest.find("CREATE TABLE ") {
        rest = &rest[i + "CREATE TABLE ".len()..];
        let name_end = rest.find(|c: char| c == '(' || c.is_whitespace()).expect("a table name");
        let table = rest[..name_end].to_string();
        let body = &rest[..rest.find("\n);").expect("a table body")];
        for (marker, kind) in [("PRIMARY KEY", "primary"), ("UNIQUE", "unique")] {
            let mut scan = body;
            while let Some(j) = scan.find(marker) {
                let after = &scan[j + marker.len()..];
                let after = after.strip_prefix(" NULLS NOT DISTINCT").unwrap_or(after);
                if let Some(list) = after.strip_prefix(" (") {
                    keys.insert((table.clone(), kind.into(), columns(&list[..list.find(')').unwrap()])));
                } else {
                    // Column level: the column is the first word of the line the marker sits on.
                    let line_start = scan[..j].rfind('\n').map_or(0, |k| k + 1);
                    let column = scan[line_start..].split_whitespace().next().unwrap();
                    keys.insert((table.clone(), kind.into(), column.to_string()));
                }
                scan = &scan[j + marker.len()..];
            }
        }
    }
    keys
}

/// The names of every `xs:key` and `xs:unique` a schema declares.
fn xsd_keys(src: &str) -> BTreeSet<String> {
    let mut names = BTreeSet::new();
    for marker in ["<xs:key name=\"", "<xs:unique name=\""] {
        let mut rest = src;
        while let Some(i) = rest.find(marker) {
            rest = &rest[i + marker.len()..];
            names.insert(rest[..rest.find('"').unwrap()].to_string());
        }
    }
    names
}

fn declared() -> BTreeSet<(String, String, String)> {
    KEYS.iter().map(|(t, k, c, _)| (t.to_string(), k.to_string(), c.to_string())).collect()
}

#[test]
fn every_key_in_the_ddl_names_its_ground() {
    let ddl = ddl_keys(&read("assets/ddl/schema.ddl"));
    assert!(ddl.len() > 20, "the DDL parsed to {} keys, so the parser is not reading it", ddl.len());
    let declared = declared();
    let unground: Vec<_> = ddl.difference(&declared).collect();
    let stale: Vec<_> = declared.difference(&ddl).collect();
    assert!(
        unground.is_empty() && stale.is_empty(),
        "keys in schema.ddl with no ground here: {unground:#?}\nkeys here that schema.ddl no longer \
         has: {stale:#?}\nA key says two rows with the same values are one thing; say why, or key by \
         position"
    );
}

#[test]
fn every_xsd_ground_is_declared_in_its_schema() {
    for (table, kind, cols, ground) in KEYS {
        if let Xsd(names) = ground {
            for (file, name) in *names {
                assert!(
                    xsd_keys(&read(&format!("schema/{file}"))).contains(*name),
                    "{table} {kind} ({cols}) names `{name}`, which {file} does not declare"
                );
            }
        }
    }
}

#[test]
fn every_xsd_key_over_a_loaded_document_has_a_key_here() {
    let imaged: BTreeSet<(&str, &str)> = KEYS
        .iter()
        .filter_map(|(_, _, _, g)| if let Xsd(n) = g { Some(n.iter().copied()) } else { None })
        .flatten()
        .collect();
    let not_loaded: BTreeSet<(&str, &str)> = NOT_LOADED.iter().map(|(f, n, _)| (*f, *n)).collect();
    for file in [PM, ASRT] {
        let names = xsd_keys(&read(&format!("schema/{file}")));
        for name in &names {
            let at = (file, name.as_str());
            assert!(
                imaged.contains(&at) || not_loaded.contains(&at),
                "{file} keys `{name}` and no key in schema.ddl images it, nor is its document declared \
                 unloaded here"
            );
            assert!(
                !(imaged.contains(&at) && not_loaded.contains(&at)),
                "`{name}` in {file} is both imaged and declared unloaded"
            );
        }
        for (f, n, _) in NOT_LOADED.iter().filter(|(f, _, _)| *f == file) {
            assert!(names.contains(*n), "NOT_LOADED names `{n}`, which {f} does not declare");
        }
    }
}

/// A ground that is not an XSD key or document order is an argument, so it has to be one.
#[test]
fn every_other_ground_says_why() {
    for (table, kind, cols, ground) in KEYS {
        let why = match ground {
            OnePer(why) | Outside(why) => *why,
            Xsd(_) | Positional => continue,
        };
        assert!(
            why.split_whitespace().count() >= 3,
            "{table} {kind} ({cols}) gives no reason a reader could argue with: {why:?}"
        );
    }
}

/// ⛔ The probe: a key added to the DDL with no ground is seen.
#[test]
fn a_key_nobody_grounded_is_seen() {
    let ddl = read("assets/ddl/schema.ddl");
    let anchor = "CREATE TABLE operation (\n";
    assert!(ddl.contains(anchor), "the probe's anchor moved");
    let mutated = ddl.replacen(anchor, &format!("{anchor}    CONSTRAINT probe UNIQUE (filing, foreign_id),\n"), 1);
    let unground: Vec<_> = ddl_keys(&mutated).difference(&declared()).cloned().collect();
    assert_eq!(
        unground,
        vec![("operation".to_string(), "unique".to_string(), "filing, foreign_id".to_string())]
    );
}
