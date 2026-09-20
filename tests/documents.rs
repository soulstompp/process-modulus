//! The documentation is a composition, and this is what holds it to being one.
//!
//! ## Why a law and not a convention
//!
//! `assets/sqlc/` is a composition: one file names one object, `:compose` is substitution, and
//! the tree's own shape is a relation anybody can query. The prose had none of that. Measured
//! before this law existed, the published pages linked to each other about thirty times in total,
//! with a quarter of those pointing at the root, so almost every page re-established its own
//! context from nothing and the root had to carry the whole argument in one pass.
//!
//! ⛔ **What that costs is not tidiness.** A parent with no child to name says the thing itself,
//! every time it needs it. The root README reached the state of carrying one claim twice inside a
//! single section, thirty lines apart, and neither copy knew about the other.
//!
//! ## The two halves
//!
//! **Reached by nothing.** Every published page is linked from another published page, or is a
//! declared root. This is `examples/observations`' `unreached` law for `.sqlc` applied to prose,
//! and it fails in the direction that matters: a page somebody writes and nobody links is a page
//! a reader can only find by knowing it is there.
//!
//! **The entry is the first line.** Where a page indexes its children, each entry IS that child's
//! own first line rather than a summary of it. ⭐ A summary is a second copy, and a second copy
//! disagrees with the first the moment either one moves, with nothing able to notice. Both
//! languages, because a Portuguese index that has drifted from its children is not a translation.

#[path = "shared/published.rs"]
mod published;

use published::{entry_of, published_documents, root};
use std::fs;

/// The pages that are reached by nothing on purpose, because nothing is above them.
///
/// ⚠️ Declared rather than inferred. "This page has no parent" and "somebody forgot to link this
/// page" are the same observation from outside, and only a declaration tells them apart.
const ROOTS: [&str; 1] = ["README.md"];

/// Every index edge: the page that indexes, and the directory whose page it indexes.
///
/// ⛔ `examples/README.md` indexes the sixteen programs beneath it and is NOT listed here,
/// because `tests/examples.rs` already holds that table against each program's own first line, in
/// both directions and both languages, and `build.rs` generates the crate's copy from the same
/// source. A second law over the same edges would be a fork of a working one.
const INDEX: [(&str, &str); 8] = [
    ("README.md", "schema"),
    ("README.md", "assets"),
    ("README.md", "conformance"),
    ("README.md", "src/proofs"),
    ("README.md", "examples"),
    ("assets/README.md", "assets/corpus"),
    ("assets/README.md", "assets/fixtures"),
    ("assets/README.md", "assets/sqlc"),
];

fn read(rel: &str) -> String {
    fs::read_to_string(root().join(rel)).unwrap_or_else(|_| panic!("{rel} is not readable"))
}

fn dir_of(rel: &str) -> &str {
    match rel.rfind('/') {
        Some(i) => &rel[..i],
        None => "",
    }
}

/// The link one page would have to write to reach another, which is what a reader clicks.
fn relative(from_dir: &str, to: &str) -> String {
    let f: Vec<&str> = from_dir.split('/').filter(|s| !s.is_empty()).collect();
    let t: Vec<&str> = to.split('/').filter(|s| !s.is_empty()).collect();
    let common = f.iter().zip(t.iter()).take_while(|(a, b)| a == b).count();
    let mut parts: Vec<String> = vec!["..".to_string(); f.len() - common];
    parts.extend(t[common..].iter().map(|s| s.to_string()));
    parts.join("/")
}

/// ⭐ Every published page is reachable by following links from somewhere else.
///
/// ⛔ THE FAILURE THIS CATCHES IS A PAGE WRITTEN AND NEVER WIRED IN. When this law was written
/// two pages were in that state, `assets/sqlc/queries/README.md` and `examples/shared/README.md`,
/// and in both cases the parent named the directory in prose and never linked it, so a reader
/// clicking through could not arrive at either one.
#[test]
fn no_published_page_is_reached_by_nothing() {
    let docs = published_documents();
    let bodies: Vec<(String, String)> =
        docs.iter().map(|d| (d.clone(), read(d))).collect();

    let mut orphans = Vec::new();
    for doc in &docs {
        if ROOTS.contains(&doc.as_str()) {
            continue;
        }
        let reached = bodies.iter().any(|(other, body)| {
            if other == doc {
                return false;
            }
            let from = dir_of(other);
            let to_file = relative(from, doc);
            if body.contains(&format!("]({to_file})")) {
                return true;
            }
            // ⛔⛔ A LINK TO A DIRECTORY REACHES THAT DIRECTORY'S README AND NOTHING ELSE IN IT,
            //    because that is the only file the link actually opens. Accepting it for every
            //    page under the directory was this law's first shape, and it made the law
            //    vacuous over four fifths of the tree: the root links `assets/`, so any page
            //    anywhere beneath it read as reached. A probe caught it; nothing else would have.
            if !doc.ends_with("/README.md") {
                return false;
            }
            let to_dir = format!("{}/", relative(from, dir_of(doc)));
            body.contains(&format!("]({to_dir})"))
        });
        if !reached {
            orphans.push(doc.clone());
        }
    }

    assert!(
        orphans.is_empty(),
        "these published pages are linked from nothing, so a reader can only reach them by \
         already knowing they exist: {orphans:?}. Either name each one from the page above it, \
         with a link rather than in prose, or add it to ROOTS and say why nothing is above it."
    );
}

/// ⭐⭐ An index entry IS its child's first line, in both languages and in both directions.
///
/// ⛔ The reverse direction is the one worth having. A child whose first line somebody improves
/// leaves its parent quoting a sentence that no longer exists anywhere, and nothing about the
/// parent looks wrong from inside it.
#[test]
fn every_index_entry_is_its_child_own_first_line() {
    for (parent, child) in INDEX {
        for (suffix, lang) in [(".md", "English"), (".pt.md", "Portuguese")] {
            let parent_path = parent.replace(".md", suffix);
            let child_path = format!("{child}/README{suffix}");
            let entry = entry_of(&read(&child_path));

            assert!(
                !entry.is_empty(),
                "{child_path} has no first line, so there is nothing for {parent_path} to name it \
                 with"
            );
            assert!(
                read(&parent_path).contains(&entry),
                "{parent_path} does not carry {child_path}'s own first line ({lang}).\n  \
                 expected the entry to be exactly: {entry}\n  \
                 An index entry is the child's first line, never a summary of it: a summary is a \
                 second copy, and it disagrees with the first the moment either one moves."
            );
        }
    }
}

/// ⚠️ A declared edge whose child is not published is a stale roster, and it fails silently in
/// the other law: an index naming a page nobody ships still reads as a complete index.
#[test]
fn every_declared_index_edge_names_a_published_page() {
    let docs = published_documents();
    for (parent, child) in INDEX {
        let child_path = format!("{child}/README.md");
        assert!(
            docs.contains(&child_path),
            "INDEX declares {parent} -> {child_path}, and that page is not published. Either the \
             page moved and this roster did not, or it was never written."
        );
        assert!(
            docs.contains(&parent.to_string()),
            "INDEX declares {parent} as an index and that page is not published"
        );
    }
}
