//! The proofs page, held to its own shape.
//!
//! `cargo test --doc` runs the page's blocks, and a block that fails is a proof that fails. What
//! it cannot see is a page that stops proving what it says: an entry with no block, a figure in
//! the prose that no block asserts, a law the page names and the roster does not have, or a
//! Portuguese page whose code has drifted from the code that runs. These tests read the two pages
//! as text and check each of those.
//!
//! ## What an entry is
//!
//! A `### ` section whose closing paragraph starts `**Entry**` (`**Entrada**` in Portuguese). That
//! paragraph names the entry's id, then the laws on `assets/sqlc/algebra/roster.sqlc` and the rules
//! on `assets/sqlc/checks/roster.sqlc` that hold it on the database. An entry that is true of
//! numbers rather than of filings names `none`, and its id is on `PURE` with the reason.

use std::collections::BTreeSet;
use std::fs;
use std::path::Path;

/// Entries that are pure mathematics, with the reason no law or rule can hold them.
const PURE: &[(&str, &str)] = &[
    (
        "two_readings",
        "a property of residues, true of every demand and quantum whatever a filing states",
    ),
    (
        "nearest_multiple",
        "a property of residues, true of every demand and quantum whatever a filing states",
    ),
    (
        "isotone_in_parts_not_in_eliminations",
        "a monotonicity of interval subtraction, true of any sum and any elimination, and neither \
         direction is a defect for a rule to find",
    ),
    (
        "product_is_join",
        "two ways of computing one sum; examples/matrices asserts them equal against the SQL",
    ),
    (
        "two_slopes",
        "the complete form of a positively homogeneous piecewise-linear map, true of every positive \
         factor whatever a filing states",
    ),
    (
        "month_hours",
        "calendar arithmetic; which month a composer reads at the mode is a convention no rule judges",
    ),
    (
        "conversion_collapses",
        "associativity of positive scaling; composition/settled_remainders rests on it and no law \
         recomputes the path product",
    ),
    (
        "slack_from_duration",
        "the filer converts before filing, and no filed element carries the duration to check",
    ),
    (
        "twelvefold",
        "a count of functions between finite sets; examples/combinatorics applies it to the SQL",
    ),
    (
        "self_join_sizes",
        "cardinalities of a self-join; examples/combinatorics holds them against the relations",
    ),
    (
        "excess",
        "an identity of weighted sums, true of any assignment of rows to classes",
    ),
    (
        "float_sums",
        "a fact about IEEE 754 doubles, which the 1e-9 tolerance every comparison uses answers",
    ),
    (
        "kernel_is_the_excess",
        "the rank and nullity of a fold's incidence, true of any function into any codomain; \
         rank/composition_kernel measures the corpus instance and algebra/composition_kernel \
         holds it",
    ),
    (
        "orthants",
        "a count of the sign orthants of a product, true of any number of parts",
    ),
    (
        "elimination_leaves",
        "the range of a divergence, true of any graph; examples/matrices measures the corpus \
         instance and no law recomputes it",
    ),
    (
        "selection_accumulates",
        "an identity of relational algebra, true of every relation",
    ),
    (
        "projection_counterexample",
        "a counterexample in relational algebra, which no filing can confirm or refute",
    ),
    (
        "incidence_subspaces",
        "the rank and the nullity of an incidence matrix, true of any graph; rank/cycle_space \
         measures the two dimensions and no law recomputes them",
    ),
    (
        "laplacian_is_a_join",
        "the Gram of an incidence matrix, true of any graph; examples/columns forms it as a join \
         over the compose graph and no law recomputes it",
    ),
    (
        "laplacian_decomposes",
        "the additivity of a Laplacian and the kernel of a Gram, true of any graph; \
         examples/columns measures both over the compose graph and no law recomputes them",
    ),
    (
        "path_product_needs_one_path",
        "a counterexample on a diamond, which no filing can confirm because checks/jagged_layer \
         refuses the second path before any factor is read",
    ),
];

/// The line every block starts with.
const INCLUDE: &str = r#"include!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/proofs/support.rs"));"#;

