//! Generate the Rust types from the two schemas in `schema/`.
//!
//! The schema is the source of truth for the types and for their documentation:
//! `RendererFlags`'s doc flags emit every `xs:documentation` block as rustdoc,
//! so the annotations in the schema are what `cargo doc` shows.

use std::fs::write;
use std::path::PathBuf;

use anyhow::{Context, Error};
use xsd_parser::config::{
    GeneratorFlags, InterpreterFlags, NamespaceIdent, OptimizerFlags, RendererFlags,
};
use xsd_parser::{generate, Config, IdentType};

const MODEL_NS: &[u8] = b"https://example.invalid/process-flow/1.0";
const ASSERTION_NS: &[u8] = b"https://example.invalid/assertion/1.0";

fn main() -> Result<(), Error> {
    let out_dir = env_path("OUT_DIR");
    let manifest_dir = env_path("CARGO_MANIFEST_DIR")
        .canonicalize()
        .context("Missing CARGO_MANIFEST_DIR")?;
    let schema_dir = manifest_dir.join("schema");

    // Two schemas, one generate call. `assertion.xsd` xs:imports the base, so a
    // second call would emit the base's types twice under two module trees and the
    // shared BorrowedTerm would stop being shared.
    //
    // The hazard is the second call, not the import. One call resolves an xs:import by
    // its schemaLocation, so an imported schema need not be listed here at all: the
    // five roots below come out byte identical when generated from `assertion.xsd`
    // alone. Both names stay in the loop because it also emits `rerun-if-changed`,
    // which is a different job, and one the build depends on.
    //
    // So no name is dropped from this loop: a partial list is worse than no loop at
    // all. Emitting any `rerun-if-changed` replaces cargo's default of watching the
    // whole package, so a name left out stops being watched, and the next edit to that
    // schema serves the previous generation byte for byte with no error. A stale
    // generation and a broken one look the same.
    let mut schemas = Vec::new();
    for name in ["process-modulus.xsd", "assertion.xsd"] {
        println!("cargo:rerun-if-changed=schema/{name}");
        schemas.push(
            schema_dir
                .join(name)
                .canonicalize()
                .with_context(|| format!("Missing or invalid schema file: {name}"))?,
        );
    }

    let config = Config::default()
        .with_schemas(schemas)
        .set_interpreter_flags(InterpreterFlags::all() - InterpreterFlags::WITH_NUM_BIG_INT)
        // Structurally identical types keep their own names. Every derivable position has a
        // wrapper and a derivation type of the same shape, told apart only by the identities the
        // XSD admits there; merged, a demand's amount would be typed as whichever twin was kept.
        .set_optimizer_flags(OptimizerFlags::all() - OptimizerFlags::REMOVE_DUPLICATES)
        .set_generator_flags(GeneratorFlags::all() - GeneratorFlags::ADVANCED_ENUMS)
        // Every xs:documentation block becomes rustdoc.
        .set_renderer_flags(RendererFlags::all())
        // The generator derives only Debug. A consumer of this model compares
        // documents and holds values taken out of them, so the enums in particular
        // are unusable without PartialEq. Eq is not available: Claim holds f64.
        .with_derive(["Debug", "Clone", "PartialEq"])
        .with_quick_xml()
        .with_generate([
            (
                IdentType::Element,
                NamespaceIdent::namespace(MODEL_NS),
                "processModulus",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "coverage",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "run",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "dependence",
            ),
            (
                IdentType::Element,
                NamespaceIdent::namespace(ASSERTION_NS),
                "composition",
            ),
        ]);

    write(out_dir.join("schema.rs"), generate(config)?.to_string())?;

    // The same hazard as the schemas, one directory over. The `rerun-if-changed` above
    // already replaced cargo's default of watching the whole package, so `examples/` is
    // watched by nothing until this line says so, and an edited header would serve the
    // previous roster byte for byte with no error. It names the directory, so that adding an
    // example counts as a change too: a per-file list misses the example nobody listed.
    println!("cargo:rerun-if-changed=examples");
    write(out_dir.join("examples.md"), roster(&examples(&manifest_dir)?))?;
    Ok(())
}

fn env_path(var: &str) -> PathBuf {
    PathBuf::from(std::env::var(var).unwrap_or_else(|_| panic!("Missing `{var}`")))
}

/// One row per example, taken from the directory and never from a list.
///
/// A named list of examples rots, and it reads like a complete one, so nothing about it looks
/// wrong when it stops being one. The roster below is generated on every build from what is on
/// disk: add an example and it appears, delete one and it goes.
///
/// It is the same bargain as the types. `src/lib.rs` says the schema's `xs:documentation` is
/// what `cargo doc` shows, so you change a schema rather than the crate. Change an example's own
/// `README.md` rather than this file, and the crate's front page follows.
struct Example {
    name: String,
    /// The first line of the example's own `README.md`: the question it exists to answer.
    question: String,
    /// Taken from the call and never from the word. A program's text can name `DATABASE_URL`
    /// while saying it needs none, so a search for the name can report the opposite of the
    /// truth. `env::var("DATABASE_URL")` is what reads one.
    needs_database: bool,
}

