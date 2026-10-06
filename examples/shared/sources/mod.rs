//! Every example's own source, as one string, read once.
//!
//! Two programs, `compositions` and `observations`, ask this directory the same question: is this
//! relation run by an example? They read it through this one function, so their answers stay in
//! step. Each program lives in a directory of its own, so the walk recurses: a reader that stopped
//! at the top level would meet directories, and a directory read as a file gives an empty string
//! that answers no for every relation in the tree.
//!
//! The walk refuses an empty answer. A scan whose population can silently become nothing gives a
//! confident no, which reads exactly like a finding.

use std::fs;
use std::path::{Path, PathBuf};

/// Every `.rs` file under `examples/`, concatenated.
///
/// The files are sorted by path, so every machine builds the same string. A scan that followed
/// directory order could answer differently on two machines for reasons nobody can see.
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
