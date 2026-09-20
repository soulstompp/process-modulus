// ⛔ THE HEADER OF THIS PROGRAM IS `README.md` BESIDE IT, AND THERE IS ONE COPY OF IT, in both
// languages, for the reason `examples/witnesses/main.rs` gives.
#![doc = include_str!("README.md")]
#![doc = include_str!("README.pt.md")]

use std::collections::{BTreeMap, BTreeSet};
use std::fmt::Write as _;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// One edit, and what must follow from it.
struct Probe {
    /// The name the report prints; a law's probe starts with the law's slug.
    id: &'static str,
    /// A document the mutant replaces in the ingest: `(path, from, to, nth occurrence)`.
    doc: Option<(&'static str, &'static str, &'static str, usize)>,
    /// Rows changed after loading, inside the same rolled-back transaction.
    rows: &'static str,
    /// The composed statement whose rows are judged, named as under `assets/sqlc/` without the
    /// extension, and read inline from `target/sql-inline/`. Unused
    /// by an acquittal, which runs every rule and every law.
    statement: &'static str,
    /// An edit to that statement's text: `(from, to, occurrences)`, every occurrence replaced
    /// and the count asserted.
    swap: Option<(&'static str, &'static str, usize)>,
    expect: Expect,
    /// What the edit means.
    says: &'static str,
}

enum Expect {
    /// Exactly these subjects fail and every other row of the statement holds.
    Only(&'static [&'static str]),
    /// These subjects fail, and others may.
    Includes(&'static [&'static str]),
    /// At least one row fails; the header of the law says which population.
    Some,
    /// An acquittal: across every rule and every law, exactly these rules fire and exactly these
    /// `(law, subject)` rows fail.
    Verdicts { rules: &'static [&'static str], laws: &'static [(&'static str, &'static str)] },
    /// The grammar refuses the mutant, so no reader ever has to judge it.
    Refused,
}
use Expect::{Includes, Only, Refused, Some as AtLeastOne, Verdicts};

const NO_ROWS: &str = "";

