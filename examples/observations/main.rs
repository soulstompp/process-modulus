// This program's header is `README.md` beside it, and there is one copy of it. GitHub renders a
// directory's README and no `//!` block, so a header kept only in the source cannot be read where
// the repository is published. `include_str!` makes the same file rustdoc's page, so the two
// renderings cannot disagree, and a missing header is a compile error rather than a blank row.
//
// Both languages are included, as in the schemas: an `xs:annotation` holds an `xml:lang="en"`
// block and an `xml:lang="pt"` block, and the generated Rust carries both in one doc comment.
// These two files are the same arrangement for a program, so the Portuguese page is rendered
// wherever the English one is, as `tests/translation.rs` requires.
#![doc = include_str!("README.md")]
#![doc = include_str!("../../pt-PT/examples/observations/README.md")]

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

// The tree walker is shared, so it is not a target: `examples/shared/` holds no `main.rs`, which
// is exactly how cargo decides what is an example, and `#[path]` is how a target reaches into it.
#[path = "../shared/tree/mod.rs"]
mod tree;

// The scan of the examples is shared for the same reason. `examples/compositions/main.rs` asks
// the same question of `examples/`, and two copies of one walk are how two answers start to
// differ.
#[path = "../shared/sources/mod.rs"]
mod sources;
use tree::{emitted, references, templates};

