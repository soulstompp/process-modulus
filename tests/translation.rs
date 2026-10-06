//! Which schema annotations carry their Portuguese, and that every published page has its own.
//!
//! The schemas are mostly prose, and that prose is what an adopter reads: `cargo doc` renders it,
//! and it carries rules no validator reaches. This model's origin and its hardest jurisdiction are
//! both Portuguese, so the prose is written in both languages.
//!
//! An `xs:annotation` may hold several `xs:documentation` children, each tagged with `xml:lang`, so
//! one schema carries both languages, and a validator ignores every one of them.
//!
//! Not every annotation has its Portuguese yet. The ones that do are declared in `TRANSLATED`, so
//! none can lose its Portuguese without this test failing, and the rest are printed as a count. The
//! test does not judge a translation. It checks that each one is there, that it is not a stub, and
//! that the English is still beside it.
//!
//! Every published page has its Portuguese page, at the same path under `pt-PT/`, so for the pages
//! the rule covers all of them rather than a declared few. It reaches every page git publishes,
//! whatever the page is called.

use std::collections::BTreeSet;
use std::fs;

#[path = "shared/published.rs"]
mod published;
use published::{portuguese_of, published_documents, root};

/// Every declaration that carries a Portuguese annotation today.
///
/// Adding a name here is the decision to translate that annotation, as adding one to `PERMITTED`
/// in `tests/independence.rs` is the decision there. The tests below hold the schemas to this list.
const TRANSLATED: [(&str, &str); 90] = [
    ("process-modulus.xsd", "Remainder"),
    ("process-modulus.xsd", "Fit"),
    ("process-modulus.xsd", "HolderKind"),
    ("process-modulus.xsd", "Holder"),
    ("process-modulus.xsd", "AbsenceReason"),
    ("process-modulus.xsd", "Provenance"),
    ("process-modulus.xsd", "Absence"),
    ("process-modulus.xsd", "ClaimAbsenceReason"),
    ("process-modulus.xsd", "ClaimAbsence"),
    ("process-modulus.xsd", "Identity"),
    ("process-modulus.xsd", "Derivation"),
    ("process-modulus.xsd", "ComposedDerivation"),
    ("process-modulus.xsd", "MagnitudeDerivation"),
    ("process-modulus.xsd", "FitDerivation"),
    ("process-modulus.xsd", "ClearanceDerivation"),
    ("process-modulus.xsd", "ShareDerivation"),
    ("process-modulus.xsd", "EliminationDerivation"),
    ("process-modulus.xsd", "FactorDerivation"),
    ("process-modulus.xsd", "BoundDerivation"),
    ("process-modulus.xsd", "NarrowingDerivation"),
    ("process-modulus.xsd", "StatedSummedQuantity"),
    ("process-modulus.xsd", "StatedMagnitude"),
    ("process-modulus.xsd", "StatedTimeSlack"),
    ("process-modulus.xsd", "StatedShare"),
    ("process-modulus.xsd", "StatedEliminatedQuantity"),
    ("process-modulus.xsd", "StatedFactor"),
    ("process-modulus.xsd", "StatedAmountOrigin"),
    ("process-modulus.xsd", "StatedRemainder"),
    ("process-modulus.xsd", "StatedBorrowedTerm"),
    ("process-modulus.xsd", "StatedDivisibility"),
    ("process-modulus.xsd", "StatedConstraintOrigin"),
    ("process-modulus.xsd", "StatedNotation"),
    ("process-modulus.xsd", "EvidenceKind"),
    ("process-modulus.xsd", "StatedDenominator"),
    ("process-modulus.xsd", "Demand"),
    ("process-modulus.xsd", "StatedEvidence"),
    ("process-modulus.xsd", "ScopeExtent"),
    ("process-modulus.xsd", "Scope"),
    ("process-modulus.xsd", "StatedScope"),
    ("process-modulus.xsd", "StatedLumpyQuantum"),
    ("process-modulus.xsd", "StatedCouplings"),
    ("process-modulus.xsd", "StatedFit"),
    ("process-modulus.xsd", "NarrowingKind"),
    ("process-modulus.xsd", "Narrowing"),
    ("process-modulus.xsd", "StatedNarrowing"),
    ("process-modulus.xsd", "Claim"),
    ("process-modulus.xsd", "ContributedBasis"),
    ("process-modulus.xsd", "MeasurementBasis"),
    ("process-modulus.xsd", "BorrowedTerm"),
    ("process-modulus.xsd", "ForeignId"),
    ("process-modulus.xsd", "ConstraintOrigin"),
    ("process-modulus.xsd", "LumpyQuantum"),
    ("process-modulus.xsd", "Continuity"),
    ("process-modulus.xsd", "Divisibility"),
    ("process-modulus.xsd", "window"),
    ("process-modulus.xsd", "Nameplate"),
    ("process-modulus.xsd", "capacitySlack"),
    ("process-modulus.xsd", "inventorySlack"),
    ("process-modulus.xsd", "Jagged"),
    ("process-modulus.xsd", "Facility"),
    ("process-modulus.xsd", "Layer"),
    ("process-modulus.xsd", "Coupling"),
    ("process-modulus.xsd", "Stack"),
    ("process-modulus.xsd", "Draw"),
    ("process-modulus.xsd", "Induction"),
    ("process-modulus.xsd", "Operation"),
    ("process-modulus.xsd", "Regime"),
    ("process-modulus.xsd", "chart"),
    ("assertion.xsd", "Answer"),
    ("assertion.xsd", "Nothing"),
    ("assertion.xsd", "Claimed"),
    ("assertion.xsd", "Verdict"),
    ("assertion.xsd", "Citation"),
    ("assertion.xsd", "CoverageEntry"),
    ("assertion.xsd", "Coverage"),
    ("assertion.xsd", "Result"),
    ("assertion.xsd", "Run"),
    ("assertion.xsd", "run"),
    ("assertion.xsd", "coverage"),
    ("assertion.xsd", "FiledLayer"),
    ("assertion.xsd", "DependenceEntry"),
    ("assertion.xsd", "Dependence"),
    ("assertion.xsd", "dependence"),
    ("assertion.xsd", "EliminationAgainst"),
    ("assertion.xsd", "Elimination"),
    ("assertion.xsd", "Part"),
    ("assertion.xsd", "StatedEliminations"),
    ("assertion.xsd", "Fusion"),
    ("assertion.xsd", "Composition"),
    ("assertion.xsd", "composition"),
];

