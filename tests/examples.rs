//! One header per program, and one copy of it.
//!
//! Every argument this repository makes about its own arithmetic is made inside a program that
//! evaluates it. `cargo doc --examples` renders a `//!` block in a source file, and a repository
//! front end, where this work is published, renders none. So each program's header is a
//! `README.md` beside it, and the program includes that file.
//!
//! The hazard of that arrangement is a second copy, which this whole repository is organised
//! against: two statements of one fact, drifting, with nothing to notice.
//! `#![doc = include_str!("README.md")]` makes the two renderings the same bytes, and this test
//! keeps a `//!` block from growing back beside the include.
//!
//! An index is a third copy unless something binds it. `examples/README.md` is what a reader
//! browsing the repository lands on, so it carries a row per program, and each row's question is
//! held here against that program's own first line, in both directions.
//!
//! All of it holds in both languages. This model's origin and its hardest jurisdiction are both
//! Portuguese, and a program's header carries rules no validator reaches, as a schema annotation
//! does. So every program has a page under `pt-PT/examples/`, `main.rs` includes both, and
//! `pt-PT/examples/README.md` is bound to the Portuguese first lines as the English index is
//! bound to the English ones.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

const ROOT: &str = env!("CARGO_MANIFEST_DIR");

/// The one directory under `examples/` that is not a program, named rather than inferred. A
/// directory holding no `main.rs` is not a cargo target, so a new one would be built by nothing
/// and reported by nothing; naming the single exception makes the next one a failure that says
/// what it is.
const NOT_A_PROGRAM: &[&str] = &["shared"];

struct Program {
    name: String,
    /// The first non-empty line of the program's own `README.md`.
    question: String,
    /// The same line of its page under `pt-PT/examples/`, with the language label taken off the
    /// front.
    question_pt: String,
    /// Whether the program reads a connection string, taken from the call that reads one and never
    /// from the variable's name appearing in the text.
    needs_database: bool,
}

/// The label is not decoration. Both files are included into one rustdoc page, so without a
/// marker at the top of the Portuguese one the two languages run together into one paragraph.
/// `tests/translation.rs` holds the schemas' Portuguese blocks to a label of their own, for the
/// same reason.
const PT_LABEL: &str = "**Português europeu.** ";

/// The one index row per language: which file carries it, and how it spells the database column.
const INDEXES: [(&str, &str, &str); 2] =
    [("examples/README.md", "yes", "no"), ("pt-PT/examples/README.md", "sim", "não")];

fn examples_dir() -> PathBuf {
    Path::new(ROOT).join("examples")
}

