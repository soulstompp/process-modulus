//! ⛔⛔⛔ WHICH OF THE SCHEMA'S ANNOTATIONS SPEAK PORTUGUESE, DECLARED RATHER THAN COUNTED.
//!
//! The schemas are mostly prose, and that prose is the artifact: `cargo doc` renders it, an
//! adopter reads it, and it carries rules no validator can reach. A schema whose prose exists
//! only in English is readable by one audience, and this model's origin and its hardest
//! jurisdiction are both Portuguese.
//!
//! ⭐⭐ XSD SOLVES THIS NATIVELY AND NOTHING WAS INVENTED. A single `xs:annotation` may hold
//! several `xs:documentation` children, each tagged with `xml:lang`. One schema stays one
//! schema — the artifact does not fork — and a validator ignores annotations entirely.
//!
//! ⚠️ COVERAGE IS PARTIAL, AND THAT IS THE WHOLE REASON THIS FILE EXISTS. Declaring the
//! translated set here means a Portuguese annotation cannot be dropped silently, and the
//! untranslated remainder is a number a reader can see rather than a claim nobody checked.
//! ⛔ This test does NOT judge the translations. It cannot. It checks that they are present,
//! that they are not stubs, and that the English is still there beside them.
//!
//! ⭐⭐⭐ AND THE SAME ARGUMENT REACHES THE MARKDOWN, WHERE COVERAGE IS NOT PARTIAL. A published
//! page carries rules no validator reaches exactly as an annotation does, and it is what a reader
//! browsing the repository lands on, so the roster idiom above is the wrong shape for it: every
//! one of them owes a Portuguese sibling, so the law is a closure rather than a declared list.
//! A directory whose argument exists in English alone is a directory one audience cannot use.
//!
//! ⛔⛔ AND THE CLOSURE IS OVER EVERY PUBLISHED PAGE, NOT OVER THE NAME `README.md`. A law keyed
//! on one file name holds exactly until somebody writes a page called something else, and then it
//! reports success about a file it never looked at. `conformance/adoption.md` is that page and it
//! was already translated, which is the only reason the widening accuses nothing: the rule was
//! being kept by hand where the law could not see it.

use std::collections::BTreeSet;
use std::fs;

#[path = "shared/published.rs"]
mod published;
use published::{published_documents, root};

/// Every declaration that carries a Portuguese annotation today.
///
/// ⛔ ADDING A NAME HERE IS THE WHOLE DECISION, exactly as it is in `tests/independence.rs`.
/// The list is the claim; the assertions below only hold the schema to it.
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

/// ⭐ The declared set is exactly what the schemas carry — no more, and no fewer.
///
/// ⛔ The failure this catches is a Portuguese block deleted by a careless edit to a long
/// annotation, which is invisible in review because the English above it still reads fine.
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

/// ⛔⛔ A TRANSLATION SITS BESIDE THE ENGLISH AND NEVER REPLACES IT.
///
/// The English annotation is what the rest of the repository, the findings and the
/// conformance rules all quote. A Portuguese block that displaced it would silently break
/// every one of those references.
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

/// ⚠️ A stub is worse than an honest gap, because it reports as covered.
///
/// ⛔ MEASURED AGAINST ITS OWN ENGLISH SIBLING AND NEVER AGAINST A FIXED FLOOR. An absolute
/// minimum called `asrt:run` a stub — its English is two lines, so a faithful translation is
/// two lines — while it would have waved through a one-paragraph rendering of `Nameplate`,
/// whose English runs to eight thousand characters. The question is never "is this long
/// enough", it is "did this annotation lose most of itself in translation".
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
                 every xs:documentation into ONE Rust doc comment, so without the label the \
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

/// ⭐ What is NOT translated, reported rather than hidden.
///
/// ⛔ This asserts a floor and never a percentage. A coverage number that only ever goes up
/// is the metric this repository already refuses elsewhere: it would make adding a short
/// annotation look like a regression and tempt somebody to translate the cheap ones.
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
// The markdown, where the rule is a closure and not a roster
// ---------------------------------------------------------------------------

/// ⭐ Every published page has a Portuguese sibling, and it is a translation rather than a note.
///
/// ⛔ THE FAILURE THIS CATCHES IS A NEW PAGE, not a deleted file. Somebody writes a page to
/// explain something they just built, in the language they were thinking in, and nothing asks
/// about the other one. Measured when this law was written, three directories were in that state.
#[test]
fn every_published_document_has_a_portuguese_sibling_and_it_is_not_a_stub() {
    for shown in published_documents() {
        let en = root().join(&shown);
        let stem = en.file_stem().and_then(|s| s.to_str()).expect("a .md path has a stem");
        let sibling = format!("{stem}.pt.md");
        let pt = en.with_file_name(&sibling);
        let body_pt = fs::read_to_string(&pt).unwrap_or_else(|_| {
            panic!(
                "{shown} has no {sibling} beside it, so whatever it explains is explained in \
                 one language. This model's origin and its hardest jurisdiction are both \
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
        // Measured against its own sibling, never against a fixed floor: see `no_translation_is_a_stub`.
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