/// Documents that are parsed only by Rust tests and never reach the database, each with the
/// reason. Adding a name here is the whole decision: it excuses a document from every SQL query,
/// every check and every report at once, and this list is the only thing that says so.
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
    // point, or by an example naming its composed output. Each step of the walk in
    // assets/sqlc/README.md is a psql entry point, which the page runs.
    let examples = sources::all();
    let entry_points = ["ingest.sqlc", "rules.sqlc", "matrices.sqlc", "invariance.sqlc"];
    let walk = "queries/walk/";

    let mut unobserved: Vec<&str> = Vec::new();
    for (name, _) in &files {
        if composed.contains(name) || entry_points.contains(&name.as_str()) || name.starts_with(walk) {
            continue;
        }
        let emitted = format!("assets/sql/{}", name.replace(".sqlc", ".sql"));
        if !examples.contains(&emitted) {
            unobserved.push(name);
        }
    }
    unobserved.sort_unstable();

    // A template carrying an open `@slot` emits no .sql and is a shape rather than a query, so it
    // is reached through its fillers and never directly. The `composed` set above covers it: a
    // shape is always composed by whoever fills it.
    println!(
        "1. relations: {} templates, {} reached by something",
        files.len(),
        files.len() - unobserved.len()
    );
    for u in &unobserved {
        println!("   {u} is read by nothing");
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
        println!("   {u}.xml is reached by nothing at all");
    }

    // The assertion this example exists for. A relation nobody reads and a document nobody
    // parses are both invisible, and from the outside invisible reads exactly like absent.
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
    println!("   every one of those {no_witness} is a pm:processModulus. It is the only root");
    println!("      that carries no document-level provenance, so a stipulation and an");
    println!("      observation are the same shape to anything reading the tree.");
    // The standard a composition works under, a different question from the regime: the regime
    // is what the members reported under, and the citation is what governs combining them.
    let cited: Vec<_> = docs.iter().filter(|d| !d.under.is_empty()).collect();
    println!("   {} document(s) name the instrument they compose under:", cited.len());
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
    println!("   `week` and `semana` are two rows because two filers wrote two tokens.");

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
    // Printed, never asserted. When somebody sizes a capacity slack above zero, this table
    // changes and nothing fails, which is the difference between an observation and a rule.
    println!("   A sized zero is the tightest bound, not a missing one.");

    let fixtures = sqlx::query_file!("assets/sql/queries/observations/6-absences-in-the-fixtures.sql")
        .fetch_all(&pool)
        .await?;
    let total: i64 = fixtures.iter().map(|f| f.times).sum();
    println!(
        "\n7. the fixtures decline {} questions across {} kinds, on purpose, which is what a",
        total,
        fixtures.len()
    );
    println!("   stipulation is for. Not counted as evidence anywhere; rules.sql composes the");
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

    // The second assertion, about coverage rather than answers. Every remainder the arithmetic
    // can reach must appear in layers/remainder_scope.sqlc with some standing. `nobody bounded
    // the set` is an honest standing and fails nothing; a remainder that never had the question
    // put to it is the failure.
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
    println!("   Not violations. A filing is not the system, and one document's observation");
    println!("      is a view of another rather than an accusation against it.");

    // The union of the two search relations, which neither half can answer: how often does
    // anybody look at all? That is a fact about the practice rather than about either mechanism,
    // so this section reads epistemics/searches.sqlc whole.
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

    // The evidence for an elimination. `asrt:Elimination/between` repeats, and no rule reads it,
    // so no rule would ever ask for a column, a table or an ingest for it: a rule reads what it
    // needs, and a field nothing reads is under no pressure to exist. What keeps it is asking
    // whether a document can be written back out from what is stored, and this section reads it.
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
    println!("   `(none named)` is not a defect. `between` is minOccurs=0, and a composer");
    println!("      eliminating against a member that files nothing has nothing to name.");

    // ------------------------------------------------------------------
    // The corpus directory against what ingest loaded, which no relation can ask. Every other
    // section is derived from what loaded, so it can report a document that arrived and never one
    // that is on disk and did not arrive: an unloaded file leaves no row to read. So which
    // documents exist, and why any of them does not load, is declared in
    // `scope/documents_on_disk.sqlc`, as `diagrams/notation.sqlc` declares its population one
    // stage earlier, and checked here against the directory.
    //
    // The check runs both ways, on purpose: a row saying `loaded` whose filing is absent is an
    // ingest that broke, and a row saying `not loaded` whose filing is present is the roster gone
    // stale.
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
        println!("   {:<32} [{}] {}", d.document.as_deref().unwrap_or("?"),
                 d.kind.as_deref().unwrap_or("?"),
                 d.not_loaded_because.as_deref().unwrap_or(""));
    }
    assert!(wrong.is_empty(), "the corpus roster disagrees with the database: {wrong:?}");
    println!("   Document kinds the schema admits and ingest does not read. The `filing.kind`");
    println!("      CHECK holds every kind, so the domain closes where the schema closes; this is");
    println!("      the same boundary, in a form a program can fail on.");

    // The same rows, read as what the document points at rather than as evidence. §11 reads
    // `between` as what an elimination is about; this reads it as a reference into another
    // document, beside the part's, so a list of what this model reaches in other documents is
    // whole.
    //
    // Reported, never asserted. A dangling part is a violation, because the fusion sum needs it;
    // a dangling `between` is ordinary, and the schema says so. `between` is the one reference
    // into another document that no rule may check.
    let refs =
        sqlx::query_file!("assets/sql/queries/observations/10b-elimination-references.sql")
            .fetch_all(&pool)
            .await?;
    let lands = refs.iter().filter(|r| r.resolves).count();
    println!(
        "\n11b. what each elimination points at: {} of {} land on a layer this corpus holds",
        lands,
        refs.len()
    );
    for r in &refs {
        println!(
            "   {:<26} {:<15} {:<10} {} / {:<18} {}",
            r.composition, r.composed_layer, r.quantity, r.party, r.layer, r.lands_on
        );
    }
    println!("   `(outside this corpus)` is not a defect either, and for a sharper reason than");
    println!("      `(none named)` above: the schema refuses a keyref forcing the subset,");
    println!("      because a group eliminating against a member that files nothing is ordinary.");

    // The largest unit that every part's quantum is a whole number of, each quantum converted
    // into the composed layer's unit first. Where a factor is unmeasured, or the converted quanta
    // still sit in different units, the row carries the typed absence rather than a number the
    // arithmetic would otherwise produce.
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

    // The one observation about the schema rather than the business. Every other section asks
    // what the filings say; this asks which states they have taken. `AbsenceReason` has three
    // members, so the answer per question is a three-letter word, and the split between the
    // words carrying `n` and the words without it is the `pm:Absence` / `pm:ClaimAbsence`
    // boundary, printed from the data instead of read off the schema. A question on the wrong
    // side of it is a defect.
    let masks = sqlx::query_file!("assets/sql/queries/observations/12-state-masks.sql")
        .fetch_all(&pool)
        .await?;
    let reaching = masks.iter().filter(|m| m.mask.starts_with('n')).count();
    println!(
        "
14. which of the three absence reasons has each question taken? {} of {} reach `none`",
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
    println!("   Read the column, not the rows. A reason a type admits and no document has");
    println!("      taken is either a state nobody needs or a state the type should not have,");
    println!("      and both deserve a sentence.");
    println!("      Either way it is a question for a person to look at, not a failure.");

    // The one section that measures work rather than content. checks/jagged_layer reports that a
    // fusion's parts overlap; this asks how much supply is in the total twice, and only where the
    // composer filed no elimination at all. A filing that found its own double counting and sized
    // it never appears, however large the overlap, because the party who can see it is doing the
    // job.
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
        println!("   None. Every fusion in this corpus draws each part once, so nobody");
        println!("      downstream is correcting an overlap a filer could have wrapped.");
    }

    // The measurement that explains the diagram. The relations a notation would draw as arrows,
    // the links between layers, reach a handful of layers; the figures reach nearly all of them.
    // The links are sparse and the figures cover everything, and BPMN can carry only the links.
    // A reader who finds a diagram thin has read a faithful drawing of the part a notation can
    // hold.
    let cover = sqlx::query_file!("assets/sql/queries/observations/15-rank.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n16. what the layer dimension carries, links against figures");
    for c in &cover {
        println!("   {:<8} {:<12} reaches {:>3} of {}", c.kind, c.relation, c.reaches, c.of);
    }
    let inc: i64 = cover.iter().filter(|c| c.kind == "incidence").map(|c| c.reaches).max().unwrap_or(0);
    let mag: i64 = cover.iter().filter(|c| c.kind == "magnitude").map(|c| c.reaches).min().unwrap_or(0);
    assert!(
        inc < mag,
        "the links reach as far as the figures, so the claim that a notation carries \
         only the sparse half has lost its subject and this section demonstrates nothing"
    );
    println!("   `diagrams/domain_objects.sqlc` says which tables render as a BPMN element and");
    println!("      which are refused with a typed reason; this is how much each of them holds.");
    println!("      The largest tables here have no element at all.");

    // The order a fusion may be evaluated in. Each layer comes after every layer it is composed
    // from, which is possible only when nothing is composed from itself: a loop leaves no order
    // to evaluate in. The order is a window over a closure that already exists, not a second walk.
    let order = sqlx::query_file!("assets/sql/rank/evaluation_order.sql").fetch_all(&pool).await?;
    let mut tiers: std::collections::BTreeMap<i32, usize> = std::collections::BTreeMap::new();
    for o in &order {
        *tiers.entry(o.rank.unwrap_or(0) as i32).or_default() += 1;
    }
    println!("\n17. the order a fusion may be evaluated in, by rank");
    for (r, n) in &tiers {
        println!("   rank {r}   {n:>3} layers");
    }
    println!("   The rank is the deepest over all paths, and `descent`'s `depth` is per path.");
    println!("      They agree on this corpus by luck; a jagged partition separates them.");

    // What the graphs differ on. For each graph the query counts its nodes, its edges, its
    // separate pieces, and the loops it has when the direction of its edges is ignored.
    //
    // A loop counted that way is not one a fusion can descend forever: a diamond, two layers
    // composed from one part and then into one total, is a loop here and still has an order. So
    // no such loops in the layer graph says more than that it has an order, and what keeps them
    // out is `checks/jagged_layer`. The loops in the unit graph are what
    // `checks/conversion_cycle_does_not_close` tests.
    let cyc = sqlx::query_file!("assets/sql/rank/cycle_space.sql").fetch_all(&pool).await?;
    println!("\n19. the graphs this model composes, counted");
    for c in &cyc {
        println!("   {:<8} nodes {:>3}  edges {:>3}  pieces {:>3}   tree edges {:>3}   loops {}",
                 c.graph.as_deref().unwrap_or("?"), c.n_nodes.unwrap_or(0), c.m_edges.unwrap_or(0),
                 c.c_components.unwrap_or(0), c.rank_of_incidence.unwrap_or(0),
                 c.cycle_space_dim.unwrap_or(0));
    }
    println!("   No loops, counted with direction ignored, says more than that the graph has");
    println!("      an order: a diamond descends nowhere for ever and still counts as a loop.");
    println!("      So the layer graph's zero is `checks/jagged_layer` holding it, and the rank");
    println!("      above comes free with it. The unit graph has loops, and its rule is that");
    println!("      converting all the way round one returns what it started with.");

    // Layers whose remainders must move together. A composition converts each part by its factor
    // and takes the eliminations off; two layers on a loop of that composition cannot change one
    // without the other, and `pm:Layer` calls such a pair one layer.
    //
    // That composed arithmetic is a check, not something a filing states here. An elimination's
    // quantity is a `pm:StatedEliminatedQuantity`, which admits a claim, a typed absence or a
    // derivation, so a computed elimination is a document the schema allows, and
    // `pm.elimination.derivation` is the column that holds it. A fixture reaches that arm and no
    // corpus document does, so on every document about a business the elimination is a figure
    // somebody wrote down, which is why `checks/fusion_sum_disagrees` compares against it rather
    // than solving for it.
    //
    // Reaching the arm is not computing it. Nothing here works out the figure the identity names,
    // so a derived elimination suspends its quantity's sum under that name rather than sizing it;
    // `eliminations/unsized.sqlc` is where it is lifted. Count the column rather than trust this
    // comment: `SELECT count(*) FROM pm.elimination WHERE derivation IS NOT NULL`.
    //
    // A path of conversions is one conversion: `composition/settled_remainders.sqlc` multiplies
    // the path's factors together and reads one row per settled node instead of recursing, so
    // nesting adds witnesses, never arithmetic.
    let comoving = sqlx::query_file!("assets/sql/rank/co_moving_layers.sql").fetch_all(&pool).await?;
    println!("\n18. layers whose remainders must move together: {}",
             comoving.len());
    if comoving.is_empty() {
        println!("   None. Every layer in this corpus can be changed without moving another");
        println!("      through the composition, so no filed pair fails `pm:Layer`'s own test.");
    }

    // The same measurement turned on the checks themselves. `reports/integrity.sqlc` compares
    // each roster with its population, and every check joins the roster so that a rule examining
    // nothing still emits a row carrying its name. Where that row is the only one, both sides of
    // the comparison come from the roster, and it cannot report.
    //
    // So the subjects short here are the rules `reports/coverage.sqlc` calls vacuous, and the two
    // tables move in opposite directions on one event: when a filing sizes a buffer and
    // attributes a share to it, coverage improves and this shortfall shrinks.
    //
    // `ok` is two different facts. `diagrams` earns it from a population the contract did not
    // write, `information_schema`; `arithmetic` and `algebra` are built like `rules` and are
    // simply populated everywhere in this corpus.
    let guards = sqlx::query_file!("assets/sql/queries/observations/16-guard-reach.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n20. what each contract's own guard can be about");
    for g in &guards {
        println!("   {:<11} {:>2} of {:>2} witnessed by the population, {:>2} by the roster alone   {}",
                 g.contract, g.witnessed, g.subjects, g.roster_only, g.verdict);
    }
    println!("   `witnessed` is where the two sides of the difference are different rows.");
    println!("      The rest is the roster agreeing with itself, which is what tests/independence.rs");
    println!("      refuses to count as corroboration anywhere else. `diagrams/domain_objects.sqlc`");
    println!("      states the rule for the contract side; this is the side nothing states.");
    assert!(
        guards.iter().all(|g| g.subjects > 0),
        "a contract declares no subjects, so this measurement has no denominator and the \
         grades printed above are about nothing"
    );

    // The operation's reference, and a relation shows only what the ingest keeps.
    // `pm:Operation/foreignId` is the whole interface to BPMN, and an ingest that dropped it would
    // leave the corpus filing a node id, the database holding none, and every relation that could
    // show the crossing derived from a table that threw it away. The column is this section's only
    // source, so the report goes exactly as far as the ingest carries the field.
    //
    // Reported, never asserted, and for a sharper reason than `between`. A `between` may resolve;
    // this one cannot, because the document it names is not in the corpus and no authority
    // publishes the list. There is no rule to write.
    let crossings =
        sqlx::query_file!("assets/sql/queries/observations/17-notation-references.sql")
            .fetch_all(&pool)
            .await?;
    let crossing = crossings.iter().filter(|c| c.crosses).count();
    println!(
        "\n21. what each operation points at in a process notation: {} of {} name a node",
        crossing,
        crossings.len()
    );
    for c in &crossings {
        println!("   {:<26} {:<34} {:<46} {}", c.filing, c.label,
                 if c.crosses { c.notation.as_str() } else { "(no position stated)" },
                 if c.crosses { c.node.as_str() } else { c.why_not.as_str() });
    }
    println!("   The rows that name nothing are the argument, and each one says which");
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

    // The layer dimension read the other way. `rank/incidence_reach.sqlc` counts, per relation,
    // how much of the dimension it touches, so it says how many layers and never which. Here the
    // subject is the layer, so a shortfall has a name.
    //
    // A count of the rules that reach a layer is only as good as the key it joins on: a key that
    // does not resolve to a layer drops rows, and the count then measures the key. So a rule whose
    // subject is a claim is counted against the claim's own layer.
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
    println!("   The thin end is the finding and it is not a violation. A layer whose nameplate");
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

    // The repository's central claim about itself, as a query. A parent composing a child twice
    // is ordinary, and a fusion reaching a layer twice is a violation; both are one name arriving
    // twice under one total. The comparison needs both halves in one relation, so both graphs are
    // tables: one held in a Rust map and the other in SQL could never be joined.
    let dup = sqlx::query_file!("assets/sql/queries/observations/19-duplication.sql")
        .fetch_all(&pool)
        .await?;
    println!("\n23. the same duplication in two graphs, and the opposite verdict");
    for d in &dup {
        println!("   {:<18} {:>3} of {:>4} edges   {}", d.graph, d.duplicated, d.edges, d.verdict);
    }
    println!("   The counts are not comparable and must not be compared: one graph is however");
    println!("      much SQL somebody wrote, the other is however many fusions a corpus files.");
    println!("      What is comparable is the verdict, and it is opposite on one column.");
    assert!(
        dup.len() == 2 && dup.iter().all(|d| d.edges > 0),
        "one of the two graphs has no edges, so this comparison is between a structure and \
         nothing and the opposite verdicts are about one thing"
    );

    // The one width in this model that narrows what it touches. Every other term widens the
    // figure it enters. An elimination taken off bound by bound sends its width the other way: its
    // low comes off the low and its high off the high, so a composer less sure how much was double
    // counted files a more precise composed figure. Neither reading is a defect and no rule is
    // owed; this section counts which filings are in which arm.
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
    println!("   The crossed reading is reached only where bound by bound would leave the claim");
    println!("      disordered, so it is rare by construction. Its arm emptying would mean the");
    println!("      fixture that exercises it had stopped, not that the model had changed.");
    assert!(
        mono.iter().any(|m| m.isotone == Some(true)) && mono.iter().any(|m| m.isotone == Some(false)),
        "one arm of this classification is empty, so the column reports the corpus rather than \
         the two readings the arithmetic actually has"
    );
    // The key is checked by the figures, because a count could not check it. `claim_seq` is a
    // position in the document, so a join on it returns one claim per elimination whether or not
    // it is the right claim: shifted by one, it still returns a row for every elimination, and
    // almost none of the figures agree. So the claim's own three values ride along and are
    // compared.
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

    // The conversion's other branch. A demand cannot be negative, so it converts bound by bound;
    // a remainder can, so it converts by corners. Taking corners changes a figure only where a
    // factor has width and the operand is negative at that bound, and the count printed below is
    // how often the two meet. The assertion is what makes that count mean something: an empty
    // overlap is a fact about the evidence only while both sides have members.
    let slopes = sqlx::query_file!("assets/sql/queries/observations/21-conversion-slopes.sql")
        .fetch_all(&pool)
        .await?;
    let spread = slopes.iter().filter(|c| c.spread_factor).count();
    let negative = slopes.iter().filter(|c| c.operand_low.is_some_and(|v| v < 0.0)).count();
    let bites = slopes.iter().filter(|c| c.corner_rule_bites == Some(true)).count();
    println!("\n25. which corner of the factor each bound of a carried remainder took");
    println!("   {:>3} settled nodes carried up", slopes.len());
    println!("   {spread:>3} under a factor with width");
    println!("   {negative:>3} whose remainder is negative at its low, so that bound takes the factor's high");
    println!("   {bites:>3} where taking corners gave a different figure from multiplying bound by bound");
    println!("   Zero is not a reason to simplify the arithmetic. It says the two populations");
    println!("      above do not overlap in this corpus. A negative remainder is the interference");
    println!("      case the model exists to measure and a factor with width is ordinary; what is");
    println!("      empty is the overlap, and no filing in this corpus reaches it, so the corner");
    println!("      rule is kept for the filing that will.");
    assert!(
        spread > 0 && negative > 0,
        "one side of this intersection is empty, so `{bites} bites` is vacuous for a reason that \
         has nothing to do with the corner rule"
    );

    // The conformance row that has no rule, given a magnitude. A fusion adds its converted parts,
    // so moving supply from one part to another at the rate below leaves the composed figure
    // exactly where it was. That invisibility is the claim the fusion makes, not a side effect of
    // the arithmetic, and `asrt:Fusion` says no validator reaches the judgement behind it. What a
    // query can do is say how much is being asserted, so the reader the schema invites to
    // disagree has something to disagree with.
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
    println!("   One row per pair of parts, which is not the number of independent offsets. A");
    println!("      fusion of two parts has one of each; past two parts, the pairs outnumber the");
    println!("      offsets. Every fusion filed here has two parts, so the two totals match for a");
    println!("      reason that is a fact about this corpus. rank/composition_kernel counts them.");
    // Both arms, because a rate column that is 1 everywhere reports that no fusion converts
    // rather than that conversion leaves the offset at par, and an empty absence arm would mean
    // the undetermined case is asserted rather than exercised.
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
