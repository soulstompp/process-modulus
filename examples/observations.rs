//! What the corpus actually says, and whether anything is looking.
//!
//! [`examples/matrices.rs`] proves the arithmetic agrees with itself. [`examples/readiness.rs`]
//! asks whether it may be performed. This one asks the corpus questions and prints the answers
//!, because a relation whose product is knowledge rather than a verdict had nowhere to land,
//! and so either never got written or got written and read by nobody.
//!
//! ⭐⭐⭐ EVERY NUMBER A COMMENT IN THIS REPOSITORY QUOTES SHOULD BE PRINTED BY A PROGRAM. Four
//! were not, and all four had drifted: the capacity-slack coverage in two places, the template
//! count, and the refusal count in `epistemics/standing.sqlc`'s own header. None of the authors
//! was wrong when they wrote it. The corpus moved and the sentences did not.
//!
//! ⛔⛔ THE TEETH ARE ON THE UNASKED QUESTION, NEVER ON THE ANSWER. Two assertions:
//! that no relation and no document is reached by nothing, and that every remainder has had
//! the closure question put to it. Neither judges a filing. `unbounded` is the honest state
//! for a document written to argue about three layers, and a spillover is a REFERRAL, a
//! filing is not the system, and a second document's observation is a projection onto this one
//! rather than an accusation against it.
//!
//! Run it with a loaded database:
//!
//! ```text
//! psql -d process_modulus_proof -f assets/ddl/schema.ddl -f assets/sql/ingest.sql
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!   cargo run --example observations
//! ```

use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};

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

/// Every `.sqlc` under `assets/sqlc`, named the way a `:compose()` directive names it.
fn templates(dir: &Path, root: &Path, out: &mut Vec<(String, String)>) {
    for e in fs::read_dir(dir).expect("assets/sqlc is readable").flatten() {
        let p = e.path();
        if p.is_dir() {
            templates(&p, root, out);
        } else if p.extension().is_some_and(|x| x == "sqlc") {
            let name = p
                .strip_prefix(root)
                .expect("under assets/sqlc")
                .to_string_lossy()
                .into_owned();
            out.push((name, fs::read_to_string(&p).expect("readable")));
        }
    }
}