fn schema(name: &str) -> String {
    let path = format!("{}/schema/{name}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"))
}

/// The `name="X"` of every declaration whose annotation carries an `xml:lang="pt"` block.
fn translated_in(src: &str) -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    for (i, _) in src.match_indices(r#"xml:lang="pt""#) {
        // walk back to the declaration this annotation belongs to
        let head = &src[..i];
        if let Some(d) = head.rfind(" name=\"") {
            let rest = &head[d + 7..];
            if let Some(end) = rest.find('"') {
                found.insert(rest[..end].to_string());
            }
        }
    }
    found
}

/// The declared set is exactly what the schemas carry, no more and no fewer.
///
/// It fails when an edit to a long annotation deletes its Portuguese block, which review misses,
/// because the English above it still reads fine.
#[test]
fn every_declared_translation_is_present_and_no_others_are() {
    for file in ["process-modulus.xsd", "assertion.xsd"] {
        let src = schema(file);
        let found = translated_in(&src);
        let declared: BTreeSet<String> = TRANSLATED
            .iter()
            .filter(|(f, _)| *f == file)
            .map(|(_, n)| n.to_string())
            .collect();
        assert_eq!(
            found, declared,
            "{file}: the Portuguese annotations on disk and the declared list disagree. \
             Adding a translation means adding its name to TRANSLATED, which is the point"
        );
    }
}

