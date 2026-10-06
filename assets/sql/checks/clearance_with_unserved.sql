-- pm:Remainder/sign = clearance against pm:HolderKind customer/unrealised.
WITH checks_roster AS (
-- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees', 'layer', 'sign agrees with the range comparison'),
  ('shares_do_not_sum', 'layer', 'stated shares sum to the magnitude'),
  ('stated_quantity_is_not_the_magnitude', 'layer', 'a stated remainder quantity is the magnitude'),
  ('nobody_named_as_unserved', 'layer', 'a supply with nowhere to put its excess names who went unserved, and under interference names nobody else'),
  ('exposure_unaccounted', 'layer', 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack', 'layer', 'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch', 'slack', 'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch', 'layer', 'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple', 'layer', 'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply', 'layer', 'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved', 'layer', 'a clearance fit rules out customer and unrealised'),
  ('unresolved_part', 'part', 'a part reference resolves to a filing that is here'),
  ('jagged_layer', 'layer', 'a fusion''s parts do not overlap'),
  ('layers_move_together', 'layer', 'layers that always move together are one layer'),
  ('coupling_does_not_attenuate', 'layer', 'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value', 'claim', 'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range', 'claim', 'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range', 'claim', 'a point value does not say its bound is where the measurements fell'),
  ('identity_does_not_compute_the_claim', 'claim', 'a claim''s edge or narrowing derives from an identity that computes the claim''s own position'),
  ('window_lost_or_summed', 'part', 'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window', 'layer', 'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate', 'layer', 'a window is notApplicable only where the unit has no period under the line'),
  ('window_size_not_applicable', 'layer', 'a window that files its live part does not call that part''s size malformed'),
  ('elimination_not_applicable_with_parts', 'layer', 'a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees', 'layer', 'a composed figure equals the sum of its converted parts less its eliminations, per quantity'),
  ('local_part_dangles', 'part', 'a local part names a layer in its own stack'),
  ('unit_crossing_without_a_factor', 'layer', 'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'part', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees', 'part', 'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close', 'layer', 'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part', 'part', 'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted', 'layer', 'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, subject, rule)
),
layers_summed_quantities AS (
-- pm:Layer/pm:Demand, pm:Nameplate/pm:amount and pm:Jagged/pm:draw, one row per quantity.
SELECT l.filing, l.layer, 'demand'::pm.summed_quantity AS quantity,
       l.demand_low AS low, l.demand_mode AS mode, l.demand_high AS high, l.demand_unit AS unit,
       l.demand_absent AS absent, l.demand_derivation AS derivation
FROM pm.layer l
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::pm.summed_quantity,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_derivation
FROM pm.nameplate n
UNION ALL
SELECT n.filing, n.layer, 'draw'::pm.summed_quantity,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent, n.draw_derivation
FROM pm.nameplate n
),
composition_part_references AS (
-- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p
),
folds_fusion_parts AS (
-- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM composition_part_references
) r
GROUP BY r.composition, r.composed_layer
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
composition_parts AS (
-- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition_part_references
) p
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer
),
composition_fusions AS (
-- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f
),
composition_derived_frontier AS (
-- layers/summed_quantities.sqlc filed as a derivation, walked through composition/parts.sqlc while
-- the node's figure is derived too.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition_parts
),
figure AS (
    SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation,
           (f.filing IS NOT NULL) AS is_fusion
    FROM      (
        SELECT * FROM layers_summed_quantities
    ) s
    LEFT JOIN (
        SELECT * FROM composition_fusions
    ) f ON f.filing = s.filing AND f.layer = s.layer
),
walk(root_filing, root_layer, quantity, filing, layer, depth,
     factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
     conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion) AS (
        SELECT r.filing, r.layer, r.quantity, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation'), p.composed_layer,
               p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      figure r
        JOIN      resolved p ON p.composition = r.filing AND p.composed_layer = r.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = r.quantity
        WHERE r.derivation IS NOT NULL
    UNION ALL
        SELECT w.root_filing, w.root_layer, w.quantity, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation'),
               p.composed_layer, p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      walk w
        JOIN      resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = w.quantity
        WHERE w.derivation IS NOT NULL
) CYCLE filing, layer SET is_cycle USING route
SELECT root_filing, root_layer, quantity, filing, layer, depth,
       factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
       conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion, is_cycle
FROM walk
),
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
),
composition_unresolved_parts AS (
-- composition/part_references.sqlc less composition/parts.sqlc, per fusion and reference.
SELECT r.composition, r.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'a part resolves to no filing here' AS suspended_because,
       r.part_filing || '/' || r.part_layer AS note
FROM      (
    SELECT * FROM composition_part_references
) r
LEFT JOIN (
    SELECT * FROM composition_parts
) p ON  p.composition    = r.composition
    AND p.composed_layer = r.composed_layer
    AND p.part_notation  = r.part_filing
    AND p.part_layer     = r.part_layer
WHERE p.composition IS NULL
),
composition_derived_quantities AS (
-- composition/derived_frontier.sqlc summed at the nodes stating the figure, less
-- eliminations/filed.sqlc at the root and each derived node passed.
WITH
root AS (
    SELECT s.filing, s.layer, s.quantity, s.derivation, coalesce(b.parts, 0) AS parts
    FROM      ( SELECT * FROM layers_summed_quantities ) s
    LEFT JOIN (
        SELECT * FROM folds_fusion_parts
    ) b ON b.composition = s.filing AND b.composed_layer = s.layer
    WHERE s.derivation IS NOT NULL
),
node AS (
    SELECT w.root_filing, w.root_layer, w.quantity, w.filing, w.layer, w.depth,
           w.factor_low, w.factor_mode, w.factor_high, w.part_of, w.conversion_absent,
           w.conversion_derivation, w.is_cycle,
           w.low, w.mode, w.high, w.unit, w.absent, w.derivation, w.is_fusion
    FROM ( SELECT * FROM composition_derived_frontier ) w
),
passed AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity, r.filing, r.layer,
           1::numeric AS factor_low, 1::numeric AS factor_mode, 1::numeric AS factor_high,
           false AS below
    FROM root r
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity, n.filing, n.layer,
           n.factor_low, n.factor_mode, n.factor_high, true
    FROM node n
    WHERE n.derivation IS NOT NULL AND n.is_fusion AND NOT n.is_cycle
),
elimination AS (
    SELECT p.root_filing, p.root_layer, p.quantity, p.filing, p.layer, p.below,
           least(   e.low  * p.factor_low, e.low  * p.factor_high) AS e_low,
           e.mode * p.factor_mode                                  AS e_mode,
           greatest(e.high * p.factor_low, e.high * p.factor_high) AS e_high,
           e.absent AS e_absent, e.derivation AS e_derivation,
           es.answer AS searched
    FROM      passed p
    LEFT JOIN ( SELECT * FROM eliminations_filed ) e
           ON e.composition = p.filing AND e.composed_layer = p.layer AND e.quantity = p.quantity
    LEFT JOIN ( SELECT * FROM eliminations_searched ) es
           ON es.composition = p.filing AND es.composed_layer = p.layer
),
unresolved AS MATERIALIZED (
    SELECT DISTINCT u.composition, u.composed_layer
    FROM ( SELECT * FROM composition_unresolved_parts ) u
),
reason AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity,
           format('no fusion here builds `%s`', r.layer) AS why
    FROM root r
    WHERE r.parts = 0
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           CASE WHEN n.is_cycle THEN format('the walk closes a cycle at `%s`', n.layer)
                WHEN n.low IS NULL AND n.derivation IS NULL
                     THEN format('`%s` files its %s %s', n.layer, n.quantity,
                                 coalesce(n.absent::text, 'nowhere'))
                ELSE format('`%s` files its %s as its fusion''s sum and no fusion builds it',
                            n.layer, n.quantity) END
    FROM node n
    WHERE n.is_cycle
       OR (n.low IS NULL AND (n.derivation IS NULL OR NOT n.is_fusion))
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           format('the conversion of `%s` into `%s` is %s', n.layer, n.part_of,
                  coalesce(n.conversion_absent::text,
                           format('filed as `%s`, and no computation of it is wired in',
                                  n.conversion_derivation)))
    FROM node n
    WHERE n.conversion_absent IS NOT NULL OR n.conversion_derivation IS NOT NULL
    UNION ALL
    SELECT e.root_filing, e.root_layer, e.quantity,
           CASE WHEN e.searched = 'unmeasured'
                THEN format('`%s` never searched for double counting', e.layer)
                ELSE format('the %s elimination at `%s` is %s', e.quantity, e.layer,
                            coalesce(e.e_absent::text,
                                     format('filed as `%s`, and no computation of it is wired in',
                                            e.e_derivation))) END
    FROM elimination e
    WHERE e.searched = 'unmeasured' OR e.e_absent IS NOT NULL OR e.e_derivation IS NOT NULL
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('a part of `%s` resolves to no filing here', p.layer)
    FROM passed p
    JOIN unresolved u ON u.composition = p.filing AND u.composed_layer = p.layer
),
level AS (
    SELECT r.filing, r.layer, r.quantity, r.derivation,
           coalesce(st.x_low, 0)  - coalesce(pb.e_low, 0)  AS s_low,
           coalesce(st.x_mode, 0) - coalesce(pb.e_mode, 0) AS s_mode,
           coalesce(st.x_high, 0) - coalesce(pb.e_high, 0) AS s_high,
           coalesce(er.e_low, 0) AS e_low, coalesce(er.e_mode, 0) AS e_mode,
           coalesce(er.e_high, 0) AS e_high,
           st.unit
    FROM root r
    LEFT JOIN (
        SELECT n.root_filing, n.root_layer, n.quantity,
               sum(least(   n.low  * n.factor_low, n.low  * n.factor_high)) AS x_low,
               sum(n.mode * n.factor_mode)                                  AS x_mode,
               sum(greatest(n.high * n.factor_low, n.high * n.factor_high)) AS x_high,
               CASE WHEN count(DISTINCT n.unit) = 1
                         AND bool_and(n.factor_low = 1 AND n.factor_high = 1)
                    THEN min(n.unit) END AS unit
        FROM node n
        WHERE n.low IS NOT NULL
        GROUP BY n.root_filing, n.root_layer, n.quantity
    ) st ON st.root_filing = r.filing AND st.root_layer = r.layer AND st.quantity = r.quantity
    LEFT JOIN (
        SELECT e.root_filing, e.root_layer, e.quantity,
               sum(e.e_low) AS e_low, sum(e.e_mode) AS e_mode, sum(e.e_high) AS e_high
        FROM elimination e
        WHERE e.below
        GROUP BY e.root_filing, e.root_layer, e.quantity
    ) pb ON pb.root_filing = r.filing AND pb.root_layer = r.layer AND pb.quantity = r.quantity
    LEFT JOIN elimination er
           ON er.root_filing = r.filing AND er.root_layer = r.layer AND er.quantity = r.quantity
          AND NOT er.below
),
inverts AS (
    SELECT l.filing, l.layer, l.quantity,
           (l.s_low <= l.s_mode AND l.s_mode <= l.s_high) AS own
    FROM level l
    WHERE NOT (l.s_low - l.e_low <= l.s_mode - l.e_mode AND l.s_mode - l.e_mode <= l.s_high - l.e_high)
),
blocked AS (
    SELECT root_filing, root_layer, quantity, why FROM reason
    UNION ALL
    SELECT i.filing, i.layer, i.quantity,
           CASE WHEN i.own
                THEN format('the %s elimination at `%s` is wider than its sum and inverts it',
                            i.quantity, i.layer)
                ELSE format('an elimination below `%s` inverts the %s sum', i.layer, i.quantity) END
    FROM inverts i
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('the %s elimination at `%s` is wider than its sum and inverts it', p.quantity, p.layer)
    FROM passed p
    JOIN inverts i ON i.filing = p.filing AND i.layer = p.layer AND i.quantity = p.quantity
    WHERE p.below
)
SELECT l.filing, l.layer, l.quantity, l.derivation,
       CASE WHEN b.why IS NULL THEN l.s_low  - l.e_low  END AS low,
       CASE WHEN b.why IS NULL THEN l.s_mode - l.e_mode END AS mode,
       CASE WHEN b.why IS NULL THEN l.s_high - l.e_high END AS high,
       CASE WHEN b.why IS NULL THEN l.unit END AS unit,
       b.why AS blocked_because