fn read(rel: &str) -> String {
    let path = format!("{}/{rel}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// One fenced block: its info string and its body.
struct Fence {
    info: String,
    body: String,
}

/// One entry of the page.
struct Entry {
    title: String,
    id: String,
    laws: Vec<String>,
    rules: Vec<String>,
    none: bool,
    prose: String,
    fences: Vec<Fence>,
}

/// Every fenced block in a page, in order.
fn fences(page: &str) -> Vec<Fence> {
    let mut out = Vec::new();
    let mut open: Option<Fence> = None;
    for line in page.lines() {
        match (&mut open, line.strip_prefix("```")) {
            (None, Some(info)) => {
                open = Some(Fence {
                    info: info.trim().to_string(),
                    body: String::new(),
                })
            }
            (Some(_), Some(rest)) if rest.trim().is_empty() => out.push(open.take().unwrap()),
            (Some(f), _) => {
                f.body.push_str(line);
                f.body.push('\n');
            }
            (None, None) => {}
        }
    }
    assert!(open.is_none(), "a fence is never closed");
    out
}

/// The entries of a page, where `label` is `**Entry**` or `**Entrada**`.
fn entries(page: &str, label: &str) -> Vec<Entry> {
    let mut out = Vec::new();
    for section in page.split("\n### ").skip(1) {
        let section = section.split("\n## ").next().unwrap();
        let title = section.lines().next().unwrap().trim().to_string();
        let mut prose = String::new();
        let mut in_fence = false;
        let mut tail = String::new();
        let mut in_tail = false;
        for line in section.lines().skip(1) {
            if line.starts_with("```") {
                in_fence = !in_fence;
                continue;
            }
            if in_fence {
                continue;
            }
            if line.starts_with(label) {
                in_tail = true;
            }
            if in_tail {
                if line.trim().is_empty() {
                    in_tail = false;
                    continue;
                }
                tail.push_str(line);
                tail.push(' ');
            } else {
                prose.push_str(line);
                prose.push('\n');
            }
        }
        if tail.is_empty() {
            continue;
        }
        assert_eq!(
            tail.matches(label).count(),
            1,
            "`{title}` names more than one entry"
        );
        let spans: Vec<String> = tail
            .split('`')
            .skip(1)
            .step_by(2)
            .map(str::to_string)
            .collect();
        let (id, rest) = spans
            .split_first()
            .unwrap_or_else(|| panic!("`{title}` has an entry line with no id"));
        out.push(Entry {
            title,
            id: id.clone(),
            laws: rest
                .iter()
                .filter_map(|s| s.strip_prefix("algebra/"))
                .map(str::to_string)
                .collect(),
            rules: rest
                .iter()
                .filter_map(|s| s.strip_prefix("checks/"))
                .map(str::to_string)
                .collect(),
            none: rest.iter().any(|s| s == "none"),
            prose,
            fences: fences(section),
        });
    }
    out
}

/// The SQL string literals on one line, `''` read as a quote.
fn literals(line: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut chars = line.chars().peekable();
    while let Some(c) = chars.next() {
        if c != '\'' {
            continue;
        }
        let mut lit = String::new();
        while let Some(c) = chars.next() {
            if c == '\'' {
                if chars.peek() == Some(&'\'') {
                    chars.next();
                    lit.push('\'');
                } else {
                    break;
                }
            } else {
                lit.push(c);
            }
        }
        out.push(lit);
    }
    out
}

/// The rows of a roster's `VALUES` list, as the literals on each row.
fn roster(rel: &str) -> Vec<Vec<String>> {
    read(rel)
        .lines()
        .filter(|l| l.trim_start().starts_with("('"))
        .map(literals)
        .collect()
}

/// Decimals and numbers of three digits or more, as written. A standard's designation,
/// `ISO 286-1:1988`, and a clause number, `4.10.1`, are names and not figures.
fn figures(text: &str, decimal: char) -> BTreeSet<String> {
    let mut out = BTreeSet::new();
    let chars: Vec<char> = text.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        if !chars[i].is_ascii_digit() || (i > 0 && chars[i - 1].is_alphanumeric()) {
            i += 1;
            continue;
        }
        let start = i;
        while i < chars.len() && chars[i].is_ascii_digit() {
            i += 1;
        }
        let whole: String = chars[start..i].iter().collect();
        if chars[..start].iter().collect::<String>().ends_with("ISO ") {
            while i < chars.len() && !chars[i].is_whitespace() {
                i += 1;
            }
            continue;
        }
        if i + 1 < chars.len() && chars[i] == decimal && chars[i + 1].is_ascii_digit() {
            i += 1;
            let from = i;
            while i < chars.len() && chars[i].is_ascii_digit() {
                i += 1;
            }
            let frac: String = chars[from..i].iter().collect();
            let clause = i + 1 < chars.len() && chars[i] == '.' && chars[i + 1].is_ascii_digit();
            if clause {
                while i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                    i += 1;
                }
                continue;
            }
            out.insert(format!("{whole}.{frac}"));
        } else if whole.len() >= 3 {
            out.insert(whole);
        }
    }
    out
}

