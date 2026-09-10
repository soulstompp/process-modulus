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

use nalgebra::{DMatrix, DVector};
use std::collections::BTreeMap;

/// One layer's demand and nameplate, with the fit the document filed.
struct Layer {
    filing: String,
    layer: String,
    d_low: f64,
    d_mode: f64,
    d_high: f64,
    n_low: f64,
    n_mode: f64,
    n_high: f64,
    sign: String,
    /// `corpus` or `fixture`. ⭐ Kept because the two must never be pooled in a count: every
    /// fixture layer reaching this query is a `transition`, written to exercise the state
    /// real filings almost never reach, so a pooled census reports the rare case as ordinary.
    evidence: String,
    /// ⛔ Whether `n - d` on this layer's own filed totals IS its remainder. False where its
    /// parts convert through a factor with width, because one factor then scaled both operands
    /// and differencing them counts its spread twice.
    differenceable: bool,
}

/// ⭐⭐ EVERY MATRIX HERE IS REALLY THREE, and there is no interval type in `nalgebra` to
/// hide that. A claim is `low`, `mostLikely`, `high`, so a matrix of claims is three
/// matrices — and they cannot all be operated on the same way, because subtracting
/// intervals REVERSES the bounds. Carrying three named fields and doing the corner
/// bookkeeping by hand is the honest encoding; a single `DMatrix<f64>` would silently pick
/// one corner and lose the other two.
struct Triple {
    low: DVector<f64>,
    mode: DVector<f64>,
    high: DVector<f64>,
}

