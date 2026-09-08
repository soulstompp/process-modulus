//! Every type documents its own children, and the list is held to the content model.
//!
//! ⭐⭐⭐ A `WHAT IT CONTAINS` BLOCK IS WHAT A READER USES AS THE CONTENT MODEL. Almost nobody
//!    reads an `xs:sequence`; they read the list above it, and then they file against what the
//!    list says. So a name in the list that the sequence does not declare sends a filer to write
//!    an element that does not validate, and a child the list omits is one they never learn they
//!    may send. Both had happened: `Claim` and `Absence` documented an `asserter` that has never
//!    existed in either content model, `Claim` never mentioned its required `denominator`, and
//!    `evidence` is required on all three assertion roots and was named in none of them.
//!
//! ⭐⭐ IT HOLDS BOTH LANGUAGES SEPARATELY, against the same sequence. An implementer reads one
//!    document, and a Portuguese list that has drifted from the English one is not a translation.
//!
//! ⚠️ A TYPE WITH NO LIST IS NOT A FAILURE. Several wrappers explain themselves in a sentence
//!   instead, and a sentence is not a content model claiming to be complete. What this holds is
//!   the types that DO make the claim.

use std::collections::BTreeSet;

const BASE: &str = include_str!("../schema/process-modulus.xsd");
const ASSERTION: &str = include_str!("../schema/assertion.xsd");

/// One named `xs:complexType`: its name and its whole body.
///
/// ⭐ Split on the two-space indent, which is where every named type in these schemas starts.
/// The one anonymous type in the pair is the document root's, nested inside an `xs:element` and
/// carrying no annotation of its own, so it declares nothing this test could hold.
fn named_types(schema: &str) -> Vec<(&str, &str)> {
    let mut out = Vec::new();
    let open = "  <xs:complexType name=\"";
    let close = "\n  </xs:complexType>";
    let mut rest = schema;
    while let Some(i) = rest.find(open) {
        let after = &rest[i + open.len()..];
        let name_end = after.find('"').expect("unterminated type name");
        let body_end = after.find(close).expect("unclosed complexType");
        out.push((&after[..name_end], &after[name_end..body_end]));
        rest = &after[body_end..];
    }
    out
}

/// The children a type actually declares, in the order the sequence gives them.
fn children(body: &str) -> Vec<&str> {
    let mut out = Vec::new();
    // ⭐ A `ref=` is a child too, and the one in this pair is the document root embedded whole.
    for needle in ["<xs:element name=\"", "<xs:element ref=\""] {
        let mut rest = body;
        while let Some(i) = rest.find(needle) {
            rest = &rest[i + needle.len()..];
            let end = rest.find('"').expect("unterminated element name");
            out.push(rest[..end].rsplit(':').next().unwrap());
        }
    }
    out
}

/// The documentation for one language, or nothing where the type carries none.
fn documentation<'a>(body: &'a str, lang: &str) -> Option<&'a str> {
    let open = format!("<xs:documentation xml:lang=\"{lang}\">");
    let i = body.find(&open)? + open.len();
    let rest = &body[i..];
    let end = rest.find("</xs:documentation>")?;
    Some(&rest[..end])
}

/// The names one list entry claims. The head of the entry is everything before the description,
/// and it takes four shapes in these schemas:
///
/// | written | names |
/// |---|---|
/// | `witness` | `witness` |
/// | `entry+` | `entry` |
/// | `low · mostLikely · high`, `lumpy \| continuous` | all three, all two |
/// | `absent/reason = none`, `origin intrinsic/contractual/policy` | `absent`, `origin` |
///
/// ⭐ The last row is the one worth naming: a wrapper lists its `absent` child once per REASON,
/// because the three reasons are three different facts, and an entry that says which reason it
/// means is still an entry about the one child.
fn names_in(head: &str) -> Vec<&str> {
    if head.contains('=') {
        return vec![head.split('=').next().unwrap().split('/').next().unwrap().trim()];
    }
    if head.contains('·') || head.contains('|') {
        return head
            .split(['·', '|'])
            .filter_map(|p| p.split_whitespace().next())
            .collect();
    }
    vec![head.split_whitespace().next().unwrap_or("")]
}

/// The children a `WHAT IT CONTAINS` block claims, or nothing where the type explains itself in
/// prose instead.
///
/// ⛔ THE LIST ENDS AT THE FIRST PARAGRAPH, and that is not a detail: `CoverageEntry` follows its
///   list with a SECOND indented list, of the two ways one child may be filled. Reading on would
///   report those two as children the type does not have.
fn listed(doc: &str, heading: &str) -> Option<Vec<String>> {
    let start = doc.find(heading)?;
    let mut names: Vec<String> = Vec::new();
    for line in doc[start..].lines().skip(1) {
        if line.trim().is_empty() {
            continue;
        }
        let indent = line.len() - line.trim_start().len();
        if indent != 8 {
            if indent > 8 {
                continue; // a description running onto the next line
            }
            if !names.is_empty() {
                break; // a paragraph, so the list is over
            }
            continue;
        }
        let entry = line.trim_end();
        let head = match entry.trim().find("  ") {
            Some(i) => &entry.trim()[..i],
            None => continue,
        };
        for n in names_in(head) {
            names.push(n.trim_end_matches('+').to_string());
        }
    }
    if names.is_empty() { None } else { Some(names) }
}

#[test]
fn every_documented_content_list_names_exactly_the_children_the_type_declares() {
    let mut held = 0usize;
    let mut wrong: Vec<String> = Vec::new();
    for (file, schema) in [("process-modulus.xsd", BASE), ("assertion.xsd", ASSERTION)] {
        for (name, body) in named_types(schema) {
            let declared: Vec<&str> = children(body);
            for (lang, heading) in [("en", "WHAT IT CONTAINS"), ("pt", "O QUE CONTÉM")] {
                let Some(doc) = documentation(body, lang) else { continue };
                let Some(claimed) = listed(doc, heading) else { continue };
                held += 1;
                let claimed_set: BTreeSet<&str> = claimed.iter().map(String::as_str).collect();
                let declared_set: BTreeSet<&str> = declared.iter().copied().collect();
                let ghosts: Vec<&&str> = claimed_set.difference(&declared_set).collect();
                let omitted: Vec<&&str> = declared_set.difference(&claimed_set).collect();
                if !ghosts.is_empty() {
                    wrong.push(format!(
                        "{file} `{name}` [{lang}] documents {ghosts:?}, which the content model \
                         does not declare, so a filer who sends one gets a validation error"
                    ));
                }
                if !omitted.is_empty() {
                    wrong.push(format!(
                        "{file} `{name}` [{lang}] never names {omitted:?}, so a filer reading \
                         the list does not learn the element exists"
                    ));
                }
            }
        }
    }
    assert!(
        held > 30,
        "only {held} content lists were found, so the annotation layout moved and this test is \
         now holding almost nothing"
    );
    assert!(wrong.is_empty(), "\n  {}", wrong.join("\n  "));
}
