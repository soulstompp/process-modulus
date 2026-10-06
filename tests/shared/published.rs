//! What this repository publishes, named once because two laws read it.
//!
//! The set is asked of git rather than rebuilt by walking the tree. `.gitignore` is where this
//! repository declares what it does not publish, and a second copy of that list inside a test
//! would drift with nothing to notice. A walk of the tree also reports on working notes nobody
//! ships.
//!
//! `--others --exclude-standard` takes in a page that is written and not yet committed. That is
//! the moment its Portuguese page or its place in an index is easiest to forget, and asking only
//! for tracked files would leave out the very page the laws exist to catch.

// Two test crates include this module and neither reads all of it, so every item here is dead
// code from one side or the other. The allowance sits on the module rather than on each item, so
// a law that reads a different part of this file does not have to come back and edit an attribute.
#![allow(dead_code)]

use std::path::PathBuf;

/// The repository root.
pub fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

/// Every published English page, as paths relative to the root, sorted.
///
/// English only: a page under `pt-PT/` is the Portuguese of one of these, at the same path under
/// `pt-PT/`, and counting both would make every law here report twice about one document.
pub fn published_documents() -> Vec<String> {
    let out = std::process::Command::new("git")
        .args(["ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", "*.md"])
        .current_dir(root())
        .output()
        .expect("git is how this repository declares what it publishes, so it must be runnable");
    assert!(
        out.status.success(),
        "`git ls-files` failed, so the published set is unknown rather than empty. A law that \
         cannot name its own population must say so instead of passing."
    );
    let mut found: Vec<String> = String::from_utf8_lossy(&out.stdout)
        .split('\0')
        .filter(|p| !p.is_empty() && !p.starts_with(PORTUGUESE))
        .map(|p| p.to_string())
        .collect();
    found.sort();
    found.dedup();
    assert!(!found.is_empty(), "the repository publishes no markdown, which cannot be right");
    found
}

/// The tree that holds the Portuguese pages, following the English one.
pub const PORTUGUESE: &str = "pt-PT/";

/// The Portuguese page of an English one, as a path relative to the root.
pub fn portuguese_of(english: &str) -> String {
    format!("{PORTUGUESE}{english}")
}

/// A page's first line, reduced to the claim it makes.
///
/// The entry and the first line are one string. A parent that summarised its child in its own
/// words would hold a second copy, and the two would disagree the first time either moved. So the
/// reductions below strip only the decoration a page needs and an index entry does not: a markdown
/// heading marker, the `**Português europeu.**` lead an example's Portuguese page opens with, and
/// a `` `path/`: `` prefix that repeats the link beside it.
pub fn entry_of(body: &str) -> String {
    let mut line = body.lines().next().unwrap_or_default().trim().to_string();
    if let Some(rest) = line.strip_prefix("# ") {
        line = rest.trim().to_string();
    }
    if line.starts_with("**") {
        if let Some(end) = line[2..].find("**") {
            line = line[end + 4..].trim().to_string();
        }
    }
    if line.starts_with('`') {
        if let Some(end) = line[1..].find("`:") {
            line = line[end + 3..].trim().to_string();
        }
    }
    line
}