/// A translation sits beside the English and never replaces it.
///
/// The rest of the repository, the conformance rules among it, quotes the English annotations, and
/// a Portuguese block that took an English one's place would break every one of those quotes.
#[test]
fn the_english_is_still_there_beside_every_translation() {
    for file in ["process-modulus.xsd", "assertion.xsd"] {
        let src = schema(file);
        let pt = src.matches(r#"xml:lang="pt""#).count();
        let en = src.matches(r#"xml:lang="en""#).count();
        assert_eq!(
            pt, en,
            "{file}: {pt} Portuguese blocks against {en} English ones. Every translated \
             annotation must tag its English sibling too, or the pair is not a pair"
        );
    }
}

/// A stub reports as covered, which makes it worse than an honest gap.
///
/// Each Portuguese block is held against its own English block, never against a fixed length:
/// `asrt:run`'s English is two lines, so its Portuguese is two lines as well, while `Nameplate`'s
/// runs to pages. What the test asks is whether an annotation lost most of itself on the way.
#[test]
fn no_translation_is_a_stub() {
    for file in ["process-modulus.xsd", "assertion.xsd"] {
        let src = schema(file);
        for (i, _) in src.match_indices(r#"<xs:documentation xml:lang="en">"#) {
            let after = &src[i..];
            let en_end = after
                .find("</xs:documentation>")
                .expect("unclosed documentation");
            let en = &after[..en_end];

            let rest = &after[en_end..];
            let pt_start = match rest.find(r#"<xs:documentation xml:lang="pt">"#) {
                Some(n) if n < 40 => n,
                _ => continue, // the English block has no Portuguese sibling; caught elsewhere
            };
            let pt_rest = &rest[pt_start..];
            let pt_end = pt_rest
                .find("</xs:documentation>")
                .expect("unclosed documentation");
            let pt = &pt_rest[..pt_end];

            assert!(
                pt.contains("**Português.**"),
                "{file}: a Portuguese block is missing its label. The generator concatenates \
                 every xs:documentation into one Rust doc comment, so without the label the \
                 two languages run together into one paragraph in `cargo doc`"
            );
            // Portuguese runs a little longer than English as a rule, so half is generous.
            let floor = en.len() / 2;
            assert!(
                pt.len() >= floor,
                "{file}: a Portuguese block of {} chars against {} of English is a summary \
                 rather than a translation. Equal footing means the reader who cannot read \
                 the English loses nothing",
                pt.len(),
                en.len()
            );
        }
    }
}

/// What is not translated yet, printed rather than hidden.
///
/// It asserts that each schema carries some Portuguese, and never a percentage: a percentage that
/// may only rise would make a short new annotation look like a step back.
#[test]
fn the_untranslated_remainder_is_visible() {
    let mut total = 0usize;
    for file in ["process-modulus.xsd", "assertion.xsd"] {
        let src = schema(file);
        // every declaration that has prose worth translating
        let annotated =
            src.matches("<xs:documentation").count() - src.matches(r#"xml:lang="pt""#).count();
        let done = translated_in(&src).len();
        total += done;
        println!("{file}: {done} translated, {annotated} annotations in the file");
        assert!(
            done > 0,
            "{file} carries no Portuguese at all; the mechanism is meant to reach both schemas"
        );
    }
    assert!(
        total >= TRANSLATED.len(),
        "the declared list is longer than what the schemas carry"
    );
}

// ---------------------------------------------------------------------------
// The pages, where every one owes its Portuguese rather than a declared few
// ---------------------------------------------------------------------------

/// Every published page has its Portuguese page, and it is a translation rather than a note.
///
/// It fails on a new page, the one somebody writes in a single language to explain what they have
/// just built, which nothing else would ask about.
#[test]
fn every_published_document_has_a_portuguese_sibling_and_it_is_not_a_stub() {
    for shown in published_documents() {
        let en = root().join(&shown);
        let sibling = portuguese_of(&shown);
        let pt = root().join(&sibling);
        let body_pt = fs::read_to_string(&pt).unwrap_or_else(|_| {
            panic!(
                "{shown} has no {sibling}, so whatever it explains is explained in one \
                 language. This model's origin and its hardest jurisdiction are both \
                 Portuguese; the pair is the point."
            )
        });
        let body_en = fs::read_to_string(&en).expect("unreadable markdown");

        assert!(
            body_pt.contains("AO90"),
            "{shown}: the Portuguese sibling does not name the orthography it is written in. \
             Every other one opens with it, and a reader is owed the same sentence about which \
             spelling and which version is authoritative."
        );
        // Held against its own English page, never a fixed length: see `no_translation_is_a_stub`.
        assert!(
            body_pt.len() * 2 >= body_en.len(),
            "{shown}: {} chars of Portuguese against {} of English is a summary rather than a \
             translation. Equal footing means the reader who cannot read the English loses nothing.",
            body_pt.len(),
            body_en.len()
        );
        assert!(
            body_en.contains(sibling.as_str()),
            "{shown} does not point at its Portuguese sibling, so a reader who needs it has to \
             already know it is there."
        );
    }
}
