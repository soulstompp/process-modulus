// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT.
// GitHub renders a directory's README and renders no `//!` block at all, so an argument
// kept only in the source is unreadable from the one place this repository is published.
// `include_str!` makes that same file rustdoc's page, so the two renderings cannot disagree
// and a missing header is a compile error rather than a blank row on the front page.
//
// ⭐⭐ BOTH LANGUAGES ARE INCLUDED, WHICH IS WHAT THE SCHEMAS ALREADY DO. An `xs:annotation`
// holds an `xml:lang="en"` block and an `xml:lang="pt"` block and the generator concatenates
// them into one Rust doc comment; these two files are the same arrangement one directory over.
// A Portuguese page rendered nowhere would be a translation nobody reads, which is the
// second-class citizenship `tests/translation.rs` exists to refuse.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;

// ⛔ AND THE SCAN OF THIS DIRECTORY IS SHARED FOR THE SAME REASON. `examples/compositions/main.rs`
// asks the identical question of `examples/`, and two copies of one walk is how the two answers
// start to differ.
#[path = "../shared/sources/mod.rs"]
mod sources;
use tree::{emitted, references, templates};

/// Documents that are parsed only by Rust tests and never reach the database, each with the
/// reason. ⛔ Adding a name here is the whole decision: it removes a document from every SQL
/// query, every check and every report at once, and the only thing that says so is this list.
const RUST_ONLY: &[(&str, &str)] = &[
    ("coverage-us-gaap", "a coverage assertion; tests/coverage_parse.rs"),
    ("coverage-pt-ncrf-pe", "a coverage assertion; tests/coverage_parse.rs"),
    ("run-2026-08-30", "a run record; tests/coverage_parse.rs"),
    ("dependence-group-consolidation", "a dependence assertion; tests/dependence_parse.rs"),
    ("every-claimed", "a draft-state fixture; tests/fixtures.rs"),
    ("every-draft", "a draft-state fixture; tests/fixtures.rs"),
];

