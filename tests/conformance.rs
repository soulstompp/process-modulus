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
//!    IS a row forty in both, that the two agree about which rows are marked, and that they
//!    name the same checks.

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

/// The roster slug in a row's third column, where the rule is one that runs.
fn slug(row: &str) -> Option<String> {
    let cell = row.rsplit('|').nth(1)?.trim();
    cell.strip_prefix('`')?.strip_suffix('`').map(str::to_string)
}

/// Every rule `assets/sqlc/checks/` actually runs, named as `checks/roster.sqlc` names it.
fn roster_slugs() -> Vec<String> {
    let path = concat!(env!("CARGO_MANIFEST_DIR"), "/assets/sqlc/checks/roster.sqlc");
    let body = fs::read_to_string(path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let slugs: Vec<String> = body
        .lines()
        .filter_map(|l| l.trim_start().strip_prefix("('"))
        .filter_map(|l| l.split('\'').next())
        .map(str::to_string)
        .collect();
    assert!(
        slugs.len() > 20,
        "only {} rules were read out of the roster, so its shape moved and this file is now \
         holding the conformance table against nothing",
        slugs.len()
    );
    slugs
}

#[test]
fn every_rule_that_runs_is_written_down_for_an_implementer() {
    let listed: Vec<String> = rule_rows(EN).iter().filter_map(|r| slug(r)).collect();
    let missing: Vec<String> = roster_slugs().into_iter().filter(|s| !listed.contains(s)).collect();
    assert!(
        missing.is_empty(),
        "{missing:?} run against every filing this repository loads and appear in no row of \
         {EN}. An implementer reads that table to learn what a validator leaves them, so a rule \
         enforced here and absent there is a rule they are never told they owe."
    );
}

#[test]
fn every_check_the_table_names_is_a_check_that_exists() {
    let roster = roster_slugs();
    let dangling: Vec<String> = rule_rows(EN)
        .iter()
        .filter_map(|r| slug(r))
        .filter(|s| !roster.contains(s))
        .collect();
    assert!(
        dangling.is_empty(),
        "{dangling:?} are named in {EN} as rules that run, and `checks/roster.sqlc` has no such \
         rule. The column then promises an implementer a gate that is not there."
    );
}

#[test]
fn both_conformance_documents_name_the_same_checks() {
    let en: Vec<Option<String>> = rule_rows(EN).iter().map(|r| slug(r)).collect();
    let pt: Vec<Option<String>> = rule_rows(PT).iter().map(|r| slug(r)).collect();
    assert_eq!(
        en, pt,
        "the third column is a slug rather than a sentence, so it is the same in both languages \
         and it pins row N in one document to row N in the other. Where the two disagree, one \
         of them has a row the other does not."
    );
}
