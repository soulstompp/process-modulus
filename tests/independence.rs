//! The independence boundary, asserted rather than trusted.
//!
//! This crate exists partly to corroborate a model built elsewhere by someone
//! else's reasoning. Corroboration between two things that share a type, an
//! author, or a code path is worth nothing. The crate boundary is what makes
//! the agreement evidence, and it is the kind of property that erodes the
//! first time somebody needs "just one type" from the other side.
//!
//! If one of these fails, the fix is not to add an exception.
//!
//! **An allowlist, not a denylist.** Naming the crates to avoid pins the
//! property to a name: it passes the moment the thing on the other side is
//! called something else, and a renamed sibling is the case that matters.
//! Declaring the complete permitted set fails closed instead: anything
//! unlisted is a finding, whatever it is called.
//!
//! **Scoped to the dependency tables on purpose.** A scan of the whole
//! manifest would also read its comments, which name the boundary in prose,
//! and report a finding the test made itself.

const MANIFEST: &str = include_str!("../Cargo.toml");

/// The complete set of crates this one may depend on, from any table.
///
/// Adding a name here is the decision to take that crate. It is meant to be a
/// reviewed edit rather than a formality, because every entry is a route by
/// which someone else's types could arrive.
const PERMITTED: &[&str] = &[
    // the crate proper
    "xsd-parser-types",
    "quick-xml",
    "xsd-parser",
    "anyhow",
    // dev only, for the examples that read the database. None reaches a consumer, and none
    // is the model this crate exists to corroborate: they are a database driver and its
    // runtime. Each is added on purpose, which is what this list is for.
    "sqlx",
    "tokio",
    // The generator. It is safe to take because it is not a model: NeXosim is a bare
    // discrete-event scheduler, with mailboxes, an event queue and a clock, and two answers
    // corroborate each other only while they are two. `serde` rides along because the
    // scheduler requires it on every model type.
    "nexosim",
    "serde",
];

/// Every `key = value` line inside a `[…dependencies]` table.
fn dependency_lines() -> Vec<&'static str> {
    let mut out = Vec::new();
    let mut in_deps = false;
    for line in MANIFEST.lines() {
        let l = line.trim();
        if l.starts_with('[') {
            in_deps = l.contains("dependencies");
            continue;
        }
        if in_deps && !l.starts_with('#') && !l.is_empty() {
            out.push(l);
        }
    }
    out
}

/// The crate name on the left of a dependency line.
fn dependency_name(line: &str) -> &str {
    line.split('=').next().unwrap_or("").trim()
}

#[test]
fn the_dependency_scan_still_finds_the_tables() {
    // Without this, every assertion below passes with nothing to examine the
    // moment the section parser stops finding a table, and a passing gate then
    // means nothing. It asserts that the parser finds a table, not that any
    // dependency exists.
    let saw_a_table = MANIFEST.lines().any(|l| {
        let l = l.trim();
        l.starts_with('[') && l.contains("dependencies")
    });
    assert!(
        saw_a_table,
        "no [...dependencies] table found in the manifest, so the checks below check nothing"
    );
}

#[test]
fn every_dependency_is_on_the_permitted_list() {
    for l in dependency_lines() {
        let name = dependency_name(l);
        assert!(
            PERMITTED.contains(&name),
            "`{name}` is not on the permitted list, so this crate may now share a type \
             with the model it exists to corroborate independently. If the dependency is \
             genuinely third-party, add it to PERMITTED deliberately. Offending line: {l}"
        );
    }
}

/// And the list names nothing the manifest does not take.
/// `every_dependency_is_on_the_permitted_list` asks that every dependency is permitted; this asks
/// that every permission is used. A name sitting on the list with no dependency behind it is
/// worse than dead weight: it is a decision recorded as taken when nobody took it, and adding a
/// name is the decision.
///
/// The one-way check cannot see it. `contains` asks whether a dependency is on the list, so
/// without this a name can sit here with no manifest entry behind it while every other test
/// passes, and the allowlist pre-authorises a crate this one does not take, in a file whose
/// purpose is that the list and the manifest agree.
#[test]
fn every_permitted_name_is_a_dependency_the_manifest_takes() {
    let taken: Vec<String> = dependency_lines()
        .into_iter()
        .map(|l| dependency_name(l).to_string())
        .collect();
    for p in PERMITTED {
        assert!(
            taken.iter().any(|t| t == p),
            "`{p}` is on the permitted list and this crate does not depend on it. A permission \
             nobody uses is a decision recorded as taken: remove the name, and add it back with \
             the dependency it authorises. Taken: {taken:?}"
        );
    }
}

#[test]
fn this_crate_has_no_path_dependency_at_all() {
    // Broader than the rule needs, on purpose: a path dependency on anything
    // local is a route back to another author's types via one more hop, and it
    // is the route a rename would otherwise hide.
    for l in dependency_lines() {
        assert!(
            !l.contains("path = "),
            "no local path dependency is permitted here: {l}"
        );
    }
}
