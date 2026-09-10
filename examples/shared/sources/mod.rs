//! Every example's own source, as one string, read once.
//!
//! ⛔⛔ TWO PROGRAMS ASK THE SAME QUESTION OF THIS DIRECTORY, and `examples/compositions/main.rs`
//! says outright in its own comment that keeping the two in step matters more than either being
//! clever. They were two copies of a `read_dir` over `examples/`, and a copy is a copy: when the
//! programs moved into directories of their own, both copies began reading DIRECTORIES.
//! `read_to_string` fails on a directory, `unwrap_or_default` turns that into an empty string,
//! and the question *is this relation run by an example* starts answering no about every relation
//! in the tree.
//!
//! ⭐⭐ SO THE WALK IS ONE FUNCTION, IT RECURSES, AND IT REFUSES AN EMPTY ANSWER. A scan whose
//! population can silently become nothing is the vacuity this repository keeps naming: the answer
//! it gives is a confident no, which reads exactly like a finding.

use std::fs;
use std::path::{Path, PathBuf};

/// Every `.rs` file under `examples/`, concatenated.
///
/// ⚠️ The order is a function of the PATHS, so two machines build the same string. Nothing here
/// depends on it today, and a scan whose result depends on directory order is a scan that answers
/// differently on two machines for reasons nobody can see.
pub fn all() -> String {
    let mut paths = Vec::new();
    collect(Path::new("examples"), &mut paths);
    paths.sort();
    assert!(
        !paths.is_empty(),
        "examples/ holds no .rs file, so every question about what an example runs answers no \
         and this scan reports the whole tree unreachable"
    );
    paths
        .iter()
        .map(|p| {
            fs::read_to_string(p).unwrap_or_else(|e| panic!("cannot read {}: {e}", p.display()))
        })
        .collect()
}

fn collect(dir: &Path, out: &mut Vec<PathBuf>) {
    for e in fs::read_dir(dir).expect("examples/ is readable").flatten() {
        let path = e.path();
        if path.is_dir() {
            collect(&path, out);
        } else if path.extension().and_then(|x| x.to_str()) == Some("rs") {
            out.push(path);
        }
    }
}