/// A block's code without its whole-line comments, which are the only part a translation changes.
fn code(body: &str) -> String {
    body.lines()
        .filter(|l| !l.trim_start().starts_with("//"))
        .collect::<Vec<_>>()
        .join("\n")
}

fn english() -> Vec<Entry> {
    entries(&read("src/proofs/README.md"), "**Entry**")
}

fn portuguese() -> Vec<Entry> {
    entries(&read("src/proofs/README.pt.md"), "**Entrada**")
}

#[test]
fn the_page_has_entries() {
    assert!(
        !english().is_empty(),
        "no entry was found, so every test below would pass on an empty page"
    );
}

#[test]
fn every_entry_has_one_id_and_one_block_that_asserts() {
    let mut seen = BTreeSet::new();
    for e in english() {
        assert!(seen.insert(e.id.clone()), "`{}` is the id of two entries", e.id);
        let rust: Vec<&Fence> = e.fences.iter().filter(|f| f.info == "rust").collect();
        assert_eq!(rust.len(), 1, "`{}` has {} Rust blocks, not one", e.title, rust.len());
        let body = &rust[0].body;
        assert_eq!(
            body.lines().next(),
            Some(INCLUDE),
            "`{}`'s block does not start with the shared include",
            e.title
        );
        assert!(body.contains("fn main()"), "`{}`'s block has no visible main", e.title);
        assert!(body.contains("assert"), "`{}`'s block asserts nothing", e.title);
        assert!(
            !body.lines().any(|l| l.starts_with("# ") || l == "#"),
            "`{}`'s block hides a line; every line a proof runs is shown",
            e.title
        );
    }
}

#[test]
fn every_fence_is_rust_text_sql_or_xml() {
    for page in ["src/proofs/README.md", "src/proofs/README.pt.md"] {
        for f in fences(&read(page)) {
            assert!(
                matches!(f.info.as_str(), "rust" | "text" | "sql" | "xml"),
                "{page} has a fence marked `{}`; rustdoc runs an unmarked fence as Rust",
                f.info
            );
        }
    }
}

#[test]
fn every_entry_is_held_by_a_law_or_a_rule_or_is_pure() {
    let laws: BTreeSet<String> = roster("assets/sqlc/algebra/roster.sqlc")
        .into_iter()
        .map(|r| r[0].clone())
        .collect();
    let rules: BTreeSet<String> = roster("assets/sqlc/checks/roster.sqlc")
        .into_iter()
        .map(|r| r[0].clone())
        .collect();
    assert!(!laws.is_empty() && !rules.is_empty(), "a roster read as empty");

    let entries = english();
    for e in &entries {
        for l in &e.laws {
            assert!(laws.contains(l), "`{}` names law `{l}`, which is not on the roster", e.id);
            assert!(
                Path::new(&format!("{}/assets/sqlc/algebra/{l}.sqlc", env!("CARGO_MANIFEST_DIR")))
                    .exists(),
                "`{}` names law `{l}`, which has no file",
                e.id
            );
        }
        for r in &e.rules {
            assert!(rules.contains(r), "`{}` names rule `{r}`, which is not on the roster", e.id);
        }
        let pure = PURE.iter().any(|(id, _)| *id == e.id);
        if e.none {
            assert!(
                e.laws.is_empty() && e.rules.is_empty(),
                "`{}` names `none` beside a law or a rule",
                e.id
            );
            assert!(pure, "`{}` names `none` and is not on PURE", e.id);
        } else {
            assert!(
                !e.laws.is_empty() || !e.rules.is_empty(),
                "`{}` names no law, no rule, and not `none`",
                e.id
            );
            assert!(!pure, "`{}` is on PURE and names a law or a rule", e.id);
        }
    }
    for (id, _) in PURE {
        assert!(entries.iter().any(|e| e.id == *id), "PURE names `{id}`, which is no entry");
    }
}

