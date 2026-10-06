//! The write direction: every document is read into the generated types, written back out, and
//! read again.
//!
//! The parse tests only read documents, and `examples/shared/simulation/filing.rs` builds its
//! filings with `push_str` rather than with the crate, so without this file nothing here runs
//! the serializer that ships to `cargo add process-modulus`. That serializer can silently drop
//! every child of the root it is given.
//!
//! The defect needs an `abstract` substitution-group head, and neither schema here declares one,
//! so what this file guards is the law rather than one instance of it: **what the generated types
//! carry is what the document carries**. A future head, or a new version of `xsd-parser`, gets a
//! verdict from the build instead of from the next reader.
//!
//! Value equality, not bytes, and not validation either. The written document is shorter than
//! the one read, because comments and indentation are not content, so bytes cannot be the law.
//! Validation cannot be the law either: a document with every optional child dropped still
//! validates, since the roles the defect removes are exactly the ones the schema makes optional.
//! Writing then reading back is the only place where what the types hold meets what the
//! document holds.
//!
//! The converse holds as well, so this file is not read as more than it is: a value that
//! survives the trip is not thereby a valid document. Drop the `label` from an `Operation`'s
//! flattened `Vec` and the crate serializes it without error into a document `xmllint` refuses,
//! and that document round trips through here perfectly, because it is a value the types can
//! hold and the schema cannot. Validity is the validator's job in both directions.
//!
//! What makes this bite is that the parser refuses what it cannot hold. Fed an element no field
//! matches, the generated deserializer stops with `Unexpected event: Start(..)` rather than
//! skipping it. So a role that vanishes from the types cannot come back quietly: either the
//! reparse refuses the name, or the value compares unequal.
//!
//! That the law can fail is shown outside the tree, because the mutation is a schema edit and
//! this harness cannot regenerate itself. An `abstract` head over a role at depth 1 of the root
//! gives an 80-byte document with the root and nothing else. Against it, `assert_eq!` on a value
//! built from the schema's role list fails, and the same assertion on an empty value passes on
//! the identical document. Both halves are why the guard against an empty run below is not
//! decoration.

use std::fmt::Debug;
use std::fs;

use process_modulus::asrt::{CompositionType, CoverageType, DependenceType, RunType};
use process_modulus::pm::ProcessModulusElementType;
use quick_xml::Writer;
use xsd_parser_types::quick_xml::{
    DeserializeSync, SerializeSync, SliceReader, WithDeserializer, WithSerializer,
};

/// The name of a document's outermost element, tag and all.
fn first_element(xml: &str) -> String {
    let mut reader = quick_xml::Reader::from_str(xml);
    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf).expect("well formed XML") {
            quick_xml::events::Event::Start(e) => {
                return String::from_utf8_lossy(e.name().as_ref()).into_owned()
            }
            quick_xml::events::Event::Eof => panic!("no element in the document"),
            _ => buf.clear(),
        }
    }
}

/// Read it, write it, read that back, and hold the two values to being the same value.
fn trip<T>(what: &str, root: &str, xml: &str)
where
    T: WithDeserializer + WithSerializer + PartialEq + Debug,
{
    let value = T::deserialize(&mut SliceReader::new(xml))
        .unwrap_or_else(|e| panic!("{what}: does not read: {e}"));

    let mut writer = Writer::new(Vec::new());
    value
        .serialize(root, &mut writer)
        .unwrap_or_else(|e| panic!("{what}: does not write: {e}"));
    let written = String::from_utf8(writer.into_inner()).expect("the writer emits UTF-8");

    let back = T::deserialize(&mut SliceReader::new(&written)).unwrap_or_else(|e| {
        panic!("{what}: the crate wrote {} bytes it cannot read back: {e}", written.len())
    });

    assert_eq!(
        back, value,
        "{what}: {} bytes in, {} bytes out, and the value did not survive the trip. \
         A child the serializer declines to emit is lost here and nowhere else: it is not a \
         validation error, because the roles this can drop are the optional ones",
        xml.len(),
        written.len()
    );
}

