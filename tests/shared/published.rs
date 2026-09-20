//! What this repository publishes, named once because two laws read it.
//!
//! ⛔⛔ THE SET IS ASKED OF GIT RATHER THAN RECONSTRUCTED. `.gitignore` is where this repository
//! declares what it does not publish, and a second copy of that list inside a test is a fork that
//! drifts with nothing able to notice. A tree walk was tried first and immediately reported on a
//! working-notes file nobody ships, which is that fork appearing within one run.
//!
//! ⭐ `--others --exclude-standard` is what keeps a law over this set strongest exactly where it
//! matters most. A page written five minutes ago and not yet committed is already in, and that is
//! the moment its Portuguese sibling or its place in an index is easiest to forget; asking only
//! for tracked files would go quiet on precisely the new page the law exists to catch.

// ⚠️ Two test crates include this module and neither reads all of it, so every item here is dead
// code from one side or the other. Allowed at the module rather than per item: a law added later
// that reads a different part of this file should not have to come back and edit an attribute.
#![allow(dead_code)]

use std::path::PathBuf;

/// The repository root.
pub fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

/// Every published English page, as paths relative to the root, sorted.
///
/// ⚠️ English only: a `.pt.md` is the sibling of one of these rather than a page in its own
/// right, and counting both would make every law here report twice about one document.
pub fn published_documents() -> Vec<String> {
    let out = std::process::Command::new("git")
        .args(["ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", "*.md"])
        .current_dir(root())
        .output()
        .expect("git is how this repository declares what it publishes, so it must be runnable");
    assert!(
        out.status.success(),
        "`git ls-files` failed, so the published set is UNKNOWN rather than empty. A law that \
         cannot name its own population must say so instead of passing."
    );
    let mut found: Vec<String> = String::from_utf8_lossy(&out.stdout)
        .split('\0')
        .filter(|p| !p.is_empty() && !p.ends_with(".pt.md"))
        .map(|p| p.to_string())
        .collect();
    found.sort();
    found.dedup();
    assert!(!found.is_empty(), "the repository publishes no markdown, which cannot be right");
    found
}

/// A page's first line, reduced to the claim it makes.
///
/// ⭐ THE ENTRY AND THE FIRST LINE ARE ONE STRING, WHICH IS THE WHOLE POINT. A parent that
/// summarised its child in its own words would be holding a second copy, and the two would
/// disagree the first time either moved. So the reductions below strip only the decoration a page
/// needs and an index entry does not: a markdown heading marker, the `**Português europeu.**`
/// lead every translated page opens with, and a `` `path/`: `` prefix that repeats the link
/// beside it.
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