/// The fit, read across the whole demand range rather than at a point.
///
/// ⭐⭐ THREE MEMBERS, AND THE THIRD IS WHY THE SIGN IS READ ACROSS THE RANGE AT ALL. A
/// two-valued fit, `clearance | interference`, has nowhere to put the overlap, so it can only
/// be read at a single point. ISO 286, which the vocabulary is borrowed from, defines THREE
/// classes, and the missing one is exactly the overlap case:
///
/// ```text
/// clearance     n_low  ≥ d_high     the whole range clears
/// transition    the ranges overlap  partly each way
/// interference  n_high ≤ d_low      the whole range interferes
/// ```
///
/// Where `n − d` crosses zero the magnitude's low bound is legitimately 0, and the sign says
/// so rather than leaving a reader to infer it.
///
/// ⛔ THE THREE ARE NOT MUTUALLY EXCLUSIVE, WHICH THE SCHEMA'S PROSE CLAIMS AND THE ARITHMETIC
/// REFUSES. `clearance` and `interference` BOTH hold when a point nameplate equals a point
/// demand. `layers/remainder.sqlc` settles it by arm order and so does the `if` below, which is
/// the same decision written twice on purpose: a `CASE` is a partition by construction, so no
/// partition law can see the overlap. Disjointness has to be probed on the PREDICATES.
fn classify(r_low: f64, r_high: f64) -> &'static str {
    if r_low >= 0.0 {
        "clearance"
    } else if r_high <= 0.0 {
        "interference"
    } else {
        "transition"
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL").map_err(|_| {
        "DATABASE_URL is unset. This example proves two computations agree, and it cannot \
         do that without the rows. Load them with assets/ddl/schema.ddl and ingest.sql."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. r = n - d, and the fit read off the ranges.
    //
    // ⛔ THE INTERVAL-ARITHMETIC TRAP, WHICH IS NOT A MODELLING CHOICE. Under a transition fit
    //    `|n - d|` is SIGN-BLIND: it keeps only the LARGER of the two sides and the smaller is
    //    invisible inside it. `d = [11.0, 13.2, 16.4]` against `n = 16` gives `[0.0, 2.8, 5.0]`,
    //    the clearance side, and the 0.4 of interference lies inside that interval,
    //    indistinguishable from 0.4 of clearance. So the interference exposure is derived from
    //    the INPUTS and never from the filed magnitude: `max(0, d_high - n_low)`. §7 bounds it.
    //
    // ⭐ AND THE TWO SIDES MUST NEVER BE ADDED. Clearance falls as `d` rises while interference
    //    rises, so a component-wise sum pairs the slack week's spare with the busy week's
    //    unserved demand and reports a state that occurs in no week. It is the same correlation
    //    error as §4, except that the shared driver is `d` itself and the pairing is exactly
    //    backwards. The cure is to evaluate at one corner, where there is one value of each,
    //    which is why `quantity` stayed a single Claim.
    // ------------------------------------------------------------------
    let rows = sqlx::query_file_as!(Layer, "assets/sql/queries/matrices/1-fit-from-ranges.sql")
        .fetch_all(&pool)
        .await?;

    let n = rows.len();
    let d = Triple {
        low: DVector::from_iterator(n, rows.iter().map(|r| r.d_low)),
        mode: DVector::from_iterator(n, rows.iter().map(|r| r.d_mode)),
        high: DVector::from_iterator(n, rows.iter().map(|r| r.d_high)),
    };
    let np = Triple {
        low: DVector::from_iterator(n, rows.iter().map(|r| r.n_low)),
        mode: DVector::from_iterator(n, rows.iter().map(|r| r.n_mode)),
        high: DVector::from_iterator(n, rows.iter().map(|r| r.n_high)),
    };

    // ⛔ THE CROSSED SUBSCRIPTS. r's LOW pairs the nameplate's low with the demand's HIGH.
    // Written as vector subtraction it is one line and the crossing is the whole content.
    let r_low = &np.low - &d.high;
    let _r_mode = &np.mode - &d.mode;
    let r_high = &np.high - &d.low;

    // ⛔⛔ THE ASSERTION RANGES OVER THE DIFFERENCEABLE LAYERS ONLY, AND THAT IS NOT A
    //    NARROWING FOR CONVENIENCE. On a layer whose parts carry a conversion factor with
    //    width, `n` and `d` were both scaled by that one factor, so differencing them counts
    //    its spread twice and the range says `transition` about a filing that clears. The
    //    remainder there is `F Phi r_parts`, which composition/fused_remainders.sqlc computes
    //    and observation 13 prints. Asserting over those rows accuses a correct document.
    let mut disagreements = 0;
    let mut not_differenceable = 0;
    for (i, row) in rows.iter().enumerate() {
        if !row.differenceable {
            not_differenceable += 1;
            continue;
        }
        let computed = classify(r_low[i], r_high[i]);
        if computed != row.sign {
            eprintln!(
                "  ⛔ {}/{}: filed {}, ranges say {computed}",
                row.filing, row.layer, row.sign
            );
            disagreements += 1;
        }
    }
    println!(
        "1. fits recomputed from the ranges: {} of {n} layers, {disagreements} disagreements",
        n - not_differenceable
    );
    println!(
        "   ⛔ {not_differenceable} layer(s) excluded: their parts convert through a factor with \
         width, so n and d are correlated and the difference is a bound rather than the \
         remainder. composition/fused_remainders.sqlc carries theirs."
    );
    assert!(
        not_differenceable > 0,
        "no layer in the corpus has a spread conversion factor, so this exclusion is a bound \
         with nothing to bound and the section demonstrates nothing"
    );
    assert_eq!(
        disagreements, 0,
        "a filed fit disagrees with its own ranges"
    );

    // ⭐⭐ THE CENSUS, AND WHY IT IS PRINTED RATHER THAN COUNTED. These are figures the header
    // above would otherwise have to quote. Maintained by reading the XML and counting, they are
    // numbers nobody recounts. The rows the assertion above already ran on are the same rows the
    // argument needs, so they come from here or they are somebody's recollection.
    let mut census: BTreeMap<(&str, &str), usize> = BTreeMap::new();
    for row in &rows {
        *census
            .entry((row.evidence.as_str(), row.sign.as_str()))
            .or_default() += 1;
    }
    for evidence in ["observation", "stipulation"] {
        let tally: Vec<String> = census
            .iter()
            .filter(|((e, _), _)| *e == evidence)
            .map(|((_, fit), c)| format!("{c} {fit}"))
            .collect();
        let total: usize = census
            .iter()
            .filter(|((e, _), _)| *e == evidence)
            .map(|(_, c)| c)
            .sum();
        println!("   {evidence:<8} {total:>3} layers: {}", tally.join(", "));
    }

    // ⛔ THE FLOOR IS ON THE CORPUS ALONE, and that is the whole reason `evidence` is
    // selected. Counting all 32 rows would let the fixtures hold this assertion up while the
    // corpus emptied underneath it, which is the vacuity trap one level out: a check with
    // plenty to check, none of it the thing being claimed.
    let corpus_layers: usize = census
        .iter()
        .filter(|((e, _), _)| *e == "observation")
        .map(|(_, c)| c)
        .sum();
    assert!(
        corpus_layers >= 20,
        "only {corpus_layers} CORPUS layers carry a demand, a nameplate and a fit; a check \
         with almost nothing to check passes loudest, and the fixtures cannot stand in \
         because every one of them is a transition"
    );

    // ------------------------------------------------------------------
    // 2. D-transpose N: computed, empty, and the reason is the thesis.
    //
    // A document also declares OPERATIONS. Each draws on a layer, or induces a commitment on
    // another, giving two P×L matrices over operations × layers: `D` for draws, `N` for
    // inductions. They are deliberately different types -- a draw is consumption that happened,
    // an induction is a commitment that creates a future draw on a DIFFERENT supply. So there is
    // genuine cross-layer structure, and `D^T N` is the obvious way to collect it.
    //
    // ⛔⛔ TWO THINGS STOP IT BEING WHAT IT LOOKS LIKE. The units: each layer carries its own --
    //    people, GPU, launches per quarter -- so entries come out in people·launches rather than
    //    launches per person. The incidence PATTERNS compose and give you reachability; the
    //    quantities do not. And there is no firing count per operation, deliberately, because
    //    sequence and timing are BPMN's job. What you have is a rate structure, not a flow.
    //
    // ⭐ THAT MATTERS BECAUSE OF WHAT IT IS NOT. `D^T N`'s off-diagonal says WORK DRAWN HERE
    //   COMMITS WORK THERE. Coupling is a different object, and §5 is where it lands.
    // ------------------------------------------------------------------
    let ops = sqlx::query_file!("assets/sql/queries/matrices/2-draws-and-inductions.sql")
        .fetch_all(&pool)
        .await?;

    let stated = ops
        .iter()
        .filter(|r| r.d_val.is_some() && r.n_val.is_some())
        .count();
    println!(
        "2. D-transpose N: {} operation(s) both draw and induce, {stated} with both stated",
        ops.len()
    );
    for r in ops.iter().filter(|r| r.d_val.is_none()) {
        println!(
            "   ⛔ '{}' draws on `{}` and commits `{}`, and THE DRAW IS UNMEASURED, so the\n   \
                product is empty. The one cross-layer entry this corpus could have had is\n   \
                missing for exactly the reason the model exists: no instrument records it.",
            r.operation, r.drawn, r.commits
        );
    }

    // ------------------------------------------------------------------
    // 3. x_composed = F Phi x_parts - e, as an actual matrix product.
    //
    // THE ONE PLACE A REAL LINEAR MAP APPEARS. A second document type consolidates filings.
    // Given part layers indexed by `p` and composed layers by `l`, a composition declares an
    // incidence matrix `F` (L×P, entries in {0,1}, each part used at most once) plus a diagonal
    // `Phi = diag(phi_p)` of strictly positive conversion factors carrying each part into the
    // composed layer's unit. For each quantity `x` in {d, n, draw}:  x_composed = F Phi x - e.
    //
    // `e` is a vector of ELIMINATIONS: quantities double-counted across parts, filed individually
    // with prose and the pair of filings they sit between.
    //
    // ⛔ AN ABSENT `e` IS NOT `e = 0`. A missing vector cannot tell "somebody looked for double
    //   counting and there is none" from "nobody looked", and the two owe OPPOSITE arithmetic:
    //   the first requires `x_composed = F Phi x` exactly, the second requires no equality at
    //   all. The schema makes a filer say which, and that is the difference between an exact
    //   rule and a warning. The `suspended` count below is that difference, counted.
    //
    // ⭐⭐ THE RULE IS INCLUSION-EXCLUSION.  x_composed = Σ x_parts - e  is  |A ∪ B| = |A| + |B|
    //    - |A ∩ B|, with `e` in the place of the intersection. Which answers why `e` has to be
    //    filed at all: FROM |A| AND |B| NOTHING RECOVERS |A ∩ B|. A layer carries a magnitude,
    //    never the set the magnitude counts, so the correction is not a function of the operands.
    //    That is the whole argument for `asrt:Elimination` being an observation with an
    //    `unmeasured` arm.
    //
    // ⭐⭐ UNLESS YOU PIVOT TO AN INCIDENCE WHOSE ELEMENTS CARRY MEASURES OF THEIR OWN, AND `F`'s
    //    DO. A part IS a layer, and a layer carries its own demand and nameplate. So express an
    //    overlap in the part basis and the correction falls out complete, with nothing filed:
    //    `eliminations/derived.sqlc` computes it. The test is whether the incidence's elements
    //    are themselves measured objects. `F`'s are; `D`'s and `N`'s are not, and the same pivot
    //    buys nothing there. ⛔ What the pivot cannot name is the residue: an overlap that is a
    //    SLICE of a part rather than a whole one has no element in the pivoted basis either. That
    //    case, and only that case, is what the filed element is for.
    //
    // ⛔ `F` IS NOT `C` AND IT IS NOT `e`. `F` is where fungibility is asserted: two parts are one
    //   composed layer exactly when supply in one can serve demand in the other. That is a
    //   judgement, it is required to carry prose, and coupling and fungibility are independent
    //   axes -- the corpus populates both off-diagonal cells. The confusion with `e` is a TYPE
    //   error rather than a matter of vocabulary: `F` in {0,1}^(L×P) carries the judgement,
    //   `e` in R^L carries what two parts counted twice, and `e` is not a function of `F`. A
    //   fusion of two disjoint establishments has `e = 0` and is perfectly fungible; a fusion of
    //   two claimants on one machine has `e` equal to a whole part's nameplate and is equally
    //   fungible. `assets/fixtures/every-partial-elimination.xml` files the middle of that scale,
    //   `e = 3` against parts of 10. Reading the operation off `e` -- pooling here, aggregation
    //   there -- quantises a magnitude and infers a judgement from an adjustment. There is no
    //   operator-valued parameter anywhere in `x = F Phi x - e` and no type tag on a row of `F`.
    //
    // ⭐ A LAYER THE COMPOSER ORIGINATED IS A ZERO ROW OF `F` -- a composed layer with no parts,
    //   whose figures are the composer's own. Nothing in the arithmetic forbids it and the model
    //   needs it: a group-level rota belongs to the parent and came from no member.
    // ------------------------------------------------------------------
    let parts = sqlx::query_file!("assets/sql/queries/matrices/3a-fusion-parts.sql")
        .fetch_all(&pool)
        .await?;

    let mut composed: Vec<(String, String)> = parts
        .iter()
        .map(|p| (p.composition.clone(), p.composed.clone()))
        .collect();
    composed.dedup();
    let (rows_n, cols_n) = (composed.len(), parts.len());

    // ⭐ F IS AN INCIDENCE MATRIX: 1 where this part composes into that layer, 0 elsewhere.
    //   Phi is DIAGONAL, one conversion factor per part. Dense is fine at this size, and it
    //   makes what follows a product rather than a join.
    let mut f = DMatrix::<f64>::zeros(rows_n, cols_n);
    for (j, p) in parts.iter().enumerate() {
        let i = composed
            .iter()
            .position(|(c, l)| *c == p.composition && *l == p.composed)
            .unwrap();
        f[(i, j)] = 1.0;
    }
    // ⛔⛔ SPARSITY, AND THE ONE THING THE MATRIX CANNOT SAY. Dense, `F` is rows×cols entries;
    //    the relation stores one row per part. The figures are printed rather than written down,
    //    because a figure carried in a note is right on the day it is written and not after.
    //
    //    IN THE MATRIX, A ZERO ENTRY AND AN ABSENT ENTRY ARE THE SAME VALUE. In the relation they
    //    are a row that says zero and no row at all, and the difference between those two is this
    //    model's entire subject. A `0` in `F` says the composer considered these two layers and
    //    judged them not fungible. A missing row says nothing whatever. Linear algebra has one
    //    symbol for both, which is what §5 pays for.
    let dense = rows_n * cols_n;
    println!(
        "3. F is {rows_n}x{cols_n}: dense that is {dense} entries, the relation stores {cols_n} \
         ({:.1}%)",
        100.0 * cols_n as f64 / dense as f64
    );

    let diag = |g: fn(&_) -> f64| {
        DMatrix::from_diagonal(&DVector::from_iterator(cols_n, parts.iter().map(g)))
    };
    let vect = |g: fn(&_) -> f64| DVector::from_iterator(cols_n, parts.iter().map(g));

    // ⭐⭐ THE CLAIM UNDER TEST. assets/sql/matrices.sql does this with a JOIN and a SUM.
    //    Here it is three matrix products. Agreement makes "a matrix product is a join with
    //    a GROUP BY" a checked statement instead of a sentence in a README.
    let fused = [
        &f * (diag(|p| p.f_low) * vect(|p| p.d_low)),
        &f * (diag(|p| p.f_mode) * vect(|p| p.d_mode)),
        &f * (diag(|p| p.f_high) * vect(|p| p.d_high)),
    ];

    let expected = sqlx::query_file!("assets/sql/queries/matrices/3b-composed-demand.sql")
        .fetch_all(&pool)
        .await?;

    let mut checked = 0;
    let mut suspended = 0;
    for (i, (comp, lay)) in composed.iter().enumerate() {
        let Some(w) = expected
            .iter()
            .find(|e| e.filing == *comp && e.layer == *lay)
        else {
            suspended += 1; // the composer never looked; no equality is owed
            continue;
        };
        for (k, (want, elim, what)) in [
            (w.d_low, w.e_low, "low"),
            (w.d_mode, w.e_mode, "mode"),
            (w.d_high, w.e_high, "high"),
        ]
        .into_iter()
        .enumerate()
        {
            // x_composed = F Phi x_parts - e
            let got = fused[k][i] - elim;
            assert!(
                (got - want).abs() < 1e-9,
                "{comp}/{lay} {what}: F.Phi.x - e = {got} but the filing says {want}"
            );
        }
        checked += 1;
    }
    println!(
        "   F.Phi.x - e against the filed composed demand: {checked} layers, all agree; \
         {suspended} suspended"
    );
    println!(
        "   ⛔ SUSPENDED IS A THIRD OUTCOME BESIDE PASSED AND FAILED, and this example asserted\n   \
            the equality on all of them until a document filed `eliminations` as `unmeasured`.\n   \
            A composer who states they never looked has not claimed their figure equals the sum\n   \
            of its parts. Reporting a pass there is the same failure as a rule that examined no\n   \
            rows — and before the wrapper existed, an unchecked fusion and a checked-clean one\n   \
            were the same bytes."
    );
    assert!(
        checked >= 5,
        "only {checked} composed layers were reachable"
    );

    // ------------------------------------------------------------------
    // 5. What densifying costs. The interesting failure, kept for the end.
    //
    // COUPLING is `C`, L×L, and it says RELIEVING THIS LAYER'S CONSTRAINT MEASURABLY MOVES THAT
    // LAYER'S REMAINDER. The model assumes `C = 0` -- that is what makes the layers separable in
    // the first place -- and requires any nonzero entry to carry a prose observation of how it
    // was seen. `C` and `D^T N` cannot be connected without exactly the firing counts §2 says
    // are not there, so `C` is OBSERVED and never derived.
    //
    // ⛔⛔ ZERO COUPLINGS IS THE ASSUMPTION, NOT A RESULT. A document with none is one where
    //    nobody looked, and the mask below is what keeps the two apart.
    //
    // ⭐⭐⭐ THE SAME GAP RUNS THROUGH EVERY QUANTITY, AND IT IS WHY THE TABLES ARE SPARSE. A
    //    matrix entry is drawn from R. A relation's cell here is drawn from
    //
    //        R  ⊎  {none, unmeasured, notApplicable, derived}
    //
    //    a coproduct, not a number with a sentinel. And the right-hand set is not fixed: at a
    //    `pm:StatedClaim` position it narrows to the three-member subset WITHOUT `none`, because
    //    a measured zero carries a unit, an observer and a provenance and the absence arm has a
    //    home for none of them. A zero there is a claim of `[0, 0, 0]`. That distinction is
    //    unrepresentable in R, it is the reason `NULL` is refused throughout, and nine `CHECK`
    //    constraints hold it in the database.
    // ------------------------------------------------------------------
    let couplings = sqlx::query_file!("assets/sql/queries/matrices/5-coupling-presence.sql")
        .fetch_all(&pool)
        .await?;

    let l = couplings.len();
    let values = DMatrix::<f64>::zeros(l, l);

    // ⭐⭐⭐ THE MASK NOW HAS THREE STATES, AND THAT IS THE WHOLE POINT OF THIS SECTION.
    // As a bit this says only whether a filing stated a coupling. `2` is the state a bit
    // cannot encode, somebody looked and reported independence, and no filing in this corpus
    // is in it, which is itself the finding.
    let mut present = DMatrix::<u8>::zeros(l, l);
    for (i, c) in couplings.iter().enumerate() {
        present[(i, i)] = match (c.n > 0, c.why.as_deref()) {
            (true, _) => 1,         // an observation, and it contradicts the assumption
            (_, Some("none")) => 2, // somebody looked and the layers are independent
            _ => 0,                 // nobody looked, or there is no pair to look at
        };
    }
    let looked = couplings.iter().filter(|c| c.n > 0).count();
    let tested = couplings
        .iter()
        .filter(|c| c.why.as_deref() == Some("none"))
        .count();
    let silent = l - looked - tested;
    println!(
        "5. C densified to {l}x{l}: {looked} filings state a coupling, {tested} assert \
         independence, {silent} say nothing"
    );
    println!(
        "   ⛔ In `values` all {} entries are 0.0 and indistinguishable. A filing where nobody\n   \
            looked and a filing where somebody looked and found nothing are the SAME NUMBER.\n   \
            The `present` mask beside it is the only thing keeping them apart, and nothing in\n   \
            a matrix requires anyone to carry one. This is the place the relational form is\n   \
            strictly better, and it is why the tables are sparse rather than dense.",
        values.len()
    );
    println!(
        "   ⭐ AND THE MASK NEEDED A THIRD VALUE, WHICH IS THE SAME ARGUMENT ONE TURN DEEPER.\n   \
            A bit distinguishes `stated` from `blank`; it cannot distinguish TESTED-AND-ZERO\n   \
            from NOBODY-LOOKED, and those are opposite verdicts on the model itself. Exactly\n   \
            {tested} of these {l} filings are in the state the bit could not hold — the\n   \
            assumption this whole model rests on has never been checked, and once contradicted."
    );

    // ------------------------------------------------------------------
    // 4. Phi is correlated with itself, and the corpus shows it.
    //
    // `Phi`'s entries are themselves three-point intervals ("a month is `[672, 720, 744]` hours"),
    // and the product is component-wise wherever the quantity converted is non-negative, which
    // covers a demand and a nameplate. ⛔ IT DOES NOT COVER A REMAINDER: `r` carries a sign, and
    // under interference the larger factor gives the smaller product, so component-wise would
    // return an interval whose low exceeded its high. `composition/settled_remainders.sqlc`
    // therefore takes the corner on each side, `least(phi_low·r_low, phi_high·r_low)` and the
    // matching `greatest`. ⭐ The general four-corner product, where BOTH operands straddle zero,
    // is not implemented and not owed: a conversion is strictly positive.
    //
    // ⛔⛔ AND `r_composed != n_composed - d_composed` WHEN `Phi != I`, WHICH IS NOT A DEFECT IN
    //    EITHER FIGURE. One `phi_p` multiplies both `n_p` and `d_p`, so those converted intervals
    //    are CORRELATED; differencing them with the bound reversal that independent quantities
    //    require counts `phi`'s spread twice. `r` must be converted directly:
    //
    //        r_composed = F Phi r_parts - e_n + e_d
    //
    //    and BOTH eliminations appear because they act on `r` in opposite directions: removing
    //    double-counted demand RAISES the remainder, removing double-counted nameplate LOWERS it.
    //
    // ⛔ AN IDENTITY STATED IN PROSE AND EVALUATED NOWHERE CAN LOSE A WHOLE TERM WITHOUT ANYTHING
    //   NOTICING, and that one lost `+ e_d` for exactly as long as it lived in a document.
    //   `composition/fused_remainders.sqlc` evaluates it, observation 13 in `examples/observations`
    //   prints it beside the figure `layers/remainder` derives from the composed totals, and the
    //   two agree on every composed layer whose parts convert at a point value and differ on
    //   exactly those carrying a factor with spread. This section is the differing pair.
    // ------------------------------------------------------------------
    let c = sqlx::query_file!("assets/sql/queries/matrices/4-converted-remainder.sql")
        .fetch_one(&pool)
        .await?;

    // The remainder as FILED: each part's own remainder converted, then added.
    let filed = DVector::from_vec(vec![c.q_low, c.q_mode, c.q_high]);
    // The remainder RE-DERIVED from the composed totals, with the bounds crossed correctly.
    let rederived = DVector::from_vec(vec![
        c.n_low - c.d_high,
        c.n_mode - c.d_mode,
        c.n_high - c.d_low,
    ]);

    println!(
        "4. Phi: filed [{}, {}, {}] vs re-derived [{}, {}, {}]",
        filed[0], filed[1], filed[2], rederived[0], rederived[1], rederived[2]
    );
    assert!(
        (filed[1] - rederived[1]).abs() < 1e-9,
        "the two must agree at the mode: that is the point where phi is a single number"
    );
    // ⛔⛔ EXACTLY ZERO IS ITS OWN CASE AND A THRESHOLD CANNOT SEE IT. Written `> 1.0` this
    //     assertion conflates two different failures: a real but small disagreement, and NO
    //     disagreement at all. The second one means phi has no spread — every factor is a
    //     point value — and then this section demonstrates nothing while still passing. So the
    //     two are separated, and the vacuous case gets its own message.
    let spread: f64 = parts
        .iter()
        .map(|p| (p.f_high - p.f_low).abs())
        .fold(0.0, f64::max);
    assert!(
        spread > 0.0,
        "no conversion factor in the corpus has any spread, so nothing here could differ \
         and a green result would mean nothing. This example needs a phi that is a range."
    );
    let (dl, dh) = (
        (filed[0] - rederived[0]).abs(),
        (filed[2] - rederived[2]).abs(),
    );
    assert!(
        dl > 0.0 && dh > 0.0,
        "phi spreads by {spread} yet the two agree at both bounds, which the correlation \
         argument says is impossible: differencing correlated intervals must count that \
         spread twice"
    );
    println!(
        "   ⭐ Equal at the mode, apart at both bounds, by {:.1} and {:.1}. One conversion\n   \
            factor multiplies BOTH the nameplate and the demand, so differencing the converted\n   \
            totals counts phi's spread twice. Both figures are arithmetically correct; only\n   \
            the filed one is the remainder.",
        dl, dh
    );

    // ------------------------------------------------------------------
    // 6. The residue census: how often the sawtooth defeats a filed demand.
    //
    // THE DECOMPOSITION. With `m = k - floor(d/q)`:      r = mq - (d mod q)
    //
    // `mq` is whole quanta and a procurement decision -- hold one more unit and it moves.
    // `(d mod q)` is a residue and no choice of `k` removes it; the closest any decision reaches
    // is `min(d mod q, q - d mod q)`. Since `n` is a multiple of `q`, `r ≡ -d (mod q)` always:
    // rounding up leaves `(-d) mod q` in `[0, q)`, rounding down leaves `-(d mod q)` in `(-q, 0]`,
    // additive inverses in R/qR summing to `q`. Clearance and interference are one division read
    // from opposite sides. The model's claim is that the residue is CONSERVED and the integer part
    // is CHOSEN, so the document records who may change each: the quantum's origin and the
    // amount's origin, each one of `intrinsic`/`contractual`/`policy`.
    //
    // ⛔ TWO THINGS ABOUT THAT IDENTITY THAT A FINDINGS PASS GOT WRONG. First, substituting
    //   `k = n/q` collapses it: `r = (n/q - floor(d/q))q - (d - floor(d/q)q) = n - d`. The floors
    //   appear twice with opposite signs and cancel, so `r` is exact for ANY `d` and ANY `n`,
    //   interval or not. A finding claiming the decomposition "assumes point values" was wrong
    //   about the total.
    //
    // ⛔⛔ SECOND, AND WORSE: `d mod q` IS A SAWTOOTH, so evaluated at an interval's three points
    //    it need not be ordered. `d = (4.5, 5.2, 6.7)` at `q = 1` gives residues `(0.5, 0.2, 0.7)`,
    //    which is not a valid three-point interval at all, while `d` is perfectly well formed.
    //    The census below counts how many corpus layers are in that state. The TOTAL is an
    //    identity; the SPLIT is not representable as two intervals in general. The schema happens
    //    to carry only the total, so nothing is broken -- but read the decomposition as a
    //    derivation of `r`, never as a filing instruction for its two halves.
    // ------------------------------------------------------------------
    let residue = sqlx::query_file!("assets/sql/queries/matrices/6-residue-census.sql")
        .fetch_all(&pool)
        .await?;

    let mut residue_disagreements = 0;
    let mut sawtoothed = 0;
    for row in &residue {
        // ⛔ A QUANTUM WITH A SPREAD WOULD MAKE `d mod q` THREE DIFFERENT DIVISIONS, and the
        //    query divides by the mode. Every filed quantum in this corpus is a point value,
        //    so that is currently free — but it is an assumption, and an assumption that
        //    stops holding silently is the failure this repository keeps naming. Asserted.
        assert!(
            (row.q_low - row.q_high).abs() < 1e-9,
            "{}/{} files a quantum spanning {} to {}, so `d mod q` is three divisions rather \
             than one and §6 is silently taking the mode. That is a legitimate filing state; \
             this census owes a corner argument before it can count it.",
            row.filing,
            row.layer,
            row.q_low,
            row.q_high
        );
        // The second witness: Postgres computed `mod`, this recomputes it with `%`.
        let q = row.q_mode;
        let (lo, md, hi) = (row.d_low % q, row.d_mode % q, row.d_high % q);
        let computed = !(lo <= md && md <= hi);
        if computed != row.sawtoothed {
            eprintln!(
                "  ⛔ {}/{}: SQL says {}, Rust says {computed}",
                row.filing, row.layer, row.sawtoothed
            );
            residue_disagreements += 1;
        }
        if computed {
            sawtoothed += 1;
        }
    }
    println!(
        "6. residue census: {} lumpy corpus layers, {sawtoothed} sawtoothed, \
         {residue_disagreements} disagreements",
        residue.len()
    );
    assert_eq!(
        residue_disagreements, 0,
        "Postgres `mod` and Rust `%` disagree about a residue"
    );
    // ⭐ BOUNDED ON BOTH SIDES, because both vacuous ends are reachable and neither is
    //   interesting. All-clean would mean the corpus files only demands sitting on the
    //   lattice; all-sawtoothed would mean the ordered case is unexercised. The claim is
    //   that this is the ORDINARY state of a real filing, and that needs both to occur.
    assert!(
        sawtoothed > 0 && sawtoothed < residue.len(),
        "{sawtoothed} of {} lumpy layers sawtooth. At either extreme this census demonstrates \
         nothing: the note's claim is that an unordered residue is ordinary rather than \
         universal.",
        residue.len()
    );

    // ------------------------------------------------------------------
    // 7. Slack coverage, and the column that reads zero.
    //
    // HOLDERS AND THE THREE SLACKS THAT BOUND THEM. Each remainder is borne by one or more of
    // exactly five HOLDERS -- `booked`, `counterparty`, `customer`, `people`, `unrealised` --
    // each with a share in the layer's unit, shares summing to `|r|`. That is `H`, L×5, a
    // DISTRIBUTION rather than a selection. Four of the five have no transaction behind them;
    // the substantive claim concerns `people`, where absorbed work creates no instrument and so
    // no accounting system can see it.
    //
    // Each layer also carries three SLACKS, one per buffer, in the layer's unit: `capacitySlack`
    // (how far supply runs above its rating), `inventorySlack` (how much output is held ahead)
    // and `timeSlack` (how much demand survives being held). Call that `S`, L×3. Each remainder
    // names one buffer as its `absorber`, so there is a selection `A: L -> {1,2,3}`, and the rule
    // is
    //
    //     Σ_{j ∉ {customer, unrealised}} H[l,j]  ≤  S[l, A(l)]
    //                                    wherever r[l] < 0 and S[l,A(l)] is stated
    //
    // ⭐ THE SLACKS ARE QUANTITIES AND NOT FLAGS, AND THIS INEQUALITY IS THE REASON: a bit says a
    //   buffer exists, not how much it holds, so against a bit every share fits and nothing is
    //   bounded. BOTH unserved holders are exempt, because both are the overflow: `customer` and
    //   `unrealised` each name demand nobody met, which is not a load the buffer held. Exempting
    //   `unrealised` alone sums a customer's borne degradation into the buffer's load, and `Fit`
    //   calls the same pair a violation under a clearance. And the constraint is ONE-SIDED --
    //   the slacks bound the interference side only, since under clearance the spare IS the
    //   remainder and there is nothing to absorb.
    //
    // ⚠️ THE COMPARISON IS EVALUATED AT THE MODE, following the `sign` convention. The strict
    //    reading, worst share against smallest slack, is available and is deliberately left to a
    //    conformance profile, because choosing between them is a policy rather than a fact. On
    //    `shift-line` the two readings diverge sharply, `1.7 ≤ 2.5` at the mode against
    //    `2.9 ≤ 1.0` strictly. ⚠️ Note what that example is: `shift-line` does not reach this
    //    inequality at all, because both its holders are `customer` and `unrealised` and the left
    //    side is therefore empty. The policy question is real; no document here illustrates it.
    //
    // ⛔⛔ AND THE LEFT SIDE IS EMPTY ON EVERY CORPUS LAYER THAT REACHES THE RULE, which is a
    //    finding about the evidence rather than a gap in it. On every interference layer that
    //    sizes its absorbing buffer, every holder is one of the two unserved kinds: nothing was
    //    absorbed at all, the demand was turned away. `Σ served shares ≤ S` has an empty left side
    //    because the served set is empty, `checks/share_exceeds_slack` reports VACUOUS, and
    //    `algebra/borne.sqlc` prints `held = absorbed + unserved` per layer on every run rather
    //    than leaving that to a comment.
    //
    // ⛔ `S` MUST BE IN THE LAYER'S UNIT, AND ITS NATURAL MEASUREMENT IS NOT. A buffer's size is
    //   observed as a DURATION -- how long stock keeps, how long a caller waits -- while `H` is in
    //   the layer's unit, so the filer owes `quantity = duration × rate` before filing. Every
    //   slack in the corpus carrying a size above zero was measured as a duration, and one of them
    //   appears not to have been multiplied; the census below is sized against absent, one row per
    //   buffer. ⭐ Whether `[0, S]` is closed is a much smaller question and it is closed: a buffer
    //   exactly full has not failed, the next unit fails. The one genuinely half-open interval in
    //   the model is the residue, `(-d) mod q` in `[0, q)`, half-open for the ISO 8601 reason --
    //   at `q` it wraps to 0 rather than meaning "full".
    //
    // ⭐⭐ `S`'s CAPACITY COLUMN ALSO CLOSES AN EQUATION, AND IT IS THE ONLY PLACE THE MODEL
    //    MEASURES SOMETHING WITH NO INSTRUMENT BEHIND IT. Everywhere above, a slack bounds shares
    //    somebody already filed. Here it bounds a quantity derived from the inputs:
    //
    //        max(0, d_high - n_low)  ≤  Σ_j S[l,j]_high  +  Σ_{j ∈ {customer, unrealised}} H[l,j]_high
    //                                   and only where every S[l,j] is stated
    //
    //    Read left to right: what a filing's own demand and nameplate say could have gone unserved
    //    is at most what the supply can absorb plus what the document admits turning away. THE
    //    SHORTFALL IS THE INTERESTING QUANTITY -- remainder that happened and that nothing
    //    recorded, which is this model's subject stated as arithmetic rather than as an argument.
    //    Evaluated at the one corner, for the anti-correlation reason in §1.
    //
    // ⛔⛔ THE BOUND IS OVER THE WHOLE ROW OF `S`, AND IT READ THE CAPACITY COLUMN ALONE UNTIL THE
    //    2026-09-01 pass. The three buffers are SUBSTITUTES: an excess above the nameplate can be
    //    absorbed by running hot, by drawing on stock, or by making the demand wait. One column
    //    closed is ONE ROUTE closed, which does not entail that anything went unserved, and two
    //    rules drew that conclusion from it. ⭐ An unstated slack SUSPENDS the inequality rather
    //    than contributing zero, because coalescing an absence to zero turns NOBODY LOOKED into
    //    THERE IS NO ROOM and manufactures a shortfall out of a gap.
    //
    // ⚠️ TWO LIMITS, BOTH WORTH KNOWING BEFORE YOU TRUST IT. It is a TRANSITION-FIT INSTRUMENT
    //    ONLY: under interference the exposure IS `|n - d|`'s high bound and the inequality
    //    degenerates into the share-sum rule, and under clearance it is zero. And it is SILENT ON
    //    ALMOST EVERY EXPOSED LAYER, for the reason the model itself predicts:
    //    `layers/exposure_scope.sqlc` sorts them into the three standings and
    //    `algebra/exposure_standing.sqlc` holds those to a partition, so run it and read the
    //    counts. Nearly all have a buffer nobody sized, and NOT ONE has a buffer with room in it.
    //    The suspension is never the harmless case; it is always an unmeasured route, which is the
    //    same sentence `people` states about instruments. A bound with nothing to bound passes
    //    loudest, and the coverage table says VACUOUS rather than scoring it as covered.
    // ------------------------------------------------------------------
    let slacks = sqlx::query_file!("assets/sql/queries/matrices/7-slack-coverage.sql")
        .fetch_all(&pool)
        .await?;

    let mut per_buffer: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for row in &slacks {
        let e = per_buffer.entry(row.buffer.as_str()).or_default();
        e.1 += 1;
        if row.sized {
            e.0 += 1;
        }
    }
    println!(
        "7. slack coverage (corpus): {} (layer, buffer) rows",
        slacks.len()
    );
    for (buffer, (sized, total)) in &per_buffer {
        let flag = if *sized == 0 { "  ⛔ unexercised" } else { "" };
        println!("   {buffer:<10} {sized} sized of {total}{flag}");
    }

    // ⛔⛔ NO ASSERTION PINS `capacity` AT ZERO, and that is deliberate. An equality here
    //     would turn today's gap into tomorrow's failure: the first filer to size a capacity
    //     slack would break the build for doing the thing the model wants. The zero is
    //     REPORTED, loudly, and the paragraph above says the bound is unexercised on the
    //     strength of this line rather than on somebody's memory.
    let sized_total: usize = per_buffer.values().map(|(s, _)| s).sum();
    assert!(
        sized_total > 0,
        "not one slack in the corpus carries a number, so the share-sum bound has nothing to \
         bound anywhere and every inequality in §3 of the note passes vacuously"
    );

    println!("\nAll checks passed.");
    Ok(())
}