/// Every document this repository ships, against the root it declares.
#[test]
fn every_document_survives_being_written() {
    let root_dir = env!("CARGO_MANIFEST_DIR");
    let mut roots: Vec<String> = Vec::new();

    for dir in ["assets/corpus", "assets/fixtures"] {
        let mut names: Vec<_> = fs::read_dir(format!("{root_dir}/{dir}"))
            .unwrap_or_else(|e| panic!("{dir}: {e}"))
            .map(|e| e.expect("a directory entry").file_name().to_string_lossy().into_owned())
            .filter(|n| n.ends_with(".xml"))
            .collect();
        names.sort();

        for name in names {
            let what = format!("{dir}/{name}");
            let xml = fs::read_to_string(format!("{root_dir}/{what}"))
                .unwrap_or_else(|e| panic!("{what}: {e}"));

            // The document's own root, read as XML. A composition contains a
            // `pm:processModulus`, so anything that only looks for a name in the text
            // picks the embedded one and reads the wrong type.
            let root = first_element(&xml);

            match root.as_str() {
                "pm:processModulus" => trip::<ProcessModulusElementType>(&what, &root, &xml),
                "asrt:coverage" => trip::<CoverageType>(&what, &root, &xml),
                "asrt:run" => trip::<RunType>(&what, &root, &xml),
                "asrt:dependence" => trip::<DependenceType>(&what, &root, &xml),
                "asrt:composition" => trip::<CompositionType>(&what, &root, &xml),
                other => panic!("{what}: root {other} is none of the five published roots"),
            }
            roots.push(root);
        }
    }

    // The guard, and the reason the assertion above means anything. An empty value round
    // trips perfectly through a serializer that emits nothing, so a run over no documents, or
    // over documents reaching only one root, passes while checking nothing.
    let tripped = roots.len();
    roots.sort_unstable();
    roots.dedup();
    assert_eq!(
        roots.len(),
        5,
        "only {:?} of the five published roots were written; a root nobody writes here is a \
         root whose serializer the first consumer runs before this repository does",
        roots
    );
    assert!(
        tripped >= 20,
        "only {tripped} documents were written back; this law is about content surviving, and \
         it shows that of exactly as much content as it was handed"
    );
}

/// The witness, kept, because a mutation that ran once and was reverted is a claim in prose.
/// The perturbation that shows a law able to fail usually lives in a scratchpad and in one
/// person's memory, where nothing re-runs it, and a law whose witness has gone looks the same
/// as a law that examines nothing. So the law above ships with the mutation that makes it
/// fail, and `cargo test` re-runs it.
///
/// The mutation is the defect in miniature: a serializer that declines to emit an optional child.
/// Rather than regenerate from a mutated schema, which this harness cannot do, the child is
/// dropped from the written document before it is read back, which is the same event seen from
/// the same side.
///
/// What it shows is not that something failed. The stripped document is still well formed and
/// still parses, so neither the reader nor a validator objects. Only the value comparison does,
/// which is why this law is written as an equality.
#[test]
fn a_dropped_child_is_caught_only_by_the_comparison() {
    // Not `refutation.xml`, which files no operations at all: the guard below refuses a
    // witness that perturbs nothing, which is the guard doing its job on the witness.
    let path = format!("{}/assets/corpus/enterprise-contract.xml", env!("CARGO_MANIFEST_DIR"));
    let xml = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let value = ProcessModulusElementType::deserialize(&mut SliceReader::new(&xml))
        .expect("enterprise-contract.xml reads");

    let mut writer = Writer::new(Vec::new());
    value.serialize("pm:processModulus", &mut writer).expect("enterprise-contract.xml writes");
    let written = String::from_utf8(writer.into_inner()).expect("UTF-8");

    // `pm:operation` is optional and repeated at depth 1 of the root, which is the shape an
    // abstract head leaves behind. Drop every one of them.
    let (stripped, dropped) = drop_all(&written, "pm:operation");
    assert!(
        dropped >= 2 && !value.operation.is_empty(),
        "the mutation removed {dropped} operations from a document holding {}; a witness that \
         perturbs nothing reports that the law passed and has shown nothing",
        value.operation.len()
    );

    let back = ProcessModulusElementType::deserialize(&mut SliceReader::new(&stripped))
        .expect("the mutated document still parses, which is the point of this test");
    assert_ne!(
        back, value,
        "a document missing {dropped} of its operations compared equal to one holding them, so \
         the law above cannot see the loss it exists to see"
    );
}

/// Remove every `<name>...</name>` block, returning the text and how many went.
fn drop_all(xml: &str, name: &str) -> (String, usize) {
    let (open, close) = (format!("<{name}>"), format!("</{name}>"));
    let (mut out, mut rest, mut n) = (String::new(), xml, 0);
    while let Some(start) = rest.find(&open) {
        let end = rest[start..].find(&close).expect("a closing tag") + start + close.len();
        out.push_str(&rest[..start]);
        rest = &rest[end..];
        n += 1;
    }
    out.push_str(rest);
    (out, n)
}
