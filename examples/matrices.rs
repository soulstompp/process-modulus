//! The second witness: the same arithmetic, computed a different way.
//!
//! [`assets/sql/matrices.sql`] computes each matrix in the database, with joins and
//! `GROUP BY`. This program pulls the same rows out and computes with `nalgebra`, where a
//! matrix product is a matrix product. Then it asserts the two agree.
//!
//! ⭐⭐ THAT ASSERTION IS THE POINT, AND IT IS THIS REPOSITORY'S OWN STANDARD APPLIED TO
//! ARITHMETIC. `tests/independence.rs` argues that corroboration between two things sharing
//! a code path is worth nothing. A query that computes a number and a README that says "look,
//! it is right" is ONE WITNESS ASSERTING. Recomputing it by a different route and comparing
//! is two, and the claim `assets/sql/README.md` makes — that a matrix product IS a join with
//! a `GROUP BY` — stops being something the author said and becomes something that was
//! checked.
//!
//! ⚠️ The two sides share the ingest, and that is fine: the ingest is not what is being
//! proved. What is being proved is the arithmetic on top of it.
//!
//! Run it with a loaded database:
//!
//! ```text
//! createdb process_modulus_proof
//! psql -d process_modulus_proof -f assets/sql/schema.ddl -f assets/sql/ingest.sql
//! DATABASE_URL='postgresql:///process_modulus_proof?host=/var/run/postgresql' \
//!   cargo run --example matrices
//! ```
//!
//! ⛔ There is no silent skip. No database means it fails to run, because a proof that
//! passes when it did not execute is the vacuity trap this repository keeps naming.

use nalgebra::{DMatrix, DVector};

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
         do that without the rows. Load them with assets/sql/schema.ddl and ingest.sql."
    })?;
    let pool = sqlx::postgres::PgPool::connect(&url).await?;

    // ------------------------------------------------------------------
    // 1. r = n - d, and the fit read off the ranges.
    // ------------------------------------------------------------------
    let rows = sqlx::query_file_as!(Layer, "assets/sql/queries/1-fit-from-ranges.sql")
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

    let mut disagreements = 0;
    for (i, row) in rows.iter().enumerate() {
        let computed = classify(r_low[i], r_high[i]);
        if computed != row.sign {
            eprintln!(
                "  ⛔ {}/{}: filed {}, ranges say {computed}",
                row.filing, row.layer, row.sign
            );
            disagreements += 1;
        }
    }
    println!("1. fits recomputed from the ranges: {n} layers, {disagreements} disagreements");
    assert_eq!(
        disagreements, 0,
        "a filed fit disagrees with its own ranges"
    );
    assert!(
        n >= 20,
        "only {n} layers carry a demand, a nameplate and a fit; a check with almost \
         nothing to check passes loudest"
    );

    // ------------------------------------------------------------------
    // 2. D-transpose N: computed, empty, and the reason is the thesis.
    // ------------------------------------------------------------------
    let ops = sqlx::query_file!("assets/sql/queries/2-draws-and-inductions.sql")
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
    // ------------------------------------------------------------------
    let parts = sqlx::query_file!("assets/sql/queries/3a-fusion-parts.sql")
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

    let expected = sqlx::query_file!("assets/sql/queries/3b-composed-demand.sql")
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
        "3. F.Phi.x - e against the filed composed demand: {checked} layers, all agree; \
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
    // ------------------------------------------------------------------
    let couplings = sqlx::query_file!("assets/sql/queries/5-coupling-presence.sql")
    .fetch_all(&pool)
    .await?;

    let l = couplings.len();
    let values = DMatrix::<f64>::zeros(l, l);

    // ⭐⭐⭐ THE MASK NOW HAS THREE STATES, AND THAT IS THE WHOLE POINT OF THIS SECTION.
    // It used to be a bit: a filing either stated a coupling or it did not. `2` is the
    // state that had no encoding — somebody looked and reported independence — and no
    // filing in this corpus is in it, which is itself the finding.
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
    // ------------------------------------------------------------------
    let c = sqlx::query_file!("assets/sql/queries/4-converted-remainder.sql")
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
    // ⛔⛔ EXACTLY ZERO IS ITS OWN CASE AND A THRESHOLD CANNOT SEE IT. An earlier version of
    //     this assertion read `> 1.0`, which conflated two different failures: a real but
    //     small disagreement, and NO disagreement at all. The second one means phi has no
    //     spread — every factor is a point value — and then this section demonstrates
    //     nothing while still passing. So the two are separated, and the vacuous case gets
    //     its own message.
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

    println!("\nAll checks passed.");
    Ok(())
}
