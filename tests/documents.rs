//! The documentation is a composition, and this is what holds it to being one.
//!
//! ## Why a law and not a convention
//!
//! `assets/sqlc/` is a composition: one file names one object, `:compose` is substitution, and
//! the tree's own shape is a relation anybody can query. The pages are held to the same shape,
//! each one linked from the page above it and naming the pages below.
//!
//! What that saves is more than tidiness. A parent with no child to name says the thing itself,
//! every time it needs it, so one claim ends up written twice, and neither copy knows about the
//! other.
//!
//! ## The two halves
//!
//! **Reached by nothing.** Every published page is linked from another published page, or is a
//! declared root. `examples/observations` holds the same rule over the `.sqlc` templates and the
//! filed documents. A page somebody writes and nobody links is a page a reader can only find by
//! knowing it is there.
//!
//! **The entry is the first line.** Where a page indexes its children, each entry is that child's
//! own first line rather than a summary of it. A summary is a second copy, and it disagrees with
//! the first the moment either one moves, with nothing to notice. The rule holds in both
//! languages, because a Portuguese index that has drifted from its children is not a translation.

#[path = "shared/published.rs"]
mod published;

use published::{entry_of, portuguese_of, published_documents, root};
use std::fs;

/// The pages that are reached by nothing on purpose, because nothing is above them.
///
/// Declared rather than inferred. From outside, a page with no parent and a page somebody forgot
/// to link look the same, and only a declaration tells them apart.
const ROOTS: [&str; 1] = ["README.md"];

/// Every index edge: the page that indexes, and the directory whose page it indexes.
///
/// `examples/README.md` indexes the programs beneath it and is not listed here: `tests/examples.rs`
/// already holds that table against each program's own first line, in both directions and both
/// languages, and `build.rs` generates the crate's copy from the same source. A second law over
/// the same edges would be a second copy of a working one.
const INDEX: [(&str, &str); 7] = [
    ("README.md", "schema"),
    ("README.md", "assets"),
    ("README.md", "conformance"),
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

/// Every published page is reachable by following links from another page.
///
/// It fails on a page that is written and never linked. A parent that names a directory in prose
/// and does not link it leaves the page there unreached, because a reader clicking through cannot
/// arrive at it.
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
            // A link to a directory reaches that directory's README and nothing else in it,
            // because that is the only file the link opens. Counting it for every page under the
            // directory would let the root's link to `assets/` reach every page beneath it.
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

/// An index entry is its child's first line, in both languages and in both directions.
///
/// The reverse direction matters most. When somebody improves a child's first line, the parent is
/// left quoting a sentence that exists nowhere else, and nothing about the parent looks wrong from
/// inside it.
#[test]
fn every_index_entry_is_its_child_own_first_line() {
    for (parent, child) in INDEX {
        let english = (parent.to_string(), format!("{child}/README.md"));
        let portuguese = (portuguese_of(parent), portuguese_of(&english.1));
        let pairs = [(english, "English"), (portuguese, "Portuguese")];
        for ((parent_path, child_path), lang) in pairs {
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

/// A declared edge whose child is not published is a stale roster, and the law above passes over
/// it in silence: an index naming a page nobody ships still reads as a complete index.
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

/// The fenced blocks of a page, in order: the word after the opening fence, and the text inside.
fn fenced_blocks(body: &str) -> Vec<(String, String)> {
    let mut blocks = Vec::new();
    let mut open: Option<(String, Vec<&str>)> = None;
    for line in body.lines() {
        match (&mut open, line.strip_prefix("```")) {
            (None, Some(lang)) => open = Some((lang.trim().to_string(), Vec::new())),
            (Some(_), Some(_)) => {
                let (lang, text) = open.take().expect("an open block");
                blocks.push((lang, text.join("\n")));
            }
            (Some((_, text)), None) => text.push(line),
            (None, None) => {}
        }
    }
    blocks
}

/// The question a composed file asks: what follows the relations it names at its head.
fn question_of(file: &str) -> String {
    let body = read(file);
    let lines: Vec<&str> = body.lines().collect();
    let close = lines.iter().rposition(|l| *l == ")").unwrap_or_else(|| {
        panic!("{file} names no relation at its head, so it has no question to show apart")
    });
    lines[close + 1..].join("\n")
}

/// A query a page shows beside the `psql` lines that run its files is the question those files
/// end with, in both languages, so the page and the file a reader runs are the same statement.
#[test]
fn every_query_shown_beside_its_file_is_the_question_the_file_asks() {
    let english = published_documents();
    let pages: Vec<String> =
        english.iter().cloned().chain(english.iter().map(|p| portuguese_of(p))).collect();
    let mut shown = 0;
    for page in &pages {
        let blocks = fenced_blocks(&read(page));
        for pair in blocks.windows(2) {
            let ((query_lang, query), (run_lang, run)) = (&pair[0], &pair[1]);
            if query_lang != "sql" || run_lang != "sh" {
                continue;
            }
            let files: Option<Vec<&str>> = run
                .lines()
                .map(|l| l.strip_prefix("psql -d process_modulus -f "))
                .map(|f| f.filter(|f| f.contains("assets/sql/queries/")))
                .collect();
            let Some(files) = files else { continue };
            let expected: Vec<String> = files.iter().map(|f| question_of(f)).collect();
            assert_eq!(
                query.trim_end(),
                expected.join("\n\n").trim_end(),
                "{page} shows a query beside `{run}` that is not the question that file asks. \
                 The page is copied from the composed file: recompose, then copy its last \
                 statement after the relations it names."
            );
            shown += 1;
        }
    }
    assert!(
        shown > 0,
        "no page shows a query beside the line that runs it, so this law examines nothing"
    );
}