FROM level l
LEFT JOIN (
    SELECT root_filing, root_layer, quantity, string_agg(DISTINCT why, '; ' ORDER BY why) AS why
    FROM blocked
    GROUP BY root_filing, root_layer, quantity
) b ON b.root_filing = l.filing AND b.root_layer = l.layer AND b.quantity = l.quantity
),
composition_resolved_quantities AS (
-- layers/summed_quantities.sqlc where no derivation is filed, beside
-- composition/derived_quantities.sqlc where one is.
SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent,
       false                  AS derived,
       s.derivation,
       NULL::text             AS blocked_because
FROM (
    SELECT * FROM layers_summed_quantities
) s
WHERE s.derivation IS NULL
UNION ALL
SELECT d.filing, d.layer, d.quantity, d.low, d.mode, d.high, d.unit,
       NULL::pm.absence_reason,
       d.low IS NOT NULL,
       d.derivation,
       d.blocked_because
FROM (
    SELECT * FROM composition_derived_quantities
) d
),
layers_demand AS (
-- composition/resolved_quantities.sqlc's pm:Layer/pm:Demand, where it has a figure.
SELECT q.filing, q.layer,
       q.low  AS d_low,
       q.mode AS d_mode,
       q.high AS d_high,
       q.unit AS d_unit,
       q.low = q.high AS is_a_point,
       q.derived AS d_derived
FROM (
    SELECT * FROM composition_resolved_quantities
) q
WHERE q.quantity = 'demand'
  AND q.low IS NOT NULL
),
layers_nameplate AS (
-- pm:Layer/pm:Nameplate, its Divisibility and its window, with the amount from
-- composition/derived_quantities.sqlc where it is filed `derived`.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       false AS n_derived,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL
UNION ALL
SELECT n.filing, n.layer, q.low, q.mode, q.high, q.unit, true,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM pm.nameplate n
JOIN (
    SELECT * FROM composition_derived_quantities
) q ON q.filing = n.filing AND q.layer = n.layer AND q.quantity = 'nameplate'
WHERE q.low IS NOT NULL
),
layers_figures AS (
-- layers/demand.sqlc and layers/nameplate.sqlc on the layer, each side where it has a figure.
SELECT filing, layer,
       d.d_low, d.d_mode, d.d_high, d.d_unit, d.is_a_point, d.d_derived,
       n.n_low, n.n_mode, n.n_high, n.n_unit, n.n_derived,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM      (
    SELECT * FROM layers_demand
) d
FULL JOIN (
    SELECT * FROM layers_nameplate
) n USING (filing, layer)
),
layers_filed_remainders AS (
-- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value, l.absorber_absent,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       l.sign_derivation, l.qty_derivation
FROM pm.layer l
WHERE l.remainder_absent IS NULL
),
layers_differenced_remainder AS (
-- layers/figures.sqlc where both figures are present, beside the sign and absorber of
-- layers/filed_remainders.sqlc.
SELECT x.filing, x.layer,
       f.sign, f.sign_absent,
       f.absorber_taxonomy, f.absorber_value, f.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.d_unit AS unit,
       x.n_low, x.n_mode, x.n_high, x.n_unit AS amount_unit,
       x.n_low  - x.d_high AS r_low,   -- crossed: the least nameplate against the most demand
       x.n_mode - x.d_mode AS r_mode,
       x.n_high - x.d_low  AS r_high,
       CASE WHEN x.n_low  - x.d_high >= 0 THEN 'clearance'::pm.fit
            WHEN x.n_high - x.d_low  <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(x.d_high - x.n_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit
FROM      (
    SELECT * FROM layers_figures
) x
LEFT JOIN (
    SELECT * FROM layers_filed_remainders
) f USING (filing, layer)
WHERE x.d_low IS NOT NULL
  AND x.n_low IS NOT NULL
),
composition_unsettled AS (
-- composition/parts.sqlc restricted to the parts whose factor has width or no figure.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    SELECT * FROM composition_parts
) p
WHERE p.factor_state IN ('absent', 'derivation')
   OR (p.factor_state = 'stated' AND p.factor_low <> p.factor_high)
),
composition_remainder_frontier AS (
-- composition/parts.sqlc walked while composition/unsettled.sqlc holds, carrying the product.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition_parts
),
open_node AS (
    SELECT * FROM composition_unsettled
),
frontier(root_filing, root_layer, filing, layer, depth,
         factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation')
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation')
        FROM frontier w
        JOIN open_node o ON o.filing = w.filing AND o.layer = w.layer
        JOIN resolved p  ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT f.root_filing, f.root_layer, f.filing, f.layer, f.depth,
       f.factor_low, f.factor_mode, f.factor_high, f.factor_absent, f.is_cycle,
       (NOT f.factor_absent AND NOT f.is_cycle) AS usable
FROM frontier f
),
composition_settled_remainders AS (
-- composition/remainder_frontier.sqlc less the nodes composition/unsettled.sqlc names,
-- against layers/differenced_remainder.sqlc at the node the walk stops on.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer,
       w.filing AS node_filing, w.layer AS node_layer, w.depth,
       w.factor_low, w.factor_mode, w.factor_high,
       least(   r.r_low  * w.factor_low, r.r_low  * w.factor_high) AS r_low,
       r.r_mode * w.factor_mode                                    AS r_mode,
       greatest(r.r_high * w.factor_low, r.r_high * w.factor_high) AS r_high,
       (w.factor_low IS DISTINCT FROM w.factor_high)               AS spread_factor
FROM      (
    SELECT * FROM composition_remainder_frontier
) w
JOIN      (
    SELECT * FROM layers_differenced_remainder
) r ON r.filing = w.filing AND r.layer = w.layer
LEFT JOIN (
    SELECT * FROM composition_unsettled
) o ON o.filing = w.filing AND o.layer = w.layer
WHERE w.usable
  AND o.filing IS NULL
),
composition_passed_nodes AS (
-- composition/remainder_frontier.sqlc restricted to the nodes composition/unsettled.sqlc names.
SELECT w.*
FROM      (
    SELECT * FROM composition_remainder_frontier
) w
JOIN      (
    SELECT * FROM composition_unsettled
) u ON u.filing = w.filing AND u.layer = w.layer
),
eliminations_unsearched AS (
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    SELECT * FROM eliminations_searched
) es
WHERE es.answer = 'unmeasured'
),
eliminations_unsized AS (
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per
-- quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       CASE WHEN e.derivation IS NOT NULL
            THEN format('the elimination is filed as `%s`, and no computation of it is wired into '
                        'the sum', e.derivation)
            ELSE 'the overlap was found and could not be sized' END AS suspended_because,
       e.reason AS note
FROM (
    SELECT * FROM eliminations_filed
) e
WHERE e.absent IS NOT NULL OR e.derivation IS NOT NULL
),
composition_unsized_conversions AS (
-- asrt:Part/asrt:factor taking its pm:absent or pm:derivation branch, as a suspension of the
-- composed sum.
SELECT p.composition, p.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       CASE WHEN p.factor_state = 'derivation'
            THEN format('the conversion is filed as `%s`, and no computation of it is wired into '
                        'the sum', p.factor_derivation)
            ELSE 'the conversion was filed and could not be sized' END AS suspended_because,
       coalesce(p.factor_absent::text, p.factor_derivation::text) AS note
FROM (
    SELECT * FROM composition_parts
) p
WHERE p.factor_state IN ('absent', 'derivation')
),
composition_fusion_quantities AS (
-- composition/fusions.sqlc joined to layers/summed_quantities.sqlc on the composed layer.
SELECT f.filing, f.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation
FROM      (
    SELECT * FROM composition_fusions
) f
JOIN      (
    SELECT * FROM layers_summed_quantities
) s ON s.filing = f.filing AND s.layer = f.layer
),
composition_unstated_quantities AS (
-- layers/summed_quantities.sqlc without a figure on a part or on the composed layer, and not a
-- derivation, per fusion.
SELECT u.composition, u.composed_layer, u.quantity,
       'the quantity is not stated on every layer the sum reads' AS suspended_because,
       string_agg(u.layer || ' ' || coalesce(u.absent::text, 'unstated'), ', ' ORDER BY u.layer)
           AS note
FROM (
    SELECT p.composition, p.composed_layer, s.quantity,
           p.part_filing || '/' || p.part_layer AS layer, s.absent
    FROM      (
        SELECT * FROM composition_parts
    ) p
    JOIN      (
        SELECT * FROM layers_summed_quantities
    ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
    WHERE s.low IS NULL
      AND s.derivation IS NULL
    UNION ALL
    SELECT q.filing, q.layer, q.quantity, 'the composed layer', q.absent
    FROM (
        SELECT * FROM composition_fusion_quantities
    ) q
    WHERE q.low IS NULL
      AND q.derivation IS NULL
) u
GROUP BY u.composition, u.composed_layer, u.quantity
),
composition_filed_grounds AS (
-- the five grounds decided by what is filed, one row per ground, carrying the quantity it lifts.
SELECT * FROM eliminations_unsearched
UNION ALL
SELECT * FROM eliminations_unsized
UNION ALL
SELECT * FROM composition_unsized_conversions
UNION ALL
SELECT * FROM composition_unstated_quantities
UNION ALL
SELECT * FROM composition_unresolved_parts
),
composition_suspended_remainders AS (
-- composition/filed_grounds.sqlc kept to the two quantities the remainder is built from, at the
-- layer or a node its walk passes; composition/resolved_quantities.sqlc without a demand or
-- nameplate figure at the layer or a node the walk reaches.
SELECT DISTINCT t.root_filing AS composition, t.root_layer AS composed_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM composition_fusions
    ) f
    UNION ALL
    SELECT w.root_filing, w.root_layer, w.filing, w.layer
    FROM (
        SELECT * FROM composition_passed_nodes
    ) w
) t
JOIN      (
    SELECT * FROM composition_filed_grounds
) s ON s.composition = t.filing AND s.composed_layer = t.layer
WHERE s.quantity IS NULL
   OR s.quantity IN ('demand', 'nameplate')