#[path = "../shared/database/mod.rs"]
mod database;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example reports what the corpus says, and it cannot do \
         that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = database::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. Nothing unobserved: every relation, and every document.
    // ------------------------------------------------------------------
    let sqlc = Path::new("assets/sqlc");
    let mut files = Vec::new();
    templates(sqlc, sqlc, &mut files);

    let composed: BTreeSet<String> = files.iter().flat_map(|(_, b)| references(&emitted(b))).collect();

    // A root is reached by no other template. It earns its place by being run: as a psql entry
    // point, or by an example naming its composed output.
    let examples = sources::all();
    let entry_points = ["ingest.sqlc", "rules.sqlc", "matrices.sqlc", "invariance.sqlc", "views.sqlc"];

    let mut unobserved: Vec<&str> = Vec::new();
    for (name, _) in &files {
        if composed.contains(name) || entry_points.contains(&name.as_str()) {
            continue;
        }
        let emitted = format!("assets/sql/{}", name.replace(".sqlc", ".sql"));
        if !examples.contains(&emitted) {
            unobserved.push(name);
        }
    }
    unobserved.sort_unstable();

    // ⛔ A template carrying an open `@slot` emits no .sql and is a shape rather than a query,
    //   so it is reached through its fillers and never directly. That is handled above by the
    //   `composed` set: a shape is always composed by whoever fills it.
    println!(
        "1. relations: {} templates, {} reached by something",
        files.len(),
        files.len() - unobserved.len()
    );
    for u in &unobserved {
        println!("   ⛔ {u} is read by nothing");
    }

    let on_disk: Vec<PathBuf> = ["assets/corpus", "assets/fixtures"]
        .iter()
        .flat_map(|d| fs::read_dir(d).expect("readable").flatten().map(|e| e.path()))
        .filter(|p| p.extension().is_some_and(|x| x == "xml"))
        .collect();
    let ingest = fs::read_to_string("assets/sqlc/ingest.sqlc").expect("readable");

    let mut unreached: Vec<String> = Vec::new();
    let mut rust_only = 0usize;
    for p in &on_disk {
        let stem = p.file_stem().expect("named").to_string_lossy().into_owned();
        if ingest.contains(&format!("'{stem}'")) {
            continue;
        }
        match RUST_ONLY.iter().find(|(n, _)| *n == stem) {
            Some(_) => rust_only += 1,
            None => unreached.push(stem),
        }
    }
    unreached.sort();

    println!(
        "\n   documents: {} on disk, {} ingested, {} parsed only by Rust",
        on_disk.len(),
        on_disk.len() - rust_only - unreached.len(),
        rust_only
    );
    for (name, why) in RUST_ONLY {
        println!("      · {name:<32} {why}");
    }
    for u in &unreached {
        println!("   ⛔ {u}.xml is reached by nothing at all");
    }

    // ⛔⛔⛔ THE ASSERTION THIS EXAMPLE EXISTS FOR. A relation nobody reads and a document
    //     nobody parses are both invisible, and invisible reads from the outside exactly like
    //     absent. `layers/drawn.sqlc` was absent for months and nothing said so.
    assert!(
        unobserved.is_empty() && unreached.is_empty(),
        "something in the tree is reached by nothing"
    );

    // ------------------------------------------------------------------
    // 2. The census: what the corpus says when somebody asks.
    // ------------------------------------------------------------------
    let docs = sqlx::query_file!("assets/sql/queries/observations/1-documents.sql")
        .fetch_all(&pool)
        .await?;
    let no_witness = docs.iter().filter(|d| d.witness.is_empty()).count();
    println!(
        "\n2. documents in the database: {}, of which {} name no witness",
        docs.len(),
        no_witness
    );
    println!("   ⛔ every one of those {no_witness} is a pm:processModulus. It is the only root");
    println!("      that carries no document-level provenance, so a stipulation and an");
    println!("      observation are the same shape to anything reading the tree.");
    // ⭐ The standard a composition works under, a different question from the regime: the
    //   regime is what the MEMBERS reported under, the citation is what governs combining them.
    let cited: Vec<_> = docs.iter().filter(|d| !d.under.is_empty()).collect();
    println!("   ⭐ {} document(s) name the instrument they compose under:", cited.len());
    for d in &cited {
        println!("      {:<32} {}", d.filing, d.under);
    }

    let standing = sqlx::query_file!("assets/sql/queries/observations/2-what-nobody-claims.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n3. where claims say they came from");
    for s in &standing {
        println!("   {:<22} {:>4}", s.says, s.claims);
    }

    let denoms = sqlx::query_file!("assets/sql/queries/observations/3-denominators.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n4. denominators the corpus leans on: {}", denoms.len());
    for d in &denoms {
        println!("   {:<8} {:<14} {:>4}  {}", d.kind, d.denominator, d.claims, d.filed_on);
    }
    println!("   ⭐ `week` and `semana` are two rows because two filers wrote two tokens.");

    let patience = sqlx::query_file!("assets/sql/queries/observations/4-patience.sql")
        .fetch_all(&pool)
        .await?;
    let filed = patience.iter().filter(|p| p.state == "filed").count();
    println!(
        "\n5. patience: {} of {} layers state how long demand survives unanswered",
        filed,
        patience.len()
    );
    for p in patience.iter().filter(|p| p.state == "filed") {
        println!(
            "   {} / {}: {} {}   (the demand is in {})",
            p.filing,
            p.layer,
            p.mode.unwrap_or_default(),
            p.unit,
            p.demand_unit
        );
    }

    let slacks = sqlx::query_file!("assets/sql/queries/observations/5-slack-coverage.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n6. buffer coverage");
    println!("   {:<10} {:<12} {:>6} {:>8} {:>8}", "buffer", "evidence", "sized", "at zero", "absent");
    for s in &slacks {
        println!(
            "   {:<10} {:<12} {:>6} {:>8} {:>8}",
            s.buffer,
            s.evidence.clone().unwrap_or_default(),
            s.sized,
            s.sized_at_zero,
            s.absent
        );
    }
    // ⭐ Printed, never pinned. The day somebody sizes a capacity slack above zero this line
    //   changes and nothing fails, which is the difference between an observation and a rule.
    println!("   ⭐ A sized zero is the TIGHTEST bound, not a missing one.");

    let fixtures = sqlx::query_file!("assets/sql/queries/observations/6-absences-in-the-fixtures.sql")
        .fetch_all(&pool)
        .await?;
    let total: i64 = fixtures.iter().map(|f| f.times).sum();
    println!(
        "\n7. the fixtures decline {} questions across {} kinds, on purpose, which is what a",
        total,
        fixtures.len()
    );
    println!("   stipulation is for. ⛔ Not counted as evidence anywhere; rules.sql composes the");
    println!("   corpus census and correctly not this one.");

    // ------------------------------------------------------------------
    // 3. Every remainder has had the closure question put to it.
    // ------------------------------------------------------------------
    let standings = sqlx::query_file!("assets/sql/queries/observations/7-remainder-standing.sql")
        .fetch_all(&pool)
        .await?;
    let asked: i64 = standings.iter().map(|s| s.remainders).sum();
    let computable: i64 =
        sqlx::query_file!("assets/sql/queries/observations/7b-remainders-computable.sql")
            .fetch_one(&pool)
            .await?
            .computable;

    println!(
        "\n8. remainders: {asked} of {computable} computable asked about the set they sit in"
    );
    for s in &standings {
        println!("   {:<32} {:>3}   {}", s.standing, s.remainders, s.filings);
    }

    // ⛔⛔ THE SECOND ASSERTION, AND IT IS ABOUT COVERAGE RATHER THAN ABOUT ANSWERS. Every
    //    remainder the arithmetic can reach must appear in layers/remainder_scope.sqlc with
    //    some standing. `nobody bounded the set` is a perfectly honest standing and fails
    //    nothing; a remainder that never had the question put to it is the failure.
    assert_eq!(
        asked, computable,
        "a remainder reaches the arithmetic without appearing in layers/remainder_scope.sqlc"
    );

    let spills = sqlx::query_file!("assets/sql/queries/observations/8-spillovers.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n9. referrals, a person settles these, not a checker: {}", spills.len());
    for s in &spills {
        println!(
            "   {} holds {} ~ {}, which {} observed  (its own search: {})",
            s.borne_by, s.from_layer, s.to_layer, s.observed_in, s.their_search
        );
    }
    println!("   ⛔ Not violations. A filing is not the system, and one document's observation");
    println!("      is a projection onto another rather than an accusation against it.");

    // ⭐ The union of the two search relations, which neither half can answer: how often does
    //   anybody look at all? That is a fact about the practice rather than about either
    //   mechanism, and it is the only thing that reads epistemics/searches.sqlc whole.
    let diligence = sqlx::query_file!("assets/sql/queries/observations/9-diligence.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n10. did anybody look?");
    let mut seen = "";
    for d in &diligence {
        if d.looked_for != seen {
            println!("   {}", d.looked_for);
            seen = &d.looked_for;
        }
        println!("      {:<20} {:>3}", d.answer, d.times);
    }

    // ⭐⭐⭐ THE EVIDENCE FOR AN ELIMINATION, AND THE ONLY DIRECTION THAT FINDS A MISSING ONE.
    //    `asrt:Elimination/between` is repeating and no rule reads it, so nothing puts it under
    //    pressure to have a column, a table or an ingest, and eight filed instances are parsed
    //    out of the corpus and thrown away on every load. The query side cannot find that: a
    //    rule reads what it needs, so a field nothing reads is under no pressure to exist. The
    //    question that finds it is "can this document be written back out from what is stored".
    let evidence =
        sqlx::query_file!("assets/sql/queries/observations/10-elimination-evidence.sql")
            .fetch_all(&pool)
            .await?;
    let named = evidence.iter().filter(|e| e.named > 0).count();
    println!(
        "\n11. eliminations, and what each says it is between: {} of {} name their evidence",
        named,
        evidence.len()
    );
    for e in &evidence {
        println!(
            "   {:<26} {:<15} {:<10} {:>12}   {}",
            e.composition, e.composed_layer, e.quantity, e.size, e.between
        );
    }
    println!("   ⛔ `(none named)` is not a defect. `between` is minOccurs=0, and a composer");
    println!("      eliminating against a member that files nothing has nothing to name.");

    // ------------------------------------------------------------------
    // ⛔⛔⛔ THE CORPUS DIRECTORY AGAINST WHAT INGEST LOADED, WHICH NO RELATION HERE CAN ASK.
    //    Everything in this file is DERIVED FROM WHAT LOADED, so it can report a document that
    //    arrived and was never decided about and it can NEVER report one that is on disk and did
    //    not arrive: an unloaded file leaves no row to read. That is `diagrams/notation.sqlc`'s
    //    argument one stage earlier in the pipeline, and it wants the same repair: declare it.
    //
    // ⭐⭐ IT WAS STATED, IN PROSE, IN `assets/ddl/schema.ddl` BESIDE THE `kind` CHECK, and the
    //    comment is correct and no program read it. So a fourth kind added tomorrow loads nothing
    //    and says nothing, and the day ingest learns to load one the sentence goes quietly stale.
    //    ⛔ THE LAW RUNS BOTH WAYS on purpose: a row saying `loaded` whose filing is absent is an
    //    ingest that broke, and a row saying `not loaded` whose filing is PRESENT is this roster
    //    gone stale. A comment can only ever fail in the first direction.
    // ------------------------------------------------------------------
    let on_disk = sqlx::query_file!("assets/sql/scope/documents_on_disk.sql")
        .fetch_all(&pool)
        .await?;
    let mut files: Vec<String> = fs::read_dir("assets/corpus")?
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|x| x == "xml"))
        .filter_map(|p| p.file_stem().map(|s| s.to_string_lossy().into_owned()))
        .collect();
    files.sort();
    let mut declared: Vec<String> =
        on_disk.iter().filter_map(|d| d.document.clone()).collect();
    declared.sort();
    assert_eq!(
        files, declared,
        "the corpus directory and scope/documents_on_disk.sqlc disagree about which documents \
         exist, so a file could be added and load nothing with nothing to say so"
    );
    let loaded_now: std::collections::BTreeSet<&str> =
        docs.iter().map(|d| d.filing.as_str()).collect();
    let mut wrong = Vec::new();
    for d in &on_disk {
        let name = d.document.as_deref().unwrap_or("?");
        let says = d.loaded == Some(true);
        let is = loaded_now.contains(name);
        assert_eq!(
            says, d.not_loaded_because.is_none(),
            "{name}: a document that does not load owes a typed reason, and one that loads may \
             not carry an excuse"
        );
        if says != is {
            wrong.push(format!(
                "{name}: the roster says {} and the database says {}",
                if says { "loaded" } else { "not loaded" },
                if is { "loaded" } else { "not loaded" }
            ));
        }
    }
    let unloaded = on_disk.iter().filter(|d| d.loaded != Some(true)).count();
    println!(
        "\n10b. the corpus directory against ingest: {} documents, {} loaded, {} not",
        on_disk.len(),
        on_disk.len() - unloaded,
        unloaded
    );
    for d in on_disk.iter().filter(|d| d.loaded != Some(true)) {
        println!("   ⛔ {:<32} [{}] {}", d.document.as_deref().unwrap_or("?"),
                 d.kind.as_deref().unwrap_or("?"),
                 d.not_loaded_because.as_deref().unwrap_or(""));
    }
    assert!(wrong.is_empty(), "the corpus roster disagrees with the database: {wrong:?}");
    println!("   ⭐ Three document KINDS the schema admits and ingest does not read yet. The");
    println!("      `filing.kind` CHECK holds all five so the domain closes where the SCHEMA");
    println!("      closes; this is the same boundary, in a form a program can fail on.");

    // ⭐⭐⭐ THE SAME EIGHT ROWS AS A POINTER RATHER THAN AS EVIDENCE, WHICH IS THE DIFFERENCE
    //    THAT HID THEM. §11 above reads `between` as what an elimination is ABOUT; this reads it
    //    as what the document POINTS AT. The model has two `pm:ForeignId` references and only the
    //    part has a relation naming it as one, so an enumeration of what this model reaches in
    //    other documents returns half the answer and nothing says which half.
    //
    // ⛔⛔ REPORTED, NEVER ASSERTED. A dangling PART is a violation because the fusion sum needs
    //    it; a dangling `between` is ORDINARY and the schema says so. That licence is exactly why
    //    the relation went unwritten: this tree grows by rules, and `between` is the one
    //    cross-document reference no rule MAY check.
    let refs =
        sqlx::query_file!("assets/sql/queries/observations/10b-elimination-references.sql")
            .fetch_all(&pool)
            .await?;
    let lands = refs.iter().filter(|r| r.resolves).count();
    println!(
        "\n11b. what each elimination POINTS AT: {} of {} land on a layer this corpus holds",
        lands,
        refs.len()
    );
    for r in &refs {
        println!(
            "   {:<26} {:<15} {:<10} {} / {:<18} {}",
            r.composition, r.composed_layer, r.quantity, r.party, r.layer, r.lands_on
        );
    }
    println!("   ⛔ `(outside this corpus)` is not a defect either, and for a sharper reason than");
    println!("      `(none named)` above: the schema REFUSES a keyref that would force the subset,");
    println!("      because a group eliminating against a member that files nothing is ordinary.");

    // The greatest element of the intersection of the parts' divisor sets, each quantum converted
    // into the composed layer's unit first. Where a factor is unmeasured, or the converted quanta
    // still sit in different units, the row carries the typed absence rather than a number the
    // fold would happily have produced. Proven in `src/proofs/README.md`, entry `composed_quantum`.
    let quanta = sqlx::query_file!("assets/sql/queries/observations/11-composed-quantum.sql")
        .fetch_all(&pool)
        .await?;
    let unanswerable = quanta.iter().filter(|q| q.quantum.starts_with('(')).count();
    println!(
        "\n12. does a fused supply still arrive in whole units? {} of {} have no common quantum",
        unanswerable,
        quanta.len()
    );
    for q in &quanta {
        println!(
            "   {:<26} {:<22} {} part(s)  {:<20} {}",
            q.composition, q.composed_layer, q.parts, q.unit, q.quantum
        );
    }
    println!("   `(unmeasured)` is a conversion nobody sized. `(notApplicable)` is the question being");
    println!("   malformed, not unanswered: two quanta in different units have no common divisor.");

    // Two ways to the same number, and the controls are what make the difference mean anything.
    // A composed layer whose remainder walk passes no factor with width agrees exactly; only a
    // spread factor can separate the two figures, because only then is one factor multiplying
    // both the nameplate and the demand that get differenced. `algebra/composed_remainder` holds
    // this on every run; here it is asserted row by row, and both kinds of row must occur.
    let rem = sqlx::query_file!("assets/sql/queries/observations/13-composed-remainder.sql")
        .fetch_all(&pool)
        .await?;
    let apart = rem.iter().filter(|r| !r.agrees).count();
    println!(
        "\n13. the composed remainder, pivoted through the parts against differenced totals: \
         {} of {} disagree",
        apart,
        rem.len()
    );
    for r in &rem {
        println!(
            "   {} {:<26} {:<22} {} part(s)  pivot [{}, {}, {}]  differenced [{}, {}, {}] {}",
            if r.agrees { "  " } else { "≠ " },
            r.composition, r.composed_layer, r.parts,
            r.pivoted_low, r.pivoted_mode, r.pivoted_high,
            r.derived_low, r.derived_mode, r.derived_high,
            r.unit
        );
    }
    for r in &rem {
        assert_eq!(
            r.agrees, !r.spread,
            "{}/{}: the two figures {} while a factor on the walk {} width",
            r.composition,
            r.composed_layer,
            if r.agrees { "agree" } else { "differ" },
            if r.spread { "has" } else { "has no" }
        );
    }
    assert!(
        apart > 0 && apart < rem.len(),
        "{apart} of {} composed layers disagree. Without both kinds of row there is no control \
         and no case, and the comparison demonstrates nothing.",
        rem.len()
    );
    println!("   The agreeing rows are the control: no factor on their walk has width, so nothing");
    println!("   could separate the two figures. Only a spread factor can, and it does.");

    // ⭐⭐⭐ THE ONE OBSERVATION THAT IS ABOUT THE SCHEMA RATHER THAN THE BUSINESS. Every other
    //    section here asks what the filings say; this asks which STATES they have ever reached.
    //    `AbsenceReason` is four members, so the answer per question is a four-bit word, and
    //    the split between the words carrying `n` and the words not carrying it is the
    //    `pm:Absence` / `pm:ClaimAbsence` boundary, printed from the data instead of read off
    //    the grammar. A question on the wrong side of it is a defect, and one was: `StatedFit`
    //    admits `none` in the grammar while `remainder sign` never once takes it, and its own
    //    annotation refuses the state in prose.
    let masks = sqlx::query_file!("assets/sql/queries/observations/12-state-masks.sql")
        .fetch_all(&pool)
        .await?;
    let reaching = masks.iter().filter(|m| m.mask.starts_with('n')).count();
    println!(
        "
14. which of the four absence reasons has each question ever taken? {} of {} reach `none`",
        reaching,
        masks.len()
    );
    for m in &masks {
        println!(
            "   {:<38} {}   {:>4} filed{}",
            m.question,
            m.mask,
            m.filings,
            if m.as_none > 0 { format!(", {} as `none`", m.as_none) } else { String::new() }
        );
    }
    println!("   ⭐ Read the column, not the rows. A bit a type ADMITS and no document has ever");
    println!("      set is either a state nobody needs or a state the type should not have, and");
    println!("      both deserve a sentence. Four passes of reading annotations missed the one");
    println!("      this found.");

    // ⭐⭐⭐ THE ONLY SECTION HERE THAT MEASURES WORK RATHER THAN CONTENT. checks/jagged_layer
    //    reports that a fusion's parts overlap; this asks how much supply is in the total
    //    twice, and only where the composer filed no elimination at all. A filing that found
    //    its own double counting and sized it never appears, however large the overlap was,
    //    because that is the party who can actually see it doing the job.
    let jagged = sqlx::query_file!("assets/sql/queries/observations/14-jagged-layers.sql")
        .fetch_all(&pool)
        .await?;
    println!(
        "\n15. overlap nobody admitted, and what somebody downstream has to zero out: {}",
        jagged.len()
    );
    for j in &jagged {
        println!(
            "   {}/{} counts {} twice, through {} and {}  [{}, {}] {}",
            j.filing, j.layer, j.doubled, j.via, j.also_via,
            j.twice_demand.map(|d| d.to_string()).unwrap_or_else(|| "?".into()),
            j.twice_nameplate.map(|n| n.to_string()).unwrap_or_else(|| "?".into()),
            j.unit
        );
    }
    if jagged.is_empty() {
        println!("   ⭐ None. Every fusion in this corpus draws each part once, so nobody");
        println!("      downstream is correcting an overlap a filer could have wrapped.");
    }

    // ⭐⭐⭐ THE MEASUREMENT THAT EXPLAINS THE DIAGRAM. The relations a notation would have drawn
    //    as arrows reach a handful of layers; the magnitudes reach nearly all of them. So the
    //    incidence side of this model is sparse and the magnitude side is total, and BPMN can
    //    carry only the first. A reader who finds an emitted diagram thin has read a faithful
    //    rendering of the part a notation can hold.
    let cover = sqlx::query_file!("assets/sql/queries/observations/15-rank.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n16. what the layer dimension carries, incidence against magnitude");
    for c in &cover {
        println!("   {:<8} {:<12} reaches {:>3} of {}", c.kind, c.relation, c.reaches, c.of);
    }
    let inc: i64 = cover.iter().filter(|c| c.kind == "incidence").map(|c| c.reaches).max().unwrap_or(0);
    let mag: i64 = cover.iter().filter(|c| c.kind == "magnitude").map(|c| c.reaches).min().unwrap_or(0);
    assert!(
        inc < mag,
        "the incidence reaches as far as the magnitudes, so the claim that a notation carries \
         only the sparse half has lost its subject and this section demonstrates nothing"
    );
    println!("   ⭐ `diagrams/domain_objects.sqlc` says which tables render as a BPMN element and");
    println!("      which are refused with a typed reason; this is how much each of them holds.");
    println!("      The largest tables here have no element at all.");

    // ⭐⭐⭐ THE ORDINAL RANK, WHICH IS WHAT WELL-FOUNDEDNESS GIVES YOU. `rank(x) = sup{rank(y)+1}`
    //    exists exactly when nothing expands to itself, so a cycle is the case where there is no
    //    order to evaluate in. This is that order, and it is a WINDOW over a closure that already
    //    exists rather than a second walk.
    let order = sqlx::query_file!("assets/sql/rank/evaluation_order.sql").fetch_all(&pool).await?;
    let mut tiers: std::collections::BTreeMap<i32, usize> = std::collections::BTreeMap::new();
    for o in &order {
        *tiers.entry(o.rank.unwrap_or(0) as i32).or_default() += 1;
    }
    println!("\n17. the order a fusion may be evaluated in, by ordinal rank");
    for (r, n) in &tiers {
        println!("   rank {r}   {n:>3} layers");
    }
    println!("   ⛔ Rank is the MAXIMUM depth over all paths, and `descent`'s `depth` is per path.");
    println!("      They agree on this corpus by luck; a jagged partition separates them.");

    // ⭐⭐⭐ THE PARAMETER THE GRAPHS ACTUALLY DIFFER ON. `rank = n - c`, cycle space `= m - n + c`.
    //    A graph with cycles has no ORDINAL rank and always has a MATRIX rank.
    //
    // ⛔ AND SAY WHICH CYCLE, BECAUSE THE TWO SENSES DO NOT COINCIDE. `m - n + c` counts UNDIRECTED
    //    cycles, so a zero says FOREST, which is strictly stronger than well-founded: a diamond is
    //    four edges over four nodes in one component, cycle space 1, and nothing in it descends
    //    forever. So the layer graph's 0 measures MORE than its well-foundedness, and what holds it
    //    there is `checks/jagged_layer` rather than an identity. The unit graph's is 1, and that is
    //    the subspace `checks/conversion_cycle_does_not_close` is really testing.
    let cyc = sqlx::query_file!("assets/sql/rank/cycle_space.sql").fetch_all(&pool).await?;
    println!("\n19. the graphs this model composes, as incidence matrices");
    for c in &cyc {
        println!("   {:<8} n {:>3}  m {:>3}  components {:>3}   rank {:>3}   cycle space {}",
                 c.graph.as_deref().unwrap_or("?"), c.n_nodes.unwrap_or(0), c.m_edges.unwrap_or(0),
                 c.c_components.unwrap_or(0), c.rank_of_incidence.unwrap_or(0),
                 c.cycle_space_dim.unwrap_or(0));
    }
    println!("   ⭐ A ZERO cycle space says the graph is a FOREST, which is stronger than");
    println!("      well-founded: a diamond descends nowhere forever and still carries a cycle");
    println!("      here. So the layer graph's zero is `checks/jagged_layer` holding it, and the");
    println!("      ordinal rank above is what a forest gives you free. The unit graph's is not");
    println!("      zero, and its rule is that the weights on it vanish: a potential exists.");

    // ⭐⭐ AND THE OTHER RANK, IN THE OTHER ALGEBRA. Read composition as the map `F Phi - E` and
    //    two layers on a loop have linearly dependent rows in it: ordinal rank stops existing and
    //    matrix rank falls at the same moment. `pm:Layer` calls the pair one layer.
    //
    // ⛔ `F Phi - E` IS THE DIAGNOSTIC AND NOT THE ARITHMETIC ANY FILING STATES HERE. An
    //    elimination's quantity is a `pm:StatedEliminatedQuantity`, which admits a claim, a typed
    //    absence OR a derivation, so a computed `e` is a document the schema allows and
    //    `pm.elimination.derivation` is the column that holds it. A FIXTURE REACHES THAT ARM and no
    //    corpus document does, so on every document about a business `e` is a figure somebody wrote
    //    down, which is why it is a magnitude `checks/fusion_sum_disagrees` compares against rather
    //    than a term a rule solves for.
    //
    // ⚠️ AND REACHING THE ARM IS NOT COMPUTING IT. Nothing here derives the figure the identity
    //    names, so a derived elimination SUSPENDS its quantity's sum under that name rather than
    //    sizing it: `eliminations/unsized.sqlc` is where it is lifted. The linear map is reachable,
    //    the grammar has been reached, and the computation behind it is not wired in. Count the
    //    column rather than trusting this comment:
    //    `SELECT count(*) FROM pm.elimination WHERE derivation IS NOT NULL`.
    //
    // ⭐⭐⭐ AND WHAT MAKES THE DIAGNOSTIC LEGITIMATE AT ANY DEPTH IS THAT A PATH OF CONVERSIONS IS
    //    ONE CONVERSION. A factor is strictly positive, so it cannot change its operand's sign, so
    //    the corner the operand takes is the same at every level and a chain of factors collapses
    //    into their product. That is what lets `composition/settled_remainders.sqlc` multiply the
    //    path's factors in and read one row per settled node instead of recursing, and it is why
    //    depth costs the rank nothing: nesting adds witnesses, never arithmetic. Proof:
    //    `src/proofs/README.md`, entry `conversion_collapses`.
    let comoving = sqlx::query_file!("assets/sql/rank/co_moving_layers.sql").fetch_all(&pool).await?;
    println!("\n18. layers whose remainders must move together, the fourth falsifier computed: {}",
             comoving.len());
    if comoving.is_empty() {
        println!("   ⭐ None. Every layer in this corpus can be perturbed without moving another");
        println!("      through the composition, so no filed pair fails `pm:Layer`'s own test.");
    }

    // ⭐⭐⭐ AND THE SAME MEASUREMENT TURNED ON THE THING DOING THE CHECKING. Branch one of
    //    `reports/integrity.sqlc` takes a roster away from a population, and every check joins the
    //    roster so that a rule examining nothing still emits a row carrying its NAME. Where that
    //    row is the only one, the difference has the roster on both ends and cannot report.
    //
    // ⛔ SO THE SUBJECTS SHORT HERE ARE EXACTLY THE RULES `reports/coverage.sqlc` CALLS VACUOUS,
    //    and the two tables move in opposite directions on one event: the day a filing sizes a
    //    buffer and attributes a share to it, coverage improves and this shortfall goes to zero.
    //
    // ⚠️ `ok` IS TWO DIFFERENT FACTS. `diagrams` earns it from a population the contract did not
    //    write, `information_schema`; `arithmetic` and `algebra` are built exactly like `rules`
    //    and are merely populated everywhere on this corpus.
    let guards = sqlx::query_file!("assets/sql/queries/observations/16-guard-reach.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n20. what each contract's own guard can be about");
    for g in &guards {
        println!("   {:<11} {:>2} of {:>2} witnessed by the population, {:>2} by the roster alone   {}",
                 g.contract, g.witnessed, g.subjects, g.roster_only, g.verdict);
    }
    println!("   ⭐ `witnessed` is where the two sides of the difference are different rows.");
    println!("      The rest is the roster agreeing with itself, which is what tests/independence.rs");
    println!("      refuses to count as corroboration anywhere else. `diagrams/domain_objects.sqlc`");
    println!("      states the rule for the contract side; this is the side nothing states.");
    assert!(
        guards.iter().all(|g| g.subjects > 0),
        "a contract declares no subjects, so this measurement has no denominator and the \
         grades printed above are about nothing"
    );

    // ⭐⭐⭐ THE THIRD `pm:ForeignId`, AND A RELATION SHOWS ONLY WHAT THE INGEST KEEPS.
    //    `pm:Operation/foreignId` is the whole BPMN interface, and an ingest that drops it leaves
    //    the corpus filing a node id, the database holding none, and every relation that could
    //    show the crossing derived from a table that threw it away. The column is this section's
    //    only source, so the report exists exactly as far as the ingest carries the field.
    //
    // ⛔ REPORTED, NEVER ASSERTED, and for a sharper reason than `between`. A `between` MAY
    //    resolve and happens not to; this one CANNOT, because the document it names is not in
    //    the corpus and no authority publishes the list. There is no rule to write.
    let crossings =
        sqlx::query_file!("assets/sql/queries/observations/17-notation-references.sql")
            .fetch_all(&pool)
            .await?;
    let crossing = crossings.iter().filter(|c| c.crosses).count();
    println!(
        "\n21. what each operation POINTS AT in a process notation: {} of {} name a node",
        crossing,
        crossings.len()
    );
    for c in &crossings {
        println!("   {:<26} {:<34} {:<46} {}", c.filing, c.label,
                 if c.crosses { c.notation.as_str() } else { "(no position stated)" },
                 if c.crosses { c.node.as_str() } else { c.why_not.as_str() });
    }
    println!("   ⭐ The rows that name nothing are the argument, and each one now says WHICH");
    println!("      nothing: `none` is in no notation and somebody looked, `unmeasured` is a");
    println!("      notation exists and nobody located it, `notApplicable` is no notation at all.");
    println!("      Most filings declare no operation either, so this model does not need a process");
    println!("      notation. Where one exists the id is the join, and it costs that document");
    println!("      nothing: no field is added to it and no tool that reads it has to change.");
    assert!(
        crossings.iter().all(|c| c.crosses != (c.why_not.is_empty() == false)),
        "an operation both states a notation position and files a reason there is none, or does \
         neither. The DDL forbids both by CHECK, so this is the relation having lost an arm"
    );
    assert!(
        !crossings.is_empty(),
        "no operation in the corpus, so this report has no population and the crossing above \
         is a claim about nothing"
    );

    // ⭐⭐⭐ THE LAYER DIMENSION READ DOWN THE OTHER AXIS. `rank/incidence_reach.sqlc` counts, per
    //    RELATION, how much of the dimension it touches, so it says `49 of 51` and never which
    //    two. This is the transpose, where the subject is the layer and the shortfall has a name.
    //
    // ⛔⛔ AND THE FIRST MEASUREMENT TAKEN THIS WAY WAS WRONG, WHICH IS WORTH KEEPING. It said
    //    two layers were unreachable. Three rules were putting a claim ADDRESS in the contract's
    //    `layer` column, 324 distinct pairs naming no layer, so the join dropped them and the
    //    shortfall was an artifact of the key. With the subject declared `claim` and the claim's
    //    own layer reported, it is zero. A cover measured through a key that does not resolve
    //    measures the key.
    let cover = sqlx::query_file!("assets/sql/queries/observations/18-layer-reach.sql")
        .fetch_all(&pool)
        .await?;
    let thinnest = cover.first().map(|c| c.examined_by).unwrap_or(0);
    println!(
        "\n22. how many rules can say anything about each layer: {} layers, {} to {}",
        cover.len(),
        thinnest,
        cover.last().map(|c| c.examined_by).unwrap_or(0)
    );
    for c in cover.iter().take(4) {
        println!("   {:<26} {:<22} {:>2} rules, {} violated", c.filing, c.layer, c.examined_by, c.violated);
    }
    println!("   ⭐ The thin end is the finding and it is not a violation. A layer whose nameplate");
    println!("      is a typed absence has no row in the vectors most rules compose, so it is");
    println!("      filed correctly, validates, and is reachable by almost nothing. That is this");
    println!("      model's boundary measured from inside rather than argued in a paragraph.");
    assert!(
        cover.iter().all(|c| c.examined_by > 0),
        "a filed layer is reached by no rule at all, so nothing in this repository could ever \
         contradict what it says"
    );
    assert!(
        !cover.is_empty(),
        "no layer reached this measurement, so the range printed above is about nothing"
    );

    // ⭐⭐⭐ THE REPOSITORY'S CENTRAL CLAIM ABOUT ITSELF, AS A QUERY RATHER THAN A SENTENCE. A
    //    parent composing a child twice is ordinary and a fusion reaching a layer twice is a
    //    violation, and both are one name arriving twice under one fold. The comparison needs
    //    both halves in one relation: a claim whose two graphs live in a Rust `BTreeMap` and a
    //    SQL table is one a program can hold a single side of and never join.
    let dup = sqlx::query_file!("assets/sql/queries/observations/19-duplication.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n23. the same duplication in two graphs, and the opposite verdict");
    for d in &dup {
        println!("   {:<18} {:>3} of {:>4} edges   {}", d.graph, d.duplicated, d.edges, d.verdict);
    }
    println!("   ⛔ The COUNTS are not comparable and must not be compared: one graph is however");
    println!("      much SQL somebody wrote, the other is however many fusions a corpus files.");
    println!("      What is comparable is the verdict, and it is opposite on one column.");
    assert!(
        dup.len() == 2 && dup.iter().all(|d| d.edges > 0),
        "one of the two graphs has no edges, so this comparison is between a structure and \
         nothing and the opposite verdicts are about one thing"
    );

    // ⭐⭐ THE ONE WIDTH IN THIS MODEL THAT NARROWS WHAT IT TOUCHES. Every other term widens the
    //    figure it enters. An elimination subtracted bound by bound sends its own width the other
    //    way, because the low rises and the high falls together, so a composer LESS sure how much
    //    was double counted files a MORE precise composed figure. Neither reading is a defect and
    //    no rule is owed; what was missing was any way to count which filings are in which arm.
    let mono = sqlx::query_file!("assets/sql/queries/observations/20-elimination-monotonicity.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n24. what a wider elimination would do to the figure it comes off");
    for m in &mono {
        let w = m.width.map_or_else(|| "        ".to_string(), |w| format!("{w:>8}"));
        println!(
            "   {:<16} {:<10} width {w}   {}",
            m.composed_layer, m.quantity, m.what_a_wider_elimination_does
        );
        if m.width.is_some_and(|w| w > 0.0) {
            println!("   {:<28}    {}", "", m.what_the_bound_rests_on);
        }
    }
    println!("   ⛔ The crossed reading is reached only where bound by bound would leave the claim");
    println!("      disordered, so it is rare BY CONSTRUCTION. Its arm emptying would mean the");
    println!("      fixture that exercises it had stopped, not that the model had changed.");
    assert!(
        mono.iter().any(|m| m.isotone == Some(true)) && mono.iter().any(|m| m.isotone == Some(false)),
        "one arm of this classification is empty, so the column reports the corpus rather than \
         the two readings the arithmetic actually has"
    );
    // ⛔⛔ THE KEY IS CHECKED BY THE FIGURES AND COULD NOT BE CHECKED BY A COUNT. `claim_seq` is a
    //    document ordinal, so a join on it returns one claim per elimination whether or not it is
    //    the right claim: shifted by one it still returns a row for every elimination and almost
    //    none of the figures agree. So the claim's own three points ride along and are compared.
    let placed: Vec<_> = mono.iter().filter(|m| m.low.is_some()).collect();
    assert!(
        !placed.is_empty()
            && placed.iter().all(|m| m.claim_low == m.low
                && m.claim_high == m.high
                && m.claim_mode.is_some()),
        "an eliminated quantity's `claim_seq` points at a claim that is not the one stating it, so \
         every bound origin read through it is read off the wrong claim"
    );
    let width_bearing: Vec<_> = mono.iter().filter(|m| m.width.is_some_and(|w| w > 0.0)).collect();
    assert!(
        width_bearing.iter().any(|m| m.licensed == Some(true))
            && width_bearing.iter().any(|m| m.licensed == Some(false)),
        "every elimination with width answers the licence question the same way, so the column \
         reports this corpus rather than the two answers a filing may give"
    );

    // ⭐⭐⭐ AND THE CONVERSION'S OTHER BRANCH, WHICH NO FILING REACHES. A demand cannot be
    //    negative so it converts bound by bound; a remainder can, so it converts by corners. The
    //    corner rule changes a figure only where a factor has width AND the operand is negative at
    //    that bound, and the two populations here do not overlap. Both asserts below are the point:
    //    an empty intersection is a fact about the evidence only while both sides are sizeable.
    let slopes = sqlx::query_file!("assets/sql/queries/observations/21-conversion-slopes.sql")
        .fetch_all(&pool)
        .await?;
    let spread = slopes.iter().filter(|c| c.spread_factor).count();
    let negative = slopes.iter().filter(|c| c.operand_low.is_some_and(|v| v < 0.0)).count();
    let bites = slopes.iter().filter(|c| c.corner_rule_bites == Some(true)).count();
    println!("\n25. which corner of the factor each bound of a carried remainder took");
    println!("   {:>3} settled nodes carried up", slopes.len());
    println!("   {spread:>3} under a factor with width");
    println!("   {negative:>3} whose remainder is negative at its low, so that bound takes the factor's HIGH");
    println!("   {bites:>3} where taking corners gave a different figure from multiplying bound by bound");
    println!("   ⛔ Zero is not a reason to simplify the arithmetic. It says the two populations");
    println!("      above do not overlap in this corpus. A negative remainder is the interference");
    println!("      case the model exists to measure and a factor with width is ordinary; what is");
    println!("      empty is the intersection, and the identity is proved against a constructed");
    println!("      operand precisely because no filing reaches it.");
    assert!(
        spread > 0 && negative > 0,
        "one side of this intersection is empty, so `{bites} bites` is vacuous for a reason that \
         has nothing to do with the corner rule"
    );

    // ⭐⭐⭐ THE CONFORMANCE ROW THAT HAS NO RULE, GIVEN A MAGNITUDE AT LAST. A fusion adds its
    //    converted parts, so moving supply from one part to another at the rate below leaves the
    //    composed figure exactly where it was. That invisibility is not a side effect of the
    //    arithmetic, it IS the claim the fusion makes, and `asrt:Fusion` is explicit that no
    //    validator reaches the judgement behind it. What a validator CAN do is say how much is
    //    being asserted, so that the reader the schema invites to disagree has something to
    //    disagree with. Nothing measured this before.
    let offsets = sqlx::query_file!("assets/sql/queries/observations/22-declared-offsets.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n26. what each fusion declared it cannot see");
    for o in &offsets {
        match (o.determined, o.rate_mode) {
            (true, Some(rate)) => println!(
                "   {:<16} {} -> {}   1 : {rate:.4}",
                o.composed_layer, o.part_a, o.part_b
            ),
            _ => println!(
                "   {:<16} {} -> {}   {}",
                o.composed_layer,
                o.part_a,
                o.part_b,
                o.undetermined_because.as_deref().unwrap_or("undetermined")
            ),
        }
    }
    println!("   ⛔ One row per PAIR, which is not the dimension. A fusion of k parts licenses");
    println!("      C(k,2) pairs and k-1 independent offsets, and those agree only up to k = 2.");
    println!("      Every fusion filed here is binary, so the two totals match for a reason that");
    println!("      is a fact about this corpus. rank/composition_kernel is the dimension.");
    // ⛔ Both arms, because a rate column that is everywhere 1 reports that no fusion converts
    //    rather than that conversion leaves the offset at par, and an empty absence arm would
    //    mean the undetermined case is being asserted rather than exercised.
    assert!(
        offsets.iter().any(|o| o.determined && o.rate_mode.is_some_and(|r| (r - 1.0).abs() > 1e-9)),
        "every declared offset is at par, so this relation cannot distinguish a fusion that \
         converts from one whose parts already share a unit"
    );
    assert!(
        offsets.iter().any(|o| !o.determined),
        "no fusion leaves an offset undetermined, so the typed-absence arm is a claim about the \
         corpus that nothing here exercises"
    );

    println!("\nAll checks passed.");
    Ok(())
}
