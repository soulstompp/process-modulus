//! The two conformance documents say the same thing, or they are two documents.
//!
//! ⭐⭐⭐ A TRANSLATION IS NOT A SUMMARY, AND NOTHING WAS CHECKING THE DIFFERENCE.
//!    `conformance/README.md` and `conformance/README.pt.md` are parallel documents with the
//!    same section headings, and an implementer picks one. When the English table enumerated
//!    forty-seven rules and the Portuguese one grouped them into seven, the two readers were
//!    not owed the same thing, and every test in this repository passed.
//!
//! ⛔ THE RULE TABLE IS THE ONE PLACE A COUNT LIVES. State in prose how many rules there are,
//!    how many carry the `NOT REACHABLE BY A VALIDATOR` marker and how many do not, and all
//!    three drift, because a number in prose is a number nobody recounts. The prose names this
//!    file instead and this file counts the table.
//!
//! ⚠️ IT CHECKS SHAPE AND NEVER MEANING. That row forty in one language says what row forty
//!    says in the other is a thing only a reader can know. What a test can hold is that there
//!    IS a row forty in both, and that the two agree about which rows are marked — which is
//!    exactly the drift that happened.

use std::fs;

const EN: &str = "conformance/README.md";
const PT: &str = "conformance/README.pt.md";

/// The rule rows of the "what a validator cannot reach" table: every table row after the
/// heading that introduces it, minus the header and separator.
fn rule_rows(path: &str) -> Vec<String> {
    let body = fs::read_to_string(format!("{}/{path}", env!("CARGO_MANIFEST_DIR")))
        .unwrap_or_else(|e| panic!("{path}: {e}"));
    let start = body
        .lines()
        .position(|l| l.starts_with("## ") && (l.contains("validator cannot reach") || l.contains("validador não alcança")))
        .unwrap_or_else(|| panic!("{path}: no section introducing the rule table"));
    body.lines()
        .skip(start)
        .filter(|l| l.starts_with("| "))
        .filter(|l| !l.starts_with("| the rule") && !l.starts_with("| a regra"))
        .map(|l| l.to_string())
        .collect()
}

#[test]
fn both_conformance_documents_owe_the_same_number_of_rules() {
    let en = rule_rows(EN);
    let pt = rule_rows(PT);
    assert_eq!(
        en.len(),
        pt.len(),
        "the rule tables are {} rules in English and {} in Portuguese. An implementer reads \
         ONE of these documents and is owed the same list either way, so a summary on one side \
         is not a translation of an enumeration on the other.",
        en.len(),
        pt.len()
    );
    assert!(
        en.len() > 40,
        "only {} rules were found, so the table was probably not located: the section heading \
         moved and this test is now measuring nothing",
        en.len()
    );
}

#[test]
fn both_conformance_documents_mark_the_same_rules_as_unenforced() {
    let mark = |rows: Vec<String>| -> Vec<usize> {
        rows.iter()
            .enumerate()
            .filter(|(_, r)| r.contains('*') && !r.contains("**"))
            .map(|(i, _)| i)
            .collect()
    };
    let en = mark(rule_rows(EN));
    let pt = mark(rule_rows(PT));
    assert_eq!(
        en, pt,
        "the asterisk says a rule is stated in prose WITHOUT the `NOT REACHABLE BY A VALIDATOR` \
         marker, which is a fact about the schema rather than about a language. English marks \
         rows {en:?} and Portuguese marks {pt:?}."
    );
}