UNION
SELECT w.root_filing, w.root_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM composition_fusions
    ) f
    UNION ALL
    SELECT r.root_filing, r.root_layer, r.filing, r.layer
    FROM (
        SELECT * FROM composition_remainder_frontier
    ) r
) w
JOIN      (
    SELECT * FROM composition_resolved_quantities
) q ON q.filing = w.filing AND q.layer = w.layer
WHERE q.quantity IN ('demand', 'nameplate')
  AND q.low IS NULL
),
composition_owed_remainder AS (
-- composition/fusions.sqlc less composition/suspended_remainders.sqlc.
SELECT f.filing, f.layer
FROM      (
    SELECT * FROM composition_fusions
) f
LEFT JOIN (
    SELECT * FROM composition_suspended_remainders
) s ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL
),
composition_converted AS (
-- asrt:Part/asrt:factor applied to each quantity the part layer states.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, s.quantity,
       least(   s.low  * coalesce(p.factor_low, 1), s.low  * coalesce(p.factor_high, 1)) AS low,
       s.mode * coalesce(p.factor_mode, 1)                                               AS mode,
       greatest(s.high * coalesce(p.factor_low, 1), s.high * coalesce(p.factor_high, 1)) AS high
FROM      (
    SELECT * FROM composition_parts
) p
JOIN      (
    SELECT * FROM composition_resolved_quantities
) s
       ON s.filing = p.part_filing AND s.layer = p.part_layer
  AND s.low IS NOT NULL
  AND p.factor_state IN ('omitted', 'stated')
),
folds_part_sums AS (
-- composition/converted.sqlc folded to one row per composed layer and quantity.
SELECT c.composition, c.composed_layer, c.quantity,
       sum(c.low)  AS sum_low,
       sum(c.mode) AS sum_mode,
       sum(c.high) AS sum_high,
       count(*)    AS parts
FROM (
    SELECT * FROM composition_converted
) c
GROUP BY c.composition, c.composed_layer, c.quantity
),
eliminations_paired AS (
-- eliminations/filed.sqlc against folds/part_sums.sqlc.
SELECT x.composition, x.composed_layer, x.quantity,
       x.low, x.mode, x.high, x.unit, x.absent, x.derivation, x.reason, x.claim_seq, x.crossed,
       CASE WHEN x.crossed THEN x.high ELSE x.low  END AS at_low,
       CASE WHEN x.crossed THEN x.low  ELSE x.high END AS at_high
FROM (
    SELECT e.composition, e.composed_layer, e.quantity,
           e.low, e.mode, e.high, e.unit, e.absent, e.derivation, e.reason, e.claim_seq,
           coalesce(NOT (s.sum_low  - e.low  <= s.sum_mode - e.mode
                     AND s.sum_mode - e.mode <= s.sum_high - e.high), false) AS crossed
    FROM      (
        SELECT * FROM eliminations_filed
    ) e
    LEFT JOIN (
        SELECT * FROM folds_part_sums
    ) s ON s.composition = e.composition AND s.composed_layer = e.composed_layer
       AND s.quantity = e.quantity
) x
),
composition_carried_eliminations AS (
-- eliminations/paired.sqlc at the nodes composition/passed_nodes.sqlc names, along a usable path.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer, e.quantity,
       count(*)                                                        AS through_layers,
       sum(least(   e.at_low  * w.factor_low, e.at_low  * w.factor_high)) AS e_low,
       sum(e.mode * w.factor_mode)                                     AS e_mode,
       sum(greatest(e.at_high * w.factor_low, e.at_high * w.factor_high)) AS e_high,
       bool_or(e.absent IS NOT NULL OR e.derivation IS NOT NULL)       AS unsized
FROM      (
    SELECT * FROM composition_passed_nodes
) w
JOIN      (
    SELECT * FROM eliminations_paired
) e ON e.composition = w.filing AND e.composed_layer = w.layer
WHERE w.usable
GROUP BY w.root_filing, w.root_layer, e.quantity
),
composition_fused_remainders AS (
-- composition/settled_remainders.sqlc summed over the settled frontier, less
-- eliminations/paired.sqlc at their own corners.
SELECT y.composition, y.composed_layer,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_low  ELSE y.r_low  - y.n_high + y.d_low  END AS pivoted_low,
       y.pivoted_mode,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_high ELSE y.r_high - y.n_low  + y.d_high END AS pivoted_high,
       y.derived_low, y.derived_mode, y.derived_high, y.derived_fit, y.unit, y.parts, y.spread
FROM (
    SELECT x.*,
           x.r_low  - x.n_at_low
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_low  ELSE x.d_at_high END AS paired_low,
           x.r_mode - x.n_mode + x.d_mode                                            AS pivoted_mode,
           x.r_high - x.n_at_high
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_high ELSE x.d_at_low  END AS paired_high,
           least(x.n_at_low, x.n_at_high)    AS n_low,
           greatest(x.n_at_low, x.n_at_high) AS n_high,
           least(x.d_at_low, x.d_at_high)    AS d_low,
           greatest(x.d_at_low, x.d_at_high) AS d_high
    FROM (
        SELECT c.composition, c.composed_layer,
               sum(c.r_low)  AS r_low,
               sum(c.r_mode) AS r_mode,
               sum(c.r_high) AS r_high,
               bool_or(c.spread_factor) AS spread,
               coalesce(max(e.n_at_low),  0) + coalesce(max(k.n_low),  0) AS n_at_low,
               coalesce(max(e.n_mode),    0) + coalesce(max(k.n_mode), 0) AS n_mode,
               coalesce(max(e.n_at_high), 0) + coalesce(max(k.n_high), 0) AS n_at_high,
               coalesce(max(e.d_at_low),  0) + coalesce(max(k.d_low),  0) AS d_at_low,
               coalesce(max(e.d_mode),    0) + coalesce(max(k.d_mode), 0) AS d_mode,
               coalesce(max(e.d_at_high), 0) + coalesce(max(k.d_high), 0) AS d_at_high,
               max(d.r_low)  AS derived_low,
               max(d.r_mode) AS derived_mode,
               max(d.r_high) AS derived_high,
               max(d.derived_fit) AS derived_fit,
               max(d.unit)   AS unit,
               count(*)      AS parts
        FROM      (
            SELECT * FROM composition_settled_remainders
        ) c
        JOIN      (
            SELECT * FROM composition_owed_remainder
        ) o  ON o.filing = c.composition AND o.layer = c.composed_layer
        JOIN      (
            SELECT * FROM layers_differenced_remainder
        ) d  ON d.filing = c.composition AND d.layer = c.composed_layer
        LEFT JOIN (
            SELECT p.composition, p.composed_layer,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'nameplate') AS n_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'nameplate') AS n_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'nameplate') AS n_at_high,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'demand')    AS d_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'demand')    AS d_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'demand')    AS d_at_high
            FROM (
                SELECT * FROM eliminations_paired
            ) p
            GROUP BY p.composition, p.composed_layer
        ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
        LEFT JOIN (
            SELECT w.composition, w.composed_layer,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'nameplate') AS n_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'nameplate') AS n_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'nameplate') AS n_high,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'demand')    AS d_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'demand')    AS d_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'demand')    AS d_high
            FROM (
                SELECT * FROM composition_carried_eliminations
            ) w
            GROUP BY w.composition, w.composed_layer
        ) k ON k.composition = c.composition AND k.composed_layer = c.composed_layer
        GROUP BY c.composition, c.composed_layer
    ) x
) y
),
composition_figureless_remainders AS (
-- composition/unsettled.sqlc within composition/suspended_remainders.sqlc.
SELECT o.filing, o.layer
FROM      (
    SELECT * FROM composition_unsettled
) o
JOIN      (
    SELECT * FROM composition_suspended_remainders
) l ON l.composition = o.filing AND l.composed_layer = o.layer
),
layers_remainder AS (
-- layers/differenced_remainder.sqlc, overridden by composition/fused_remainders.sqlc where a
-- composed layer owes an exact remainder, less composition/figureless_remainders.sqlc.
SELECT x.filing, x.layer,
       x.sign, x.sign_absent,
       x.absorber_taxonomy, x.absorber_value, x.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.unit,
       x.n_low, x.n_mode, x.n_high, x.amount_unit,
       x.r_low, x.r_mode, x.r_high,
       CASE WHEN x.r_low  >= 0 THEN 'clearance'::pm.fit
            WHEN x.r_high <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(-x.r_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit,
       x.pivoted,
       CASE WHEN x.r_low <= 0 AND x.r_high >= 0 THEN 0
            ELSE least(abs(x.r_low), abs(x.r_high)) END AS m_low,
       abs(x.r_mode)                                    AS m_mode,
       greatest(abs(x.r_low), abs(x.r_high))            AS m_high
FROM (
    SELECT b.filing, b.layer,
           b.sign, b.sign_absent,
           b.absorber_taxonomy, b.absorber_value, b.absorber_absent,
           b.d_low, b.d_mode, b.d_high, b.unit,
           b.n_low, b.n_mode, b.n_high, b.amount_unit,
           coalesce(f.pivoted_low,  b.r_low)  AS r_low,
           coalesce(f.pivoted_mode, b.r_mode) AS r_mode,
           coalesce(f.pivoted_high, b.r_high) AS r_high,
           b.lumpy, b.quantum_mode, b.quantum_unit,
           (f.pivoted_low IS NOT NULL) AS pivoted
    FROM      (
        SELECT * FROM layers_differenced_remainder
    ) b
    LEFT JOIN (
        SELECT * FROM composition_fused_remainders
    ) f ON f.composition = b.filing AND f.composed_layer = b.layer
    WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition_figureless_remainders ) g
                      WHERE g.filing = b.filing AND g.layer = b.layer)
) x
),
entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
),
entries_unserved_holders AS (
-- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('customer', 'unrealised')
)
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT r.filing, r.layer,
           u.kind IS NOT NULL AS violates,
           format('%s holder under a clearance fit', h.kind) AS detail
    FROM      (
        SELECT * FROM layers_remainder
    ) r
    JOIN      (
        SELECT * FROM entries_holders
    ) h USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM entries_unserved_holders
    ) u USING (filing, layer, kind)
    WHERE r.sign = 'clearance'
) p ON true
WHERE r.slug = 'clearance_with_unserved'