/// A missing header is a hard error, not a blank cell. An example nothing describes is one
/// nobody can find from the front page or from the repository page, and a roster that quietly
/// prints an empty row for it hides the omission behind what looks like a complete table.
///
/// The header is a file the program itself includes, so there are two refusals and this is the
/// second. `#![doc = include_str!("README.md")]` at the top of every `main.rs` means a target
/// whose header is missing does not compile at all; what this function adds is the target whose
/// header is present and says nothing.
///
/// To see it refuse: `mkdir examples/zzprobe && printf 'fn main(){}\n' >
/// examples/zzprobe/main.rs`, and `cargo build` must fail naming that directory; delete it and
/// the build comes back. A roster nobody has seen refuse anything is a check nobody knows works.
fn examples(manifest: &std::path::Path) -> Result<Vec<Example>, Error> {
    use std::fs::read_to_string;

    let dir = manifest.join("examples");
    let mut found = Vec::new();
    for entry in std::fs::read_dir(&dir).context("Missing examples/")? {
        let path = entry?.path();
        // A directory holding a `main.rs` is an example and nothing else here is, which is
        // cargo's own test for a target rather than a second test kept in step by hand.
        // `examples/shared/` holds the modules several of these programs import and no `main.rs`,
        // so cargo builds nothing from it and this roster carries no row for it.
        if !path.join("main.rs").is_file() {
            continue;
        }
        let name = path
            .file_name()
            .and_then(|s| s.to_str())
            .context("An example directory with no name")?
            .to_string();
        let source = read_to_string(path.join("main.rs"))
            .with_context(|| format!("Cannot read examples/{name}/main.rs"))?;
        let header = read_to_string(path.join("README.md")).with_context(|| {
            format!("examples/{name}/ has no README.md, so the roster cannot say what it answers \
                     and `include_str!` has nothing to make a rustdoc page from either.")
        })?;
        let question = header
            .lines()
            .map(str::trim)
            .find(|l| !l.is_empty())
            .with_context(|| {
                format!("examples/{name}/README.md says nothing, so the roster cannot say what it \
                         answers. Give it one line naming the question it puts to the model.")
            })?
            .to_string();
        found.push(Example {
            name,
            question,
            needs_database: source.contains(r#"env::var("DATABASE_URL")"#),
        });
    }
    // A total order on the names alone, so two machines emit the same page.
    found.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(found)
}

/// The roster as rustdoc, for `src/lib.rs` to include.
///
/// The crate's front page is where an adopter lands, and the examples are where the argument is.
/// Every claim this repository makes about its own arithmetic is made inside a program that
/// evaluates it, so the claim answers to the program each time it runs, as a note in prose never
/// would. So the front page carries the map and each program carries its own case, and
/// `cargo doc --examples` renders both from one tree.
///
/// No links between the pages, on purpose. `cargo doc --examples` renders each example as its
/// own crate, so a link from here to one of them is a relative path that exists in a local
/// `target/doc` and does not exist on docs.rs, where only the library is built. A link that
/// resolves on one of the two renderings is worse than the command that produces both.
fn roster(examples: &[Example]) -> String {
    use std::fmt::Write as _;

    let mut md = String::from(
        "\n# The examples, and the question each one puts to the model\n\n\
         This table is generated from `examples/` on every build, so it lists what is on disk. \
         Each row's question is the first line of that program's own `README.md`, which is its \
         whole header: `examples/<name>/README.md` is the page rustdoc renders and the page the \
         repository renders, because the program includes that one file.\n\n\
         **Each program carries its own case.** Whatever it says about the figures sits in its \
         header or in the comment on the code that works them out, so a claim and the code \
         that checks it change together.\n\n\
         | example | the question it answers | database |\n|---|---|---|\n",
    );
    for e in examples {
        let db = if e.needs_database { "yes" } else { "no" };
        let _ = writeln!(md, "| `{}` | {} | {db} |", e.name, e.question);
    }
    md.push_str(
        "\n**A `yes` means the program needs the database.** None of these programs skips when \
         the database is absent, because a check that did not run has checked nothing, so they \
         fail to run instead.\n\n\
         Read them rendered, or run them:\n\n\
         ```text\n\
         cargo doc --examples --open\n\
         cargo run --example soundness\n\
         ```\n\n\
         `docs.rs` builds the library only, so the pages behind this table exist wherever \
         `cargo doc --examples` was run. The sources travel with the crate either way.\n",
    );
    md
}