/// Every program under `examples/`, taken from the directory.
fn programs() -> Vec<Program> {
    let mut found = Vec::new();
    let mut entries: Vec<PathBuf> = fs::read_dir(examples_dir())
        .expect("examples/ is missing")
        .map(|e| e.expect("unreadable entry in examples/").path())
        .collect();
    entries.sort();

    for path in entries {
        if !path.is_dir() {
            continue;
        }
        let name = path
            .file_name()
            .and_then(|s| s.to_str())
            .expect("a directory under examples/ with no name")
            .to_string();
        let main = path.join("main.rs");
        if !main.is_file() {
            assert!(
                NOT_A_PROGRAM.contains(&name.as_str()),
                "examples/{name}/ holds no main.rs, so cargo builds nothing from it and no law \
                 here reaches it. Either give it a main.rs and a README.md, or name it in \
                 NOT_A_PROGRAM in this file with a sentence saying what it is instead."
            );
            assert!(
                path.join("README.md").is_file(),
                "examples/{name}/ is declared not a program, which means a reader who opens it \
                 is owed a sentence saying so. Give it a README.md."
            );
            continue;
        }
        assert!(
            !NOT_A_PROGRAM.contains(&name.as_str()),
            "examples/{name}/ is named as not a program and holds a main.rs, so cargo builds a \
             target this test excuses from every law below."
        );

        let source = fs::read_to_string(&main).expect("unreadable main.rs");
        let header = fs::read_to_string(path.join("README.md")).unwrap_or_else(|_| {
            panic!(
                "examples/{name}/ has no README.md. It is the program's header, so this is a \
                 compile error too; it is asserted here as well because the message is worth \
                 more than a macro's."
            )
        });
        let pt_page = Path::new(ROOT).join("pt-PT/examples").join(&name).join("README.md");
        let header_pt = fs::read_to_string(&pt_page).unwrap_or_else(|_| {
            panic!(
                "examples/{name}/ has no pt-PT/examples/{name}/README.md, so this program argues \
                 its case in one language. Portuguese is first class here: see \
                 tests/translation.rs."
            )
        });

        // One copy. An include and a `//!` block in the same file are two headers, and rustdoc
        // joins them, so the drift shows as a page that reads oddly rather than as an error.
        let headers = ["README.md".to_string(), format!("../../pt-PT/examples/{name}/README.md")];
        for header_file in headers {
            assert!(
                source.contains(&format!("#![doc = include_str!(\"{header_file}\")]")),
                "examples/{name}/main.rs does not include its {header_file}, so that header is \
                 readable in one of the two places it is read from."
            );
        }
        assert!(
            !source.lines().any(|l| l.trim_start().starts_with("//!")),
            "examples/{name}/main.rs carries a `//!` block beside the included README.md, which \
             is a second header. Move what it says into examples/{name}/README.md."
        );

        let question = header
            .lines()
            .map(str::trim)
            .find(|l| !l.is_empty())
            .unwrap_or_else(|| {
                panic!(
                    "examples/{name}/README.md says nothing, so nothing can say what question \
                     this program puts to the model."
                )
            })
            .to_string();
        assert!(
            !question.starts_with('#'),
            "examples/{name}/README.md opens with a heading, and its first line is the summary \
             every roster quotes. Open with the sentence: `{question}`"
        );

        let first_pt = header_pt
            .lines()
            .map(str::trim)
            .find(|l| !l.is_empty())
            .unwrap_or_else(|| panic!("pt-PT/examples/{name}/README.md says nothing"));
        let question_pt = first_pt
            .strip_prefix(PT_LABEL)
            .unwrap_or_else(|| {
                panic!(
                    "pt-PT/examples/{name}/README.md opens `{first_pt}`. It owes `{PT_LABEL}` and \
                     then the question, because rustdoc renders both files as one page and the \
                     label is what separates them there."
                )
            })
            .to_string();
        assert!(
            !question_pt.is_empty(),
            "pt-PT/examples/{name}/README.md carries the label and no question after it"
        );

        // Held against its own English page and never a fixed length, as tests/translation.rs
        // holds its blocks: a fixed minimum calls a short header a stub and lets a paragraph
        // stand in for a long one. Portuguese runs a little longer than English as a rule, so
        // half is generous.
        assert!(
            header_pt.len() * 2 >= header.len(),
            "pt-PT/examples/{name}/README.md is {} chars against {} of English, which is a summary \
             rather than a translation. Equal footing means the reader who cannot read the \
             English loses nothing.",
            header_pt.len(),
            header.len()
        );

        found.push(Program {
            name,
            question,
            question_pt,
            needs_database: source.contains(r#"env::var("DATABASE_URL")"#),
        });
    }
    assert!(!found.is_empty(), "examples/ holds no programs, which cannot be right");
    found
}

/// The index a reader browsing the repository lands on, parsed back into rows.
///
/// Parsed rather than searched. A test asking whether the file contains each question passes on a
/// table that also holds a row for a program that is gone, and that row is the one a reader would
/// act on.
fn index_rows(file: &str, yes: &str, no: &str) -> BTreeMap<String, (String, bool)> {
    let index = fs::read_to_string(Path::new(ROOT).join(file)).unwrap_or_else(|_| {
        panic!("{file} is missing, so browsing examples/ shows no argument at all")
    });
    let mut rows = BTreeMap::new();
    for line in index.lines() {
        let line = line.trim();
        // A row, and never the header or the alignment line: `| [`name`](name/) | … | … |`
        let Some(rest) = line.strip_prefix("| [`") else { continue };
        let Some((name, rest)) = rest.split_once("`](") else { continue };
        let cells: Vec<&str> = rest.split('|').map(str::trim).collect();
        assert_eq!(
            cells.len(),
            4,
            "{file} has a row for `{name}` with {} cells, not the three the table \
             declares plus its closing bar",
            cells.len()
        );
        assert_eq!(
            cells[0], format!("{name}/)"),
            "{file} links `{name}` at `{}` rather than at its own directory, so the \
             link a reader follows is not the program the row describes",
            cells[0]
        );
        let db = match cells[2] {
            c if c == yes => true,
            c if c == no => false,
            other => panic!(
                "{file} says `{other}` in the database column for `{name}`. It is \
                 `{yes}` or `{no}`, because a program here either reads a connection string or \
                 does not."
            ),
        };
        let previous = rows.insert(name.to_string(), (cells[1].to_string(), db));
        assert!(previous.is_none(), "{file} has two rows for `{name}`");
    }
    rows
}

/// Closed in both directions, once per language. A program with no row is unreachable from the
/// page a reader lands on; a row with no program is a link that goes nowhere and a question
/// nothing answers. Running it per language stops one index from being kept up while the other
/// quietly falls behind, which is how a second language fails.
#[test]
fn each_index_names_every_program_and_only_programs() {
    let programs = programs();

    for (file, yes, no) in INDEXES {
        let mut rows = index_rows(file, yes, no);
        let portuguese = file.starts_with("pt-PT/");

        for p in &programs {
            let mine = if portuguese { &p.question_pt } else { &p.question };
            let (question, db) = rows.remove(&p.name).unwrap_or_else(|| {
                panic!(
                    "{file} has no row for `{}`, so a reader browsing examples/ cannot \
                     find it. Add:\n\n| [`{}`]({}/) | {mine} | {} |",
                    p.name,
                    p.name,
                    p.name,
                    if p.needs_database { yes } else { no }
                )
            });
            assert_eq!(
                &question, mine,
                "{file} and the page of `{}` beside it disagree about what `{}` answers. The \
                 program's own first line is the one that is right.",
                p.name, p.name
            );
            assert_eq!(
                db, p.needs_database,
                "{file} says `{}` needs a database: {db}, and \
                 `env::var(\"DATABASE_URL\")` in examples/{}/main.rs says {}.",
                p.name, p.name, p.needs_database
            );
        }

        assert!(
            rows.is_empty(),
            "{file} has rows for programs that are not there: {:?}",
            rows.keys().collect::<Vec<_>>()
        );
    }
}

/// The shared modules are reached by path. A `#[path]` naming a file that does not exist is a
/// compile error, so what is worth asserting is the converse: a module under `shared/` that
/// nothing reaches is code no target builds.
#[test]
fn every_shared_module_is_imported_by_a_program() {
    let shared = examples_dir().join("shared");
    let mut modules: Vec<String> = fs::read_dir(&shared)
        .expect("examples/shared/ is missing")
        .map(|e| e.expect("unreadable entry in examples/shared/").path())
        .filter(|p| p.is_dir())
        .map(|p| p.file_name().and_then(|s| s.to_str()).unwrap().to_string())
        .collect();
    modules.sort();
    assert!(!modules.is_empty(), "examples/shared/ holds no modules, so it should not be there");

    let sources: Vec<String> = programs()
        .iter()
        .map(|p| {
            fs::read_to_string(examples_dir().join(&p.name).join("main.rs"))
                .expect("unreadable main.rs")
        })
        .collect();

    for m in &modules {
        let needle = format!("#[path = \"../shared/{m}/mod.rs\"]");
        assert!(
            sources.iter().any(|s| s.contains(&needle)),
            "examples/shared/{m}/ is imported by no program, so nothing compiles it and nothing \
             runs it. Either a program should reach it with `{needle}`, or it should go."
        );
    }
}
