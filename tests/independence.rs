//! The independence boundary, asserted rather than trusted.
//!
//! This crate exists partly to corroborate a model built elsewhere by someone
//! else's reasoning. Corroboration between two things that share a type, an
//! author, or a code path is worth nothing. The crate boundary is what makes
//! the agreement evidence, and it is exactly the kind of property that erodes
//! the first time somebody needs "just one type" from the other side.
//!
//! If one of these ever fails, the fix is NOT to add an exception.
//!
//! **An allowlist, not a denylist.** An earlier draft named the one crate family
//! to be avoided. That pins the property to a name: it passes the moment the
//! thing on the other side is called something else, and a renamed sibling is
//! exactly the case that matters. Declaring the complete permitted set fails
//! closed instead: anything unlisted is a finding, whatever it is called.
//!
//! **Scoped to the dependency tables on purpose.** A draft that scanned the whole
//! manifest would fail on its own comments, which name the boundary in prose,
//! a test manufacturing the finding it reports.

const MANIFEST: &str = include_str!("../Cargo.toml");

/// The complete set of crates this one may depend on, from any table.
///
/// ⛔ Adding a name here is the whole decision. It is meant to be a deliberate,
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
    // runtime. Added deliberately, which is what this list is for.
    "sqlx",
    "tokio",
    // ⭐⭐⭐ THE GENERATOR, AND THE REASON IT IS SAFE TO TAKE IS THAT IT IS NOT A MODEL.
    // NeXosim is a bare discrete-event scheduler: mailboxes, an event queue and a clock. Two
    // answers only corroborate while they are two. `serde` rides along because the scheduler
    // requires it on every model type.
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
    // ⛔ Without this, every assertion below passes vacuously the moment the
    // section parser stops finding a table, the failure mode that makes a
    // green gate meaningless. It asserts the PARSER works, not that deps exist,
    // because [dependencies] here is legitimately empty.
    let saw_a_table = MANIFEST.lines().any(|l| {
        let l = l.trim();
        l.starts_with('[') && l.contains("dependencies")
    });
    assert!(
        saw_a_table,
        "no [...dependencies] table found in the manifest, so the checks below prove nothing"
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

/// ⛔⛔⛔ AND THE LIST MAY NOT NAME WHAT THE MANIFEST DOES NOT TAKE, which is the half that was
/// missing and the half that would have caught a real mistake. `every_dependency_is_on_the_
/// permitted_list` asks that every dependency is permitted; nothing asked that every permission
/// is used. A name sitting on the list with no dependency behind it is worse than dead weight:
/// it is a decision recorded as taken when nobody took it, and the file's own doc says adding a
/// name IS the decision.
///
/// ⚠️ AND THE ONE-WAY GATE CANNOT SEE IT. `contains` asks whether a dependency is on the list;
/// nothing asks the converse, so a name can sit here with no manifest entry behind it and every
/// test still passes. What ships is an allowlist pre-authorising a crate this one does not take,
/// in a file whose entire purpose is that the list and the manifest agree.
#[test]
fn every_permitted_name_is_a_dependency_the_manifest_takes() {
    let taken: Vec<String> = dependency_lines()
        .into_iter()
        .map(|l| dependency_name(l).to_string())
        .collect();
    for p in PERMITTED {
        assert!(
            taken.iter().any(|t| t == p),
            "`{p}` is on the permitted list and this crate does not depend on it. A permission              nobody uses is a decision recorded as taken: remove the name, and add it back with              the dependency it authorises. Taken: {taken:?}"
        );
    }
}

#[test]
fn this_crate_has_no_path_dependency_at_all() {
    // Broader than the rule needs, deliberately: a path dependency on anything
    // local is a route back to another author's types via one more hop, and it
    // is the route a rename would otherwise hide.
    for l in dependency_lines() {
        assert!(
            !l.contains("path = "),
            "no local path dependency is permitted here: {l}"
        );
    }
}