#[test]
fn every_value_law_is_named_on_the_page() {
    let named: BTreeSet<String> = english().into_iter().flat_map(|e| e.laws).collect();
    let value: Vec<String> = roster("assets/sqlc/algebra/roster.sqlc")
        .into_iter()
        .filter(|r| r.get(3).map(String::as_str) == Some("value"))
        .map(|r| r[0].clone())
        .collect();
    assert!(!value.is_empty(), "the roster has no value law, so this test checks nothing");
    for v in value {
        assert!(
            named.contains(&v),
            "value law `{v}` recomputes a figure the page never proves"
        );
    }
}

#[test]
fn every_figure_in_an_entry_is_asserted_by_its_block() {
    for e in english() {
        let block = &e.fences.iter().find(|f| f.info == "rust").unwrap().body;
        for n in figures(&e.prose, '.') {
            assert!(
                block.contains(&n),
                "`{}` mentions {n} and its block never does",
                e.id
            );
        }
    }
}

#[test]
fn the_two_languages_carry_the_same_entries_and_code() {
    let (en, pt) = (english(), portuguese());
    let ids = |v: &[Entry]| v.iter().map(|e| e.id.clone()).collect::<Vec<_>>();
    assert_eq!(ids(&en), ids(&pt), "the two pages list different entries");
    for (a, b) in en.iter().zip(&pt) {
        assert_eq!(a.laws, b.laws, "`{}` names different laws in the two pages", a.id);
        assert_eq!(a.rules, b.rules, "`{}` names different rules in the two pages", a.id);
        assert_eq!(a.fences.len(), b.fences.len(), "`{}` has different blocks", a.id);
        for (x, y) in a.fences.iter().zip(&b.fences) {
            assert_eq!(x.info, y.info, "`{}` has a block of a different kind", a.id);
            if x.info == "rust" {
                assert_eq!(
                    code(&x.body),
                    code(&y.body),
                    "`{}`: the Portuguese block is not the code that runs",
                    a.id
                );
            }
        }
        assert_eq!(
            figures(&a.prose, '.'),
            figures(&b.prose, ','),
            "`{}` quotes different figures in the two pages",
            a.id
        );
    }
}

#[test]
fn the_shared_file_does_no_arithmetic_beyond_its_tolerance() {
    let src = read("src/proofs/support.rs");
    let mut in_close = false;
    for line in src.lines() {
        let l = line.trim();
        if l.starts_with("//") {
            continue;
        }
        if l.starts_with("fn ") {
            in_close = l.starts_with("fn close(");
        }
        if in_close {
            continue;
        }
        for op in [" + ", " - ", " * ", " / ", "+=", "-=", ".abs(", ".sum(", ".max(", ".min("] {
            assert!(
                !l.contains(op),
                "support.rs computes (`{op}` in `{l}`); a proof's arithmetic belongs in its block"
            );
        }
    }
}

#[test]
fn src_holds_only_the_library_and_the_proofs() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("src");
    let mut found = BTreeSet::new();
    let mut stack = vec![root.clone()];
    while let Some(dir) = stack.pop() {
        for e in fs::read_dir(&dir).unwrap().flatten() {
            let p = e.path();
            if p.is_dir() {
                stack.push(p);
            } else {
                found.insert(p.strip_prefix(&root).unwrap().to_string_lossy().to_string());
            }
        }
    }
    let expected: BTreeSet<String> = [
        "lib.rs",
        "proofs/README.md",
        "proofs/README.pt.md",
        "proofs/support.rs",
    ]
    .into_iter()
    .map(str::to_string)
    .collect();
    assert_eq!(
        found, expected,
        "src/ is the generated library and its proofs page; anything else is hand-written code \
         the generator does not own"
    );
}