/// The `.sqlc` paths a template names, from either directive. Three forms occur:
/// `:compose(path)`, `:union(ALL a, b)`, and a slot fill, `:compose(shape, @scope = path)`.
/// ⛔ The third is the one worth being careful about: the filler is the only reference a
/// `scope/` relation ever gets, so a parser that stopped at the `@` would report every scope
/// as an orphan. A bare `@scope` inside a shape names no file and drops out on its own.
fn references(body: &str) -> Vec<String> {
    let mut out = Vec::new();
    for (open, close) in [(":compose(", ')'), (":union(", ')')] {
        let mut rest = body;
        while let Some(i) = rest.find(open) {
            rest = &rest[i + open.len()..];
            let Some(j) = rest.find(close) else { break };
            for token in rest[..j].split(',') {
                let t = token.trim().trim_start_matches("ALL").trim();
                let t = t.split_once('=').map_or(t, |(_, filler)| filler.trim());
                if t.ends_with(".sqlc") {
                    out.push(t.to_string());
                }
            }
            rest = &rest[j..];
        }
    }
    out
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example reports what the corpus says, and it cannot do \
         that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. Nothing unobserved: every relation, and every document.
    // ------------------------------------------------------------------
    let sqlc = Path::new("assets/sqlc");
    let mut files = Vec::new();
    templates(sqlc, sqlc, &mut files);

    let composed: BTreeSet<String> = files.iter().flat_map(|(_, b)| references(b)).collect();

    // A root is reached by no other template. It earns its place by being run: as a psql entry
    // point, or by an example naming its composed output.
    let examples: String = fs::read_dir("examples")
        .expect("examples/ is readable")
        .flatten()
        .map(|e| fs::read_to_string(e.path()).unwrap_or_default())
        .collect();
    let entry_points = ["ingest.sqlc", "rules.sqlc", "matrices.sqlc", "invariance.sqlc"];

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

    // ⭐⭐⭐ THE EVIDENCE FOR AN ELIMINATION, WHICH THIS DATABASE COULD NOT STORE UNTIL
    //    2026-09-06. `asrt:Elimination/between` is repeating and no rule read it, so it had no
    //    column, no table and no ingest, and eight of them were parsed out of the corpus and
    //    thrown away on every load. Nothing on the query side could find that: a rule reads what
    //    it needs, so a field nothing reads is under no pressure to exist. The question that
    //    finds it is "could I write this document back out from what I stored".
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

    // ⭐⭐⭐ THE SAME EIGHT ROWS AS A POINTER RATHER THAN AS EVIDENCE, WHICH IS THE DIFFERENCE
    //    THAT HID THEM. §11 above reads `between` as what an elimination is ABOUT; this reads it
    //    as what the document POINTS AT. The model has two `pm:ForeignId` references and only the
    //    part had a relation naming it as one, so enumerating what this model reaches in other
    //    documents returned half the answer for as long as nobody asked twice.
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

    // ⭐ The greatest element of the intersection of the parts' divisor sets, where the parts
    //   share a unit. Where they do not, divisibility is a relation on one ordered set and there
    //   is nothing to intersect, so the row reports `notApplicable` rather than a number the fold
    //   would happily have produced.
    let quanta = sqlx::query_file!("assets/sql/queries/observations/11-composed-quantum.sql")
        .fetch_all(&pool)
        .await?;
    let unanswerable = quanta.iter().filter(|q| q.unit == "(incommensurable)").count();
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
    println!("   ⛔ `(notApplicable)` is the question being malformed, not unanswered: two quanta");
    println!("      in different units have no common divisor to find.");

    // ⭐⭐⭐ THE ONE OBSERVATION THAT IS ABOUT THE SCHEMA RATHER THAN THE BUSINESS. Every other
    //    section here asks what the filings say; this asks which STATES they have ever reached.
    //    `AbsenceReason` is four members, so the answer per question is a four-bit word, and
    //    the split between the words carrying `n` and the words not carrying it is the
    //    `pm:Absence` / `pm:ClaimAbsence` boundary, printed from the data instead of read off
    //    the grammar. A question on the wrong side of it is a defect, and one was: `StatedFit`
    //    admitted `none` for revisions while `remainder sign` never once took it, and its own
    //    annotation had been refusing the state in prose the whole time.
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
    println!("   ⭐ Nine tables render as a BPMN element and fourteen do not; this is how much");
    println!("      each of them holds. The largest tables here have no element at all.");

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
    //    A graph with cycles has no ORDINAL rank and always has a MATRIX rank, and a well-founded
    //    relation is simply one whose cycle space is zero. The layer graph's comes out at 0,
    //    which is its well-foundedness measured rather than assumed; the unit graph's is 1, and
    //    that is the subspace `checks/conversion_cycle_does_not_close` is really testing.
    let cyc = sqlx::query_file!("assets/sql/rank/cycle_space.sql").fetch_all(&pool).await?;
    println!("\n19. the graphs this model composes, as incidence matrices");
    for c in &cyc {
        println!("   {:<8} n {:>3}  m {:>3}  components {:>3}   rank {:>3}   cycle space {}",
                 c.graph.as_deref().unwrap_or("?"), c.n_nodes.unwrap_or(0), c.m_edges.unwrap_or(0),
                 c.c_components.unwrap_or(0), c.rank_of_incidence.unwrap_or(0),
                 c.cycle_space_dim.unwrap_or(0));
    }
    println!("   ⭐ A well-founded relation is one whose cycle space is ZERO, and the ordinal rank");
    println!("      is what you get free when it is. The unit graph's is not, and its rule is that");
    println!("      the weights on it vanish: a potential exists, per Strang's decomposition.");

    // ⭐⭐ AND THE OTHER RANK, IN THE OTHER ALGEBRA. Composition is the linear map `F Phi - E`,
    //    and two layers on a loop have linearly dependent rows in it: ordinal rank stops existing
    //    and matrix rank falls at the same moment. `pm:Layer` calls the pair one layer.
    let comoving = sqlx::query_file!("assets/sql/rank/co_moving_layers.sql").fetch_all(&pool).await?;
    println!("\n18. layers whose remainders must move together, the fourth falsifier computed: {}",
             comoving.len());
    if comoving.is_empty() {
        println!("   ⭐ None. Every layer in this corpus can be perturbed without moving another");
        println!("      through the composition, so no filed pair fails `pm:Layer`'s own test.");
    }

    println!("\nAll checks passed.");
    Ok(())
}