const PROBES: &[Probe] = &[
    // ---- laws, each seen to fail on an edit to the relation it governs ----
    Probe {
        id: "absences_filed",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/absences_filed",
        swap: Some(("UNION ALL SELECT filing, layer, 'remainder absorber',  absorber_absent",
                    "UNION ALL SELECT filing, layer, 'remainder absorber',  NULL::pm.absence_reason", 1)),
        expect: Only(&["remainder absorber"]),
        says: "the census stops counting one group of positions",
    },
    Probe {
        id: "derivations_filed",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/derivations_filed",
        swap: Some(("UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation",
                    "UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, NULL::pm.identity", 1)),
        expect: Only(&["pm:remainder/pm:quantity"]),
        says: "the census stops counting one position's derivations",
    },
    Probe {
        id: "derivations_filed / a row",
        doc: None,
        rows: "DELETE FROM pm.derivation WHERE filing = 'every-absence' AND owns = 'pm:layer/pm:timeSlack';",
        statement: "algebra/derivations_filed",
        swap: None,
        expect: Only(&["pm:layer/pm:timeSlack"]),
        says: "one filed derivation is lost between the document and its census",
    },
    Probe {
        id: "absences_filed / a row",
        doc: None,
        rows: "DELETE FROM pm.absence WHERE filing = 'enterprise-contract' AND seq = 1;",
        statement: "algebra/absences_filed",
        swap: None,
        expect: Only(&["denominator"]),
        says: "one filed absence is lost between the document and its census",
    },
    Probe {
        id: "arithmetic_class",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/arithmetic_class",
        swap: Some(("WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,",
                    "WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                END AS verdict,", 1)),
        expect: Only(&["r = n - d"]),
        says: "`r = n - d` loses the arm that says computable, so its candidates fall out of every class",
    },
    Probe {
        id: "composed_quantum",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composed_quantum",
        swap: Some(("gcd(f.g, o.quantum_mode)", "greatest(f.g, o.quantum_mode)", 1)),
        expect: Only(&["merge-holding-composition / compute"]),
        says: "the fold takes the largest quantum instead of the common divisor",
    },
    Probe {
        id: "composed_remainder",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composed_remainder",
        swap: Some(("max(p.at_low)  FILTER (WHERE p.quantity = 'nameplate') AS n_at_low,",
                    "max(p.low)  FILTER (WHERE p.quantity = 'nameplate') AS n_at_low,", 1)),
        expect: Only(&["every-inverting-elimination / shift-capacity"]),
        says: "the pivot reads the nameplate elimination at its low whether or not it crossed",
    },
    Probe {
        id: "conforms",
        doc: None,
        rows: "UPDATE pm.nameplate SET amount_low = 100, amount_mode = 100, amount_high = 100
               WHERE filing = 'enterprise-contract' AND layer = 'support-cover';",
        statement: "algebra/conforms",
        swap: None,
        expect: Includes(&["nameplate_not_a_multiple"]),
        says: "a nameplate moves off its quantum's lattice, with every rule the move reaches",
    },
    Probe {
        id: "integrity",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/integrity",
        swap: Some((") c ON c.rule = r.rule", ") c ON c.rule = r.rule || '?'", 1)),
        expect: Only(&["rules"]),
        says: "the rules fold's outer join stops matching, so every rule lands on both one-sided regions while EXCEPT finds none",
    },
    Probe {
        id: "crossed_remainder",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/crossed_remainder",
        swap: Some(("x.n_low  - x.d_high AS r_low,", "x.n_low  - x.d_low AS r_low,", 3)),
        expect: AtLeastOne,
        says: "the low of n - d pairs n.low with d.low, so no bound is crossed",
    },
    Probe {
        id: "derived_quantities",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/derived_quantities",
        swap: Some(("CASE WHEN b.why IS NULL THEN l.s_low  - l.e_low  END AS low,",
                    "CASE WHEN b.why IS NULL THEN l.s_low END AS low,", 2)),
        expect: Only(&["every-derived-quantity / pair / demand"]),
        says: "the walked figure forgets the root's own elimination at its low",
    },
    Probe {
        id: "exposure",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/exposure",
        swap: Some(("greatest(-x.r_low, 0) AS exposure", "greatest(x.d_high - x.n_low, 0) AS exposure", 1)),
        expect: AtLeastOne,
        says: "exposure is read from the differenced totals even where the pivot moved the low",
    },
    Probe {
        id: "exposure_standing",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/exposure_standing",
        swap: Some(("            ELSE                       'every buffer sized and empty'::public.exposure_standing END AS standing",
                    "            END AS standing", 3)),
        expect: Only(&["layers/exposure_scope"]),
        says: "the last standing loses its arm, so the layers it held have none",
    },
    Probe {
        id: "factor_state",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/factor_state",
        swap: Some(("WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state",
                    "WHEN p.factor_absent     IS NOT NULL THEN 'derivation'::public.factor_state", 1)),
        expect: Only(&["composition/part_references"]),
        says: "a factor filed absent is called a derivation, so the one absent part carries a state its columns contradict",
    },
    Probe {
        id: "fit_domain / cell",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fit_domain",
        swap: Some(("  ('shares_do_not_sum', 'transition',   'open',",
                    "  ('shares_do_not_sum', 'transition',   'exercised',", 2)),
        expect: Only(&["shares_do_not_sum"]),
        says: "a rule declares a fit class exercised that nothing it examined is in",
    },
    Probe {
        id: "fit_domain / axis",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fit_domain",
        swap: Some(("  ('draw_exceeds_the_supply',              'not read'),",
                    "  ('draw_exceeds_the_supply',              'derived fit'),", 4)),
        expect: Only(&["draw_exceeds_the_supply"]),
        says: "a rule whose closure reaches no fit declares that it reads one",
    },
    Probe {
        id: "fusion_sum",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fusion_sum",
        swap: Some(("coalesce(e.at_low,  0) AS e_at_low,", "coalesce(e.low,  0) AS e_at_low,", 1)),
        expect: Only(&["every-inverting-elimination / shift-capacity / nameplate"]),
        says: "an elimination wider than its sum is subtracted bound by bound, which inverts it",
    },
    // ⭐⭐ THE CORNER, AND IT IS WHY THIS LAW WAS WRONG FOR A WHOLE PASS. The law recomputed the
    //    sum bound by bound while `composition/converted.sqlc` read the corner the operand's sign
    //    picks: two functions agreeing on every non-negative operand, and no filed operand is
    //    negative. Nothing here could fail, so nothing did. `examples/soundness/main.rs` section 8
    //    now holds every conversion site to the one spelling; this holds THIS law's own route to
    //    the one arithmetic, which a spelling check cannot do.
    Probe {
        id: "fusion_sum / corner",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fusion_sum",
        swap: Some(("sum(least(   s.low", "sum(greatest(   s.low", 1)),
        expect: Only(&[
            "every-nested-conversion / line-batches / demand",
            "every-nested-conversion / line-batches / draw",
            "every-nested-conversion / line-batches / nameplate",
            "every-nested-conversion / line-hours / demand",
            "every-nested-conversion / line-hours / draw",
            "every-nested-conversion / line-hours / nameplate",
            "every-unit-cycle / cards / demand",
            "every-unit-cycle / cards / draw",
            "every-unit-cycle / cards / nameplate",
            "merge-holding-composition / compute / demand",
            "merge-holding-composition / compute / draw",
            "merge-holding-composition / compute / nameplate",
        ]),
        says: "a part is converted at the wrong corner, which moves every sum under a factor with width",
    },
    // ⭐⭐ TWO PROBES, BECAUSE THE LAW HAS TWO ARMS AND A COUNT WOULD PASS EITHER WAY. The first
    //    makes the two instruments disagree; the second makes the graph look empty, so the law must
    //    refuse a zero it got for the wrong reason rather than call it a pass. `0 = 0` is true of an
    //    empty graph and of a rule that examined nothing, which is why non-vacuity is a column here.
    Probe {
        id: "cycle_space / equivalence",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/cycle_space",
        swap: Some(("count(*) FILTER (WHERE k.violates)", "count(*)", 1)),
        expect: Only(&["rank/cycle_space"]),
        says: "the jagged-partition rule is read as accusing every fusion while F carries no cycle",
    },
    Probe {
        id: "cycle_space / vacuity",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/cycle_space",
        swap: Some(("m.n_nodes AS nodes", "0 AS nodes", 1)),
        expect: Only(&["rank/cycle_space"]),
        says: "the layer graph is read as empty, where a cycle space of zero means nothing at all",
    },
    // ⭐⭐ THE FOUR SUBSPACES OF THE FOLD, ONE PROBE EACH, AND THE TWO THAT SHARE A LAW SHARE IT
    //    BECAUSE THEY ARE ONE COUNT READ FROM EACH END. The kernel is held against the layer
    //    graph, the row space against the rank counted along the fusions, the image against the
    //    rule that keeps it whole, and the closure against the sum of the levels inside it.
    Probe {
        id: "composition_kernel",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composition_kernel",
        swap: Some(("       p.part_filing  || '/' || p.part_layer     AS to_node",
                    "       p.part_filing                             AS to_node", 1)),
        expect: Only(&["rank/composition_kernel"]),
        says: "every part layer of one filing collapses to one node, so the graph loses edges while the fold keeps its parts",
    },
    Probe {
        id: "composition_row_space",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composition_row_space",
        swap: Some(("       1::bigint                                                            AS row_dim,",
                    "       2::bigint                                                            AS row_dim,", 2)),
        expect: Only(&["rank/composition_row_space", "rank/composition_row_space / the rank"]),
        says: "a fusion's row space is read as two dimensions, so no fibre sums to its own parts and the rank doubles",
    },
    Probe {
        id: "composition_row_space / the rank",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composition_row_space",
        swap: Some(("       count(k.composition)                             AS rank,",
                    "       count(k.composition) + 1                         AS rank,", 1)),
        expect: Only(&["rank/composition_row_space / the rank"]),
        says: "the fusion side counts one row too many per composition, and only the crossing can see it",
    },
    Probe {
        id: "composition_image",
        doc: None,
        rows: "UPDATE pm.part SET part_layer = 'nowhere' \
                WHERE composition = 'merge-group-composition' AND composed_layer = 'capacidade-instalada';",
        statement: "algebra/composition_image",
        swap: None,
        expect: Only(&["rank/composition_image"]),
        says: "a fusion's only part names a layer nobody filed, so a declared fusion is no row of the matrix",
    },
    Probe {
        id: "composition_image / the rule",
        doc: None,
        rows: "UPDATE pm.part SET part_layer = 'nowhere' \
                WHERE composition = 'merge-group-composition' AND composed_layer = 'capacidade-instalada';",
        statement: "algebra/composition_image",
        swap: Some(("           r.composition IS NULL AS violates,", "           false AS violates,", 1)),
        expect: Only(&["rank/composition_image", "rank/composition_image / the rule"]),
        says: "the rule stops accusing the part that resolves to nothing while the dimension it leaves is still there",
    },
    Probe {
        id: "composition_closure",
        doc: None,
        rows: "INSERT INTO pm.part (composition, composed_layer, part_filing, part_layer, part_party, part_version) \
                VALUES ('merge-holding-composition', 'compute', \
                        'urn:example:filing:us-member:2026-08-31', 'compute', 'probe', '2026-08-31');",
        statement: "algebra/composition_closure",
        swap: None,
        expect: Only(&["rank/composition_closure"]),
        says: "a root draws a layer already reachable beneath it, so the blocks sum higher than the leaves allow",
    },
    Probe {
        id: "composition_closure / the row space",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/composition_closure",
        swap: Some(("                                  AND NOT w.factor_absent",
                    "                                  AND w.factor_absent", 1)),
        expect: Only(&["rank/composition_closure"]),
        says: "the leaves with a stated path product are read as the leaves without one, so the two columns stop exhausting the leaves",
    },
    Probe {
        id: "figures",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/figures",
        swap: Some(("FULL JOIN (", "JOIN (", 1)),
        expect: Only(&["layers/figures"]),
        says: "the pair keeps only the layers with both figures, so one with a demand and no nameplate has no row",
    },
    Probe {
        id: "fusion_quantities",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fusion_quantities",
        swap: Some((") s ON s.filing = f.filing AND s.layer = f.layer", ") s ON s.filing = f.filing", 1)),
        expect: Only(&["composition/fusion_quantities"]),
        says: "the join forgets the composed layer, so a quantity pairs with every fusion of its filing",
    },
    Probe {
        id: "fusions_have_parts",
        doc: None,
        rows: "DELETE FROM pm.part WHERE composition = 'every-derived-quantity' AND composed_layer = 'single';",
        statement: "algebra/fusions_have_parts",
        swap: None,
        expect: Only(&["every-derived-quantity"]),
        says: "a fusion loses every part it names",
    },
    Probe {
        id: "fusions_have_parts / the references",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/fusions_have_parts",
        swap: Some((") r\nGROUP BY r.composition, r.composed_layer",
                    ") r\nWHERE r.factor_state <> 'stated'\nGROUP BY r.composition, r.composed_layer", 1)),
        expect: Only(&["every-nested-conversion", "every-unit-cycle", "merge-group-composition",
                       "merge-holding-composition"]),
        says: "the fold stops counting the parts that state a factor, so those compositions' sums fall short of what they filed",
    },
    Probe {
        id: "leaves",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/leaves",
        swap: Some(("SELECT d.*\nFROM      (", "SELECT DISTINCT d.filing, d.layer\nFROM      (", 1)),
        expect: Only(&["composition/leaves"]),
        says: "the leaves are deduplicated on the key, as an `EXCEPT` would, and descent is a bag",
    },
    Probe {
        id: "owed_equality",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/owed_equality",
        swap: Some(("    UNION\n    SELECT d.filing, d.layer, d.quantity\n    FROM (",
                    "    UNION\n    SELECT d.filing, d.layer, NULL::pm.summed_quantity\n    FROM (", 1)),
        expect: Only(&["composition/owed_equality"]),
        says: "a composed figure filed as a derivation is left owing an equality",
    },
    Probe {
        id: "owed_remainder",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/owed_remainder",
        swap: Some(("WHERE s.quantity IS NULL\n   OR s.quantity IN ('demand', 'nameplate')",
                    "WHERE s.quantity IN ('demand', 'nameplate')", 2)),
        expect: Only(&["composition/owed_remainder"]),
        says: "a suspension that names no quantity stops lifting the remainder",
    },
    Probe {
        id: "part_quantities",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/part_quantities",
        swap: Some((") comp ON comp.filing = p.composition AND comp.layer = p.composed_layer\n      AND comp.quantity = part.quantity",
                    ") comp ON comp.filing = p.composition AND comp.layer = p.composed_layer", 1)),
        expect: Only(&["composition/part_quantities"]),
        says: "the join forgets the quantity, so a part's demand is set beside its composed layer's every quantity",
    },
    Probe {
        id: "part_sums",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/part_sums",
        swap: Some((") c\nGROUP BY c.composition, c.composed_layer, c.quantity",
                    ") c\nWHERE c.low = c.high\nGROUP BY c.composition, c.composed_layer, c.quantity", 1)),
        expect: Only(&["demand", "draw", "nameplate"]),
        says: "the fold drops every part whose figure has width, so its totals fall short of the parts",
    },
    Probe {
        id: "remainder_decomposes",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/remainder_decomposes",
        swap: Some(("l.n_low  / l.quantum_mode - floor(l.d_high / l.quantum_mode) AS m_low,",
                    "l.n_low  / l.quantum_mode - floor(l.d_low / l.quantum_mode) AS m_low,", 1)),
        expect: AtLeastOne,
        says: "the whole quanta at the low are counted from the low demand",
    },
    Probe {
        id: "remainder_in_force",
        doc: None,
        rows: "UPDATE pm.elimination_search SET absent = 'unmeasured'
               WHERE composition = 'every-nested-conversion' AND composed_layer = 'line-hours';",
        statement: "algebra/remainder_in_force",
        swap: Some((" AND g.layer = b.layer)\n) x", ")\n) x", 1)),
        expect: Only(&["layers/remainder"]),
        says: "a figureless remainder takes every other layer of its filing with it",
    },
    Probe {
        id: "remainder_standing",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/remainder_standing",
        swap: Some(("            ELSE 'bounded and the pairs answered'::public.remainder_standing END AS standing",
                    "            END AS standing", 3)),
        expect: Only(&["layers/remainder_scope"]),
        says: "the last standing loses its arm, so the remainders it held have none",
    },
    Probe {
        id: "sawtooth",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/sawtooth",
        swap: Some(("floor(l.d_low / l.quantum_mode) <> floor(l.d_high / l.quantum_mode) AS crosses_tooth",
                    "floor(l.d_low / l.quantum_mode) <> floor(l.d_mode / l.quantum_mode) AS crosses_tooth", 1)),
        expect: AtLeastOne,
        says: "a demand that crosses a tooth after its mode is taken for one that stays inside",
    },
    Probe {
        id: "searches_answered",
        doc: None,
        rows: "DELETE FROM pm.elimination_between WHERE composition = 'every-derived-quantity' AND composed_layer = 'pair';
               DELETE FROM pm.elimination WHERE composition = 'every-derived-quantity' AND composed_layer = 'pair';",
        statement: "algebra/searches_answered",
        swap: None,
        expect: Only(&["double counting"]),
        says: "a fusion's eliminations vanish while its search still says it filed some",
    },
    Probe {
        id: "settled_remainders",
        doc: None,
        rows: "UPDATE pm.layer SET demand_low = NULL, demand_mode = NULL, demand_high = NULL, demand_unit = NULL,
                                demand_derivation = 'fusionSum'
               WHERE filing = 'every-derived-quantity' AND layer = 'line-c';",
        statement: "algebra/settled_remainders",
        swap: Some(("AND q.low IS NULL", "AND q.low IS NULL AND false", 1)),
        expect: Only(&["composition/settled_remainders"]),
        says: "a walk stops at a node with no figure and nothing lifts the remainder above it",
    },
    Probe {
        id: "subject_boxes",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/subject_boxes",
        swap: Some(("count(c.rule) FILTER (WHERE c.violates IS NULL AND c.filing IS NOT NULL) AS silent",
                    "count(c.rule) FILTER (WHERE c.violates IS NULL) AS silent", 1)),
        expect: Only(&["rules"]),
        says: "the rules fold's silent box takes the roster's own rows too, so a vacuous rule is counted twice",
    },
    Probe {
        id: "subject_boxes / the population",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/subject_boxes",
        swap: Some((") c) AS population", ") c WHERE c.filing IS NOT NULL) AS population", 1)),
        expect: Only(&["rules"]),
        says: "the population is counted without the roster's own rows, so the fold's rows no longer add up to it",
    },
    Probe {
        id: "served_totals",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/served_totals",
        swap: Some(("WHERE h.kind IN ('booked', 'counterparty', 'people')", "WHERE h.kind IN ('booked', 'counterparty')", 1)),
        expect: Only(&["folds/served_totals"]),
        says: "the served kinds lose `people`, so a layer holding a people share holds more than it served and left unserved",
    },
    Probe {
        id: "settled_remainders / passed",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/settled_remainders",
        swap: Some((") u ON u.filing = w.filing AND u.layer = w.layer", ") u ON u.filing = w.filing", 2)),
        expect: Only(&["composition/settled_remainders"]),
        says: "the nodes passed through are matched on the filing alone, so one frontier row is passed through once per unsettled layer of its filing",
    },
    Probe {
        id: "suspended_quantities",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/suspended_quantities",
        swap: Some(("       ON s.quantity IS NULL OR s.quantity = q.quantity", "       ON s.quantity = q.quantity", 1)),
        expect: Only(&["composition/suspended_quantities"]),
        says: "a ground naming no quantity stops lifting any, so its fusion's pairs are neither owing nor suspended",
    },
    Probe {
        id: "unresolved_parts",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/unresolved_parts",
        swap: Some(("WHERE p.composition IS NULL", "WHERE p.composition IS NULL OR p.part_layer LIKE 'l%'", 1)),
        expect: Only(&["composition/unresolved_parts"]),
        says: "parts that resolve are counted among the ones that do not",
    },
    Probe {
        id: "layer_units",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/layer_units",
        // ⛔ The nameplate arm, in all three copies. A layer that files its nameplate in a unit of
        //    its own is exactly the document `units/conversions.sqlc` pins `quantity = 'nameplate'`
        //    against, and the pin cannot see it: the graph it builds stays perfectly well formed.
        //    The law composes `layers/quantities` once for the unit and once more through
        //    `composition/part_quantities`, which takes it at the part AND at the composed layer,
        //    so an edit to the model has to land on every copy the statement carries.
        swap: Some((
            "n.n_low, n.n_mode, n.n_high, n.n_unit",
            "n.n_low, n.n_mode, n.n_high, n.n_unit || ' each'",
            3,
        )),
        expect: Only(&["layers/quantities"]),
        says: "a layer names one unit in its nameplate and another everywhere else, so reading \
               the conversion graph off one quantity reads a unit the layer's other figures deny",
    },
    Probe {
        id: "unsized_conversions_are_unsettled",
        doc: None,
        rows: NO_ROWS,
        statement: "algebra/unsized_conversions_are_unsettled",
        // ⛔ The predicate is `composition/unsettled.sqlc`'s too, word for word, and inlined this
        //    statement carries both. What follows it is the only thing that tells them apart: the
        //    narrow one ends there, the other one goes on to `OR ... stated ... <> ...`.
        swap: Some((
            "WHERE p.factor_state IN ('absent', 'derivation')\n ) x",
            "WHERE p.factor_state IN ('absent', 'derivation', 'omitted')\n ) x",
            1,
        )),
        expect: Only(&["composition/unsized_conversions"]),
        says: "a part whose units already agree is counted as a conversion nobody could size, \
               so layers that difference perfectly well fall outside the ground that lifts them",
    },
    // ---- acquittals: a correct filing, edited, and the verdicts it must still get ----
    Probe {
        id: "acquit: a part not here",
        doc: Some(("assets/corpus/merge-holding-composition.xml",
                   "        <asrt:filing>\n          <pm:notation>urn:example:filing:group-parent:2026-08-31</pm:notation>\n          <pm:id>compute-pt</pm:id>",
                   "        <asrt:filing>\n          <pm:notation>urn:example:filing:nobody-files-this</pm:notation>\n          <pm:id>compute-pt</pm:id>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        // ⭐ `fit_domain` moves because `compute` is the only clearance layer that states its
        //   remainder quantity; lifting its remainder empties a cell the coverage table declares
        //   exercised, which is the table noticing, not a rule accusing.
        expect: Verdicts {
            rules: &["unresolved_part"],
            laws: &[("conforms", "unresolved_part"),
                    ("fit_domain", "stated_quantity_is_not_the_magnitude")],
        },
        says: "a composer names a part the reader cannot fetch: the reference is wrong, and nothing built on the missing figure is",
    },
    Probe {
        id: "acquit: a derived figure nothing builds",
        doc: Some(("assets/fixtures/every-derived-quantity.xml",
                   "            <pm:claim>\n              <pm:low>5</pm:low><pm:mostLikely>6</pm:mostLikely><pm:high>8</pm:high>\n              <pm:unit>orders per day</pm:unit>\n              <pm:denominator><pm:period>day</pm:period></pm:denominator>\n              <pm:narrowsWhen><pm:absent><pm:reason>unmeasured</pm:reason><pm:note>stipulated: nobody has said what would tighten this</pm:note></pm:absent></pm:narrowsWhen>\n              <pm:boundOrigin><pm:absent><pm:reason>none</pm:reason><pm:note>stipulated: nothing sets this bound</pm:note></pm:absent></pm:boundOrigin>\n            </pm:claim>",
                   "            <pm:derivation><pm:identity>fusionSum</pm:identity><pm:note>mutated: an output with no fusion behind it</pm:note></pm:derivation>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Verdicts { rules: &[], laws: &[] },
        says: "a part files its demand as its fusion's sum and it has no fusion: the sum and the remainder above it are lifted, and nobody is accused",
    },
    Probe {
        id: "acquit: an unsearched conversion with width",
        doc: Some(("assets/fixtures/every-nested-conversion.xml",
                   "        <pm:reason>notApplicable</pm:reason>\n        <pm:note>a one-part fusion.",
                   "        <pm:reason>unmeasured</pm:reason>\n        <pm:note>a one-part fusion.",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Verdicts { rules: &[], laws: &[] },
        says: "a composer never searched a fusion whose conversion has width: its remainder has no figure, and no rule reads the doubled `n - d`",
    },
    Probe {
        id: "acquit: a conversion filed as a derivation",
        doc: Some(("assets/corpus/merge-holding-composition.xml",
                   "      <asrt:factor>\n        <pm:claim>\n          <pm:low>672</pm:low>\n          <pm:mostLikely>720</pm:mostLikely>\n          <pm:high>744</pm:high>\n          <pm:unit>GPU-hour per GPU</pm:unit>\n          <pm:denominator>\n            <pm:each>GPU</pm:each>\n          </pm:denominator>\n          <pm:narrowsWhen>\n            <pm:narrowing>\n              <pm:condition>the members bill on a fixed 30-day cycle instead of a calendar month</pm:condition>\n              <pm:kind>intervention</pm:kind>\n            </pm:narrowing>\n          </pm:narrowsWhen>\n          <pm:boundOrigin>\n            <pm:origin>intrinsic</pm:origin>\n          </pm:boundOrigin>\n          <pm:provenance><pm:party>holding-company</pm:party>\n            <pm:standing><pm:absent><pm:reason>unmeasured</pm:reason><pm:note>no standing vocabulary is published for this assertion</pm:note></pm:absent></pm:standing>\n          </pm:provenance>\n          <pm:asOf>2026-08-31</pm:asOf>\n        </pm:claim>\n      </asrt:factor>",
                   "      <asrt:factor>\n        <pm:derivation><pm:identity>conversionPath</pm:identity><pm:note>mutated: a factor nothing here computes</pm:note></pm:derivation>\n      </asrt:factor>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        // ⭐ `fit_domain` moves for the reason the first acquittal gives: `compute` is the one
        //   clearance layer that states its remainder quantity, and a factor with no figure
        //   leaves its remainder with none either.
        expect: Verdicts {
            rules: &[],
            laws: &[("fit_domain", "stated_quantity_is_not_the_magnitude")],
        },
        says: "a composer names the unit graph as the source of a GPU-to-GPU-hour factor: the sums it feeds are lifted under that name, and no reader multiplies by one",
    },
    // ---- refusals: states the grammar does not let a document spell ----
    Probe {
        id: "refuse: a search answered by a derivation",
        doc: Some(("assets/fixtures/every-elimination.xml",
                   "      <asrt:absent>\n        <pm:reason>unmeasured</pm:reason>\n        <pm:note>nobody checked whether these two parts double count. The fused figure may be\n                 out by an amount nobody knows, and saying so is strictly more than filing\n                 nothing</pm:note>\n      </asrt:absent>",
                   "      <pm:derivation>\n        <pm:identity>sharedParts</pm:identity>\n      </pm:derivation>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Refused,
        says: "whether anybody looked for double counting is nobody's output",
    },
    Probe {
        id: "refuse: couplings answered by a derivation",
        doc: Some(("assets/fixtures/every-absence.xml",
                   "    <pm:couplings>\n      <pm:absent>\n        <pm:reason>none</pm:reason>\n        <pm:note>stipulated: the oven was taken from one tray size to two over four weeks\n                 while the counter rota was held fixed, and the counter's service share did\n                 not move outside its filed range. Relief applied to one layer did not reach\n                 the other, which is what independence means and what the corpus has never\n                 actually tested</pm:note>\n      </pm:absent>\n    </pm:couplings>",
                   "    <pm:couplings>\n      <pm:derivation>\n        <pm:identity>fusionSum</pm:identity>\n      </pm:derivation>\n    </pm:couplings>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Refused,
        says: "whether anybody looked for couplings is nobody's output",
    },
    Probe {
        id: "refuse: a derivation nothing computes",
        doc: Some(("assets/fixtures/every-derived-quantity.xml",
                   "<pm:patience><pm:absent><pm:reason>unmeasured</pm:reason></pm:absent></pm:patience>",
                   "<pm:patience><pm:derivation><pm:identity>fusionSum</pm:identity></pm:derivation></pm:patience>",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Refused,
        says: "how long the people waiting will wait is a fact about them, and no identity computes it",
    },
    Probe {
        id: "refuse: an identity the position does not admit",
        doc: Some(("assets/fixtures/every-derived-quantity.xml",
                   "<pm:identity>fusionSum</pm:identity><pm:note>stipulated: the output of this layer's fusion",
                   "<pm:identity>magnitude</pm:identity><pm:note>stipulated: the output of this layer's fusion",
                   1)),
        rows: NO_ROWS,
        statement: NO_ROWS,
        swap: None,
        expect: Refused,
        says: "a composed demand is its fusion's sum, and no other identity computes it",
    },
];

/// The deepest a plan may nest and still be read back when a `query_file!` statement is checked:
/// sqlx decodes `EXPLAIN (VERBOSE, FORMAT JSON)` with serde_json, whose recursion limit refuses
/// the 128th nested container.
const PLAN_CEILING: usize = 127;

/// How deeply `[` and `{` nest in a JSON text, strings skipped.
fn json_depth(s: &str) -> usize {
    let (mut depth, mut deepest, mut in_string, mut escaped) = (0usize, 0usize, false, false);
    for c in s.chars() {
        if in_string {
            match (escaped, c) {
                (true, _) => escaped = false,
                (false, '\\') => escaped = true,
                (false, '"') => in_string = false,
                _ => {}
            }
            continue;
        }
        match c {
            '"' => in_string = true,
            '[' | '{' => {
                depth += 1;
                deepest = deepest.max(depth);
            }
            ']' | '}' => depth = depth.saturating_sub(1),
            _ => {}
        }
    }
    deepest
}

/// Every statement a target reads with `query_file!`, from the sources themselves, so a new one
/// is measured the day it is written.
fn statements_read_at_compile_time() -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    let mut stack = vec![PathBuf::from("examples"), PathBuf::from("tests"), PathBuf::from("src")];
    while let Some(dir) = stack.pop() {
        let Ok(entries) = fs::read_dir(&dir) else { continue };
        for e in entries.flatten() {
            let p = e.path();
            if p.is_dir() {
                stack.push(p);
            } else if p.extension().is_some_and(|x| x == "rs") {
                let src = fs::read_to_string(&p).unwrap_or_default();
                for (i, _) in src.match_indices("query_file!(") {
                    // The path must be the macro's first argument and a file: the programs that
                    // search their own source for this text hold it as a literal too.
                    let rest = src[i + "query_file!(".len()..].trim_start();
                    let Some(tail) = rest.strip_prefix('"') else { continue };
                    let Some(end) = tail.find('"') else { continue };
                    let path = &tail[..end];
                    if path.starts_with("assets/sql/") && path.ends_with(".sql") && Path::new(path).is_file() {
                        found.insert(path.to_string());
                    }
                }
            }
        }
    }
    found
}

/// Where the statements a probe edits are read from: the composition with every statement inline.
/// The tracked `assets/sql/` names a shared statement by its view, so an edit anchored inside one
/// would find nothing there; the inline form carries every statement's text in the file that runs.
const INLINE: &str = "target/sql-inline";

/// A composed statement as the body of a subquery: provenance lines and the final `;` removed.
fn body(sql: &str) -> String {
    sql.lines()
        .filter(|l| !l.trim_start().starts_with("--"))
        .collect::<Vec<_>>()
        .join("\n")
        .trim_end()
        .trim_end_matches(';')
        .to_string()
}

fn mutate_document(doc: &str, from_: &str, to: &str, nth: usize) -> Result<String, String> {
    let src = fs::read_to_string(doc).map_err(|e| format!("{doc}: {e}"))?;
    let found = src.matches(from_).count();
    if found < nth {
        return Err(format!(
            "its anchor occurs {found} time(s) in {doc} and it edits #{nth}. The document moved \
             under the probe; re-read it rather than adjusting the number."
        ));
    }
    let mut at = 0;
    for _ in 0..nth {
        at += src[at..].find(from_).unwrap() + 1;
    }
    at -= 1;
    Ok(format!("{}{}{}", &src[..at], to, &src[at + from_.len()..]))
}

fn well_formed(path: &Path) -> Result<bool, Box<dyn std::error::Error>> {
    Ok(Command::new("xmllint").arg("--noout").arg(path).output()?.status.success())
}

fn validates(path: &Path, mutant: &str) -> Result<bool, Box<dyn std::error::Error>> {
    let xsd = if mutant.contains("<asrt:") { "schema/assertion.xsd" } else { "schema/process-modulus.xsd" };
    Ok(Command::new("xmllint").args(["--noout", "--schema", xsd]).arg(path).output()?.status.success())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")
        .map_err(|_| "DATABASE_URL is unset. This example edits the loaded rows and rolls every edit back.")?;

    if !Path::new(INLINE).join("algebra/all.sql").is_file() {
        return Err(format!(
            "{INLINE}/ holds no composition. The probes edit statements inline; compose them with \
             `cargo sqlc compose --source assets/sqlc --target {INLINE} --skip-prepare`."
        )
        .into());
    }
    let inline = |name: &str| fs::read_to_string(format!("{INLINE}/{name}.sql"));
    let ingest = fs::read_to_string("assets/sql/ingest.sql")?;
    let checks = body(&inline("checks/all")?);
    let laws = body(&inline("algebra/all")?);
    let roster = body(&inline("checks/roster")?);
    let law_roster = body(&inline("algebra/roster")?);

    let dir = PathBuf::from("target/probes");
    fs::create_dir_all(&dir)?;
    let plans = dir.join("plans");
    fs::create_dir_all(&plans)?;

    println!("A law nobody has seen fail, and an acquittal nobody has run, are both prose.\n");

    let mut script = String::from("SET search_path TO pm, public;\n");
    let mut refused: BTreeMap<usize, bool> = BTreeMap::new();
    let mut problems: Vec<String> = Vec::new();

    for (i, p) in PROBES.iter().enumerate() {
        // The document, when the edit is one.
        let mut ingested = false;
        if let Some((doc, from_, to, nth)) = p.doc {
            let mutant = match mutate_document(doc, from_, to, nth) {
                Ok(m) => m,
                Err(e) => {
                    problems.push(format!("{}: {e}", p.id));
                    continue;
                }
            };
            let path = dir.join(format!("probe-{i}.xml"));
            fs::write(&path, &mutant)?;
            let ok = validates(&path, &mutant)?;
            if matches!(p.expect, Refused) {
                if !well_formed(&path)? {
                    problems.push(format!(
                        "{}: the mutant is not well-formed, so refusing it says nothing about the grammar",
                        p.id
                    ));
                    continue;
                }
                refused.insert(i, !ok);
                continue;
            }
            if !ok {
                problems.push(format!("{}: the mutant does not validate, so it acquits nothing", p.id));
                continue;
            }
            let abs = fs::canonicalize(&path)?;
            let one = ingest
                .replace(&format!("cat {doc}"), &format!("cat {}", abs.display()))
                .replace("COMMIT;", "");
            writeln!(script, "{one}")?;
            ingested = true;
        }
        if !ingested {
            writeln!(script, "BEGIN;")?;
        }
        writeln!(script, "SET CONSTRAINTS ALL DEFERRED;\n{}", p.rows)?;

        if matches!(p.expect, Verdicts { .. }) {
            writeln!(
                script,
                "SELECT 'p{i}', 'rule', rr.slug FROM ({checks}) v JOIN ({roster}) rr ON rr.rule = v.rule \
                 WHERE v.violates GROUP BY rr.slug;"
            )?;
            writeln!(
                script,
                "SELECT 'p{i}', 'law', l.law || ' | ' || coalesce(l.subject, '(no subject)') \
                 FROM ({laws}) l WHERE l.holds IS NOT TRUE;"
            )?;
        } else {
            let mut sql = body(&inline(p.statement)?);
            if let Some((from_, to, occurs)) = p.swap {
                let found = sql.matches(from_).count();
                if found != occurs {
                    problems.push(format!(
                        "{}: its anchor occurs {found} time(s) in {INLINE}/{}.sql and the probe \
                         says {occurs}. The relation moved under it; re-read the relation.",
                        p.id, p.statement
                    ));
                    writeln!(script, "ROLLBACK;\n")?;
                    continue;
                }
                sql = sql.replace(from_, to);
            }
            writeln!(
                script,
                "SELECT 'p{i}', CASE WHEN x.holds IS NOT TRUE THEN 'fails' ELSE 'holds' END, \
                 coalesce(x.subject, '(no subject)') FROM ({sql}) x WHERE x.law IS NOT NULL;"
            )?;
        }
        writeln!(script, "ROLLBACK;\n")?;
    }

    // The plans, each written to its own file so a text that spans lines stays one document.
    let statements = statements_read_at_compile_time();
    for (n, s) in statements.iter().enumerate() {
        let sql = fs::read_to_string(s)?;
        writeln!(
            script,
            "\\o {}\nEXPLAIN (VERBOSE, FORMAT JSON)\n{};\n\\o",
            plans.join(format!("{n}.json")).display(),
            body(&sql)
        )?;
    }

    let script_path = dir.join("probes.sql");
    fs::write(&script_path, &script)?;
    let psql = Command::new("psql")
        // examples/shared/database/mod.rs says why: a plan this deep costs more to compile
        // than to run.
        .env("PGOPTIONS", "-c jit=off")
        .arg(&url)
        .args(["-q", "-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-f"])
        .arg(&script_path)
        .output()?;
    if !psql.status.success() {
        eprintln!("{}", String::from_utf8_lossy(&psql.stderr));
        return Err(format!("psql failed. The script is at {}", script_path.display()).into());
    }

    // Rows are `p<i>|<kind>|<what>`.
    let mut seen: BTreeMap<usize, Vec<(String, String)>> = BTreeMap::new();
    for line in String::from_utf8_lossy(&psql.stdout).lines() {
        let mut f = line.splitn(3, '|');
        if let (Some(tag), Some(kind), Some(what)) = (f.next(), f.next(), f.next()) {
            if let Some(i) = tag.strip_prefix('p').and_then(|n| n.parse::<usize>().ok()) {
                seen.entry(i).or_default().push((kind.to_string(), what.to_string()));
            }
        }
    }

    println!("{:<48} {:<9} what the edit says", "probe", "verdict");
    let mut failed: Vec<&str> = Vec::new();
    for (i, p) in PROBES.iter().enumerate() {
        if problems.iter().any(|m| m.starts_with(&format!("{}:", p.id))) {
            continue;
        }
        let rows = seen.get(&i).cloned().unwrap_or_default();
        let fails: BTreeSet<String> =
            rows.iter().filter(|(k, _)| k == "fails").map(|(_, w)| w.clone()).collect();
        let held = rows.iter().any(|(k, _)| k == "holds");
        let (ok, note) = match &p.expect {
            Refused => {
                let r = refused.get(&i).copied().unwrap_or(false);
                (r, if r { "refused".to_string() } else { "ADMITTED".to_string() })
            }
            Only(want) => {
                let want: BTreeSet<String> = want.iter().map(|s| s.to_string()).collect();
                (fails == want, if fails == want { "fails".into() } else { format!("fails on {fails:?}") })
            }
            Includes(want) => {
                let ok = want.iter().all(|w| fails.contains(*w));
                (ok, if ok { format!("fails +{}", fails.len() - want.len()) } else { format!("fails on {fails:?}") })
            }
            AtLeastOne => (!fails.is_empty(), format!("fails {}", fails.len())),
            Verdicts { rules, laws } => {
                let got_rules: BTreeSet<String> =
                    rows.iter().filter(|(k, _)| k == "rule").map(|(_, w)| w.clone()).collect();
                let got_laws: BTreeSet<String> =
                    rows.iter().filter(|(k, _)| k == "law").map(|(_, w)| w.clone()).collect();
                let want_rules: BTreeSet<String> = rules.iter().map(|s| s.to_string()).collect();
                let want_laws: BTreeSet<String> =
                    laws.iter().map(|(l, s)| format!("{l} | {s}")).collect();
                let ok = got_rules == want_rules && got_laws == want_laws;
                (ok, if ok { "acquitted".into() } else { format!("rules {got_rules:?}, laws {got_laws:?}") })
            }
        };
        // A law probe whose statement returned nothing examined nothing, and proves nothing.
        let vacuous = !matches!(p.expect, Refused | Verdicts { .. }) && fails.is_empty() && !held;
        let ok = ok && !vacuous;
        if !ok {
            failed.push(p.id);
        }
        println!("{:<48} {:<9} {}", p.id, if ok { "ok" } else { "WRONG" }, p.says);
        if !ok {
            println!("{:<48} {:<9} {}", "", "", note);
        }
    }

    // ⭐⭐ THE LAWS NO PROBE HAS SEEN FAIL, read from the roster rather than listed here, so a law
    //    added tomorrow arrives unprobed instead of unnoticed.
    let unprobed: Vec<&str> = law_roster
        .lines()
        .filter_map(|l| l.trim().strip_prefix("('"))
        .filter_map(|l| l.split('\'').next())
        .filter(|slug| !PROBES.iter().any(|p| p.id == *slug || p.id.starts_with(&format!("{slug} /"))))
        .collect();
    println!(
        "\n{} of {} laws have been seen to fail here. Not yet: {}",
        law_roster.lines().filter(|l| l.trim().starts_with("('")).count() - unprobed.len(),
        law_roster.lines().filter(|l| l.trim().starts_with("('")).count(),
        unprobed.join(", ")
    );

    // The plans.
    let mut depths: Vec<(usize, &String)> = Vec::new();
    for (n, s) in statements.iter().enumerate() {
        let plan = fs::read_to_string(plans.join(format!("{n}.json")))?;
        depths.push((json_depth(&plan), s));
    }
    depths.sort_by(|a, b| b.0.cmp(&a.0).then(a.1.cmp(b.1)));
    println!(
        "\n{} statements are read at compile time. The deepest plans, against a ceiling of {PLAN_CEILING}:",
        depths.len()
    );
    for (d, s) in depths.iter().take(5) {
        println!("  {d:>4}  {:>3} to spare  {s}", PLAN_CEILING.saturating_sub(*d));
    }
    let over: Vec<&String> = depths.iter().filter(|(d, _)| *d > PLAN_CEILING).map(|(_, s)| *s).collect();

    for m in &problems {
        println!("⛔ {m}");
    }
    if !problems.is_empty() || !failed.is_empty() || !over.is_empty() {
        return Err(format!(
            "{} probe(s) could not be applied, {} did not come out as they say, and {} plan(s) \
             nest past what sqlx can read: {failed:?} {over:?}",
            problems.len(),
            failed.len(),
            over.len()
        )
        .into());
    }
    Ok(())
}
