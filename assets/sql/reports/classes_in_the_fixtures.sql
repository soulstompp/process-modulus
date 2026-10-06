-- reports/class_census.sqlc at fixtures scope.
-- epistemics/class_cells.sqlc counted per class, restricted by the caller's @scope.
WITH arithmetic_roster AS (
-- the arithmetic the schemas' prose owes, against the unit rules that exist to make it mean
-- anything.
SELECT * FROM (VALUES
  ('remainder',          'the remainder is the nameplate less the demand',
                         'demand and nameplate',              NULL),
  ('shares_sum',         'the shares add up to the size of the remainder',
                         'holder shares and remainder',       NULL),
  ('shares_bounded',     'the shares add up to no more than the absorbing slack',
                         'holder shares and absorbing slack', 'slack_unit_mismatch'),
  ('whole_multiple',     'the nameplate is a whole number of quanta',
                         'nameplate and quantum',             'quantum_unit_mismatch'),
  ('draw_bounded',       'the draw is no more than the nameplate plus its capacity slack',
                         'draw, nameplate and slack',         NULL),
  ('exposure_bounded',   'the exposure is no more than the unserved shares',
                         'remainder and unserved shares',     NULL),
  ('time_slack_derived', 'the time slack is the nameplate less the demand, never below zero',
                         'demand and nameplate',              NULL),
  ('filed_remainder',    'a filed remainder is the nameplate less the demand',
                         'remainder quantity and remainder',  NULL),
  ('fusion_sum',         'a composed figure is its converted parts added up, less its eliminations',
                         'parts, factors and elimination',    '(forbidden)')
) AS a(slug, site, operands, guarded_by)
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
arithmetic_remainder AS (
-- composition/resolved_quantities.sqlc's demand against its nameplate, before layers/remainder.sqlc
-- drops either, with composition/figureless_remainders.sqlc for a layer whose totals do not give
-- its remainder.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.low IS NULL OR n.low IS NULL   THEN 'suspended'::public.arithmetic_verdict
                WHEN d.unit IS DISTINCT FROM n.unit   THEN 'not comparable'::public.arithmetic_verdict
                WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.low IS NULL AND n.low IS NULL
                     THEN format('demand %s and nameplate %s', d.why, n.why)
                WHEN d.low IS NULL THEN format('demand %s', d.why)
                WHEN n.low IS NULL THEN format('nameplate %s', n.why)
                WHEN d.unit IS DISTINCT FROM n.unit
                     THEN format('%s against %s', d.unit, n.unit)
                WHEN g.filing IS NOT NULL
                     THEN 'a conversion with width scales both totals, and the composed remainder is lifted'
                ELSE format('both in %s', d.unit) END AS detail
    FROM      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition_resolved_quantities ) q
    ) d
    JOIN      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition_resolved_quantities ) q
    ) n ON n.filing = d.filing AND n.layer = d.layer AND n.quantity = 'nameplate'
    LEFT JOIN (
        SELECT * FROM composition_figureless_remainders
    ) g ON g.filing = d.filing AND g.layer = d.layer
    WHERE d.quantity = 'demand'
) p ON true
WHERE a.slug = 'remainder'
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
entries_holder_totals AS (
-- entries/holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                     AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)  AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                              AS shares_low,
       sum(h.share_mode)                             AS shares_mode,
       sum(h.share_high)                             AS shares_high,
       array_agg(DISTINCT h.share_unit)              AS share_units
FROM (
    SELECT * FROM entries_holders
) h
GROUP BY h.filing, h.layer
),
arithmetic_shares_sum AS (
-- pm:Remainder/pm:holder against the layer the magnitude belongs to.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT r.filing, r.layer,
           CASE WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[r.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('%s holders, %s unstated%s', h.holders, h.unstated,
                  CASE WHEN h.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', h.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers_remainder
    ) r
    JOIN      (
        SELECT * FROM entries_holder_totals
    ) h USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_sum'
),
layers_absorber AS (
-- pm:Remainder/absorber, resolved through pm.buffer_term.
SELECT l.filing, l.layer,
       l.absorber_taxonomy AS taxonomy,
       l.absorber_value    AS term,
       bt.buffer,
       bt.note AS the_readers_warrant
FROM pm.layer l
JOIN pm.buffer_term bt ON bt.taxonomy = l.absorber_taxonomy AND bt.value = l.absorber_value
),
entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack;
-- the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
),
entries_absorbing_slack AS (
-- layers/absorber.sqlc joined to entries/slacks.sqlc on the buffer the layer actually names.
SELECT a.filing, a.layer, a.buffer,
       a.taxonomy, a.term, a.the_readers_warrant,
       s.low, s.mode, s.high, s.unit, s.absent, s.sized
FROM      (
    SELECT * FROM layers_absorber
) a
JOIN      (
    SELECT * FROM entries_slacks
) s USING (filing, layer, buffer)
),
entries_served_holders AS (
-- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('booked', 'counterparty', 'people')
),
folds_served_totals AS (
-- entries/served_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                                 AS served_low,
       sum(h.share_mode)                                AS served_mode,
       sum(h.share_high)                                AS served_high,
       array_agg(DISTINCT h.share_unit)                 AS share_units,
       string_agg(DISTINCT h.kind::text, ' and ')       AS kinds
FROM (
    SELECT * FROM entries_served_holders
) h
GROUP BY h.filing, h.layer
),
layers_pressed AS (
-- pm:Remainder/sign in {interference, transition}.
SELECT r.*
FROM (
    SELECT * FROM layers_remainder
) r
WHERE r.sign IN ('interference', 'transition')
),
arithmetic_shares_bounded AS (
-- the slack named by pm:Remainder/pm:absorber, against the served pm:Remainder/pm:holder under
-- interference.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT s.filing, s.layer,
           CASE WHEN s.mode IS NULL                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[s.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN s.mode IS NULL
                     THEN format('the %s buffer is %s', s.buffer, s.absent)
                WHEN h.unstated > 0
                     THEN format('%s of %s shares unstated%s, against a %s slack of %s',
                                 h.unstated, h.holders,
                                 CASE WHEN h.derived > 0
                                      THEN format(' (%s of them filed as `sharesSum`''s output, which nothing here computes)', h.derived)
                                      ELSE '' END,
                                 s.buffer, s.mode)
                ELSE format('%s shares bounded by a %s slack of %s',
                            h.holders, s.buffer, s.mode)
           END AS detail
    FROM      (
        SELECT * FROM entries_absorbing_slack
    ) s
    JOIN      (
        SELECT * FROM folds_served_totals
    ) h USING (filing, layer)
    JOIN      (
        SELECT DISTINCT r.filing, r.layer
        FROM (
            SELECT * FROM layers_pressed
        ) r
        WHERE r.sign = 'interference'
    ) x USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_bounded'
),
layers_lumpy AS (
-- layers/figures.sqlc where the nameplate is lumpy, the demand beside it where stated.
SELECT f.filing, f.layer,
       f.n_low, f.n_mode, f.n_high, f.n_unit AS amount_unit,
       f.quantum_low, f.quantum_mode, f.quantum_high, f.quantum_unit, f.quantum_absent,
       f.d_low, f.d_mode, f.d_high, f.d_unit AS unit
FROM (
    SELECT * FROM layers_figures
) f
WHERE f.lumpy
),
arithmetic_whole_multiple AS (
-- pm:Divisibility/pm:quantum against pm:Nameplate/pm:amount.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.quantum_mode IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN l.quantum_unit IS DISTINCT FROM l.amount_unit     THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.quantum_mode IS NULL THEN format('quantum %s', l.quantum_absent)
                ELSE format('%s of %s against a rating in %s',
                            l.quantum_mode, l.quantum_unit, l.amount_unit) END AS detail
    FROM (
        SELECT * FROM layers_lumpy
    ) l
) p ON true
WHERE a.slug = 'whole_multiple'
),
layers_drawn AS (
-- pm:Jagged/pm:draw from composition/resolved_quantities.sqlc, against layers/nameplate.sqlc
-- and entries/slacks.sqlc's capacity slack.
SELECT dr.filing, dr.layer,
       dr.low  AS draw_low,
       dr.mode AS draw_mode,
       dr.high AS draw_high,
       dr.unit AS draw_unit,
       n.low   AS n_low,
       n.mode  AS n_mode,
       n.high  AS n_high,
       n.unit  AS n_unit,
       s.low    AS capacity_low,
       s.mode   AS capacity_slack,
       s.high   AS capacity_high,
       s.unit   AS capacity_unit,
       s.absent AS capacity_absent
FROM      (
    SELECT q.filing, q.layer, q.low, q.mode, q.high, q.unit
    FROM ( SELECT * FROM composition_resolved_quantities ) q
    WHERE q.quantity = 'draw'
      AND q.low IS NOT NULL
) dr
JOIN      (
    SELECT n.filing, n.layer, n.n_low AS low, n.n_mode AS mode, n.n_high AS high, n.n_unit AS unit
    FROM ( SELECT * FROM layers_nameplate ) n
) n ON n.filing = dr.filing AND n.layer = dr.layer
LEFT JOIN (
    SELECT * FROM entries_slacks
) s ON s.filing = dr.filing AND s.layer = dr.layer AND s.buffer = 'capacity'
),
arithmetic_draw_bounded AS (
-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.capacity_slack IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit       THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.capacity_slack IS NULL
                     THEN format('the capacity buffer is %s', d.capacity_absent)
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit
                     THEN format('a draw in %s against a rating in %s and a slack in %s',
                                 d.draw_unit, d.n_unit, d.capacity_unit)
                ELSE format('draw, rating and slack all in %s', d.n_unit) END AS detail
    FROM (
        SELECT * FROM layers_drawn
    ) d
) p ON true
WHERE a.slug = 'draw_bounded'
),
layers_absorption AS (
-- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack,
-- summed across the layer in the demand's unit.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE (s.sized AND s.unit IS NOT DISTINCT FROM d.d_unit)
                    OR s.absent = 'notApplicable')                                 AS absorbable,
       count(*)
         FILTER (WHERE (NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable')
                    OR (s.sized AND s.unit IS DISTINCT FROM d.d_unit))        AS unknown
FROM      (
    SELECT * FROM entries_slacks
) s
LEFT JOIN (
    SELECT * FROM layers_demand
) d ON d.filing = s.filing AND d.layer = s.layer
GROUP BY s.filing, s.layer
),
layers_exposure_scope AS (
-- layers/remainder.sqlc where exposure > 0, classified by layers/absorption.sqlc.
SELECT r.*, a.absorbable, a.unknown,
       CASE WHEN a.unknown    > 0 THEN 'a buffer nobody sized'::public.exposure_standing
            WHEN a.absorbable > 0 THEN 'a buffer with room in it'::public.exposure_standing
            ELSE                       'every buffer sized and empty'::public.exposure_standing END AS standing
FROM      (
    SELECT * FROM layers_remainder
) r
JOIN      (
    SELECT * FROM layers_absorption
) a USING (filing, layer)
WHERE r.exposure > 1e-9
),
layers_unabsorbed_exposure AS (
-- layers/exposure_scope.sqlc, restricted to the standing that licenses a conclusion.
SELECT s.*
FROM (
    SELECT * FROM layers_exposure_scope
) s
WHERE s.standing = 'every buffer sized and empty'
),
entries_unserved_holders AS (
-- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('customer', 'unrealised')
),
entries_unserved_totals AS (
-- entries/unserved_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_high IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                                 AS unserved_low,
       sum(h.share_mode)                                AS unserved_mode,
       sum(h.share_high)                                AS unserved_high,
       array_agg(DISTINCT h.share_unit)                 AS share_units
FROM (
    SELECT * FROM entries_unserved_holders
) h
GROUP BY h.filing, h.layer
),
arithmetic_exposure_bounded AS (
-- every slack on the layer accounted for and empty, against pm:Remainder/pm:holder of kind customer
-- and unrealised.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT x.filing, x.layer,
           CASE WHEN u.unstated > 0                        THEN 'suspended'::public.arithmetic_verdict
                WHEN u.share_units <> ARRAY[x.unit]        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('exposure %s in %s against %s unserved holder(s)%s',
                  round(x.exposure, 3), x.unit, u.holders,
                  CASE WHEN u.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', u.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers_unabsorbed_exposure
    ) x
    JOIN      (
        SELECT * FROM entries_unserved_totals
    ) u USING (filing, layer)
) p ON true
WHERE a.slug = 'exposure_bounded'
),
layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
),
entries_derived_time_slacks AS (
-- pm:Layer/pm:timeSlack filed as a clearance derivation, beside pm:Divisibility/pm:window.
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    SELECT * FROM layers_windows
) w
JOIN      (
    SELECT * FROM entries_slacks
) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.derivation = 'clearance'
),
arithmetic_time_slack_derived AS (
-- pm:Layer/pm:timeSlack with pm:absent/reason = derived, against the clearance it stands for.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT t.filing, t.layer,
           CASE WHEN r.filing IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN r.unit IS DISTINCT FROM r.amount_unit        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN r.filing IS NULL THEN 'no demand and nameplate to take a clearance from'
                WHEN r.unit IS DISTINCT FROM r.amount_unit
                     THEN format('a demand in %s against a nameplate in %s', r.unit, r.amount_unit)
                ELSE format('the clearance [%s, %s, %s] %s is the slack',
                            greatest(r.r_low, 0), greatest(r.r_mode, 0), greatest(r.r_high, 0),
                            r.unit) END AS detail
    FROM      (
        SELECT * FROM entries_derived_time_slacks
    ) t
    LEFT JOIN (
        SELECT * FROM layers_remainder
    ) r USING (filing, layer)
) p ON true
WHERE a.slug = 'time_slack_derived'
),
layers_filed_against_derived AS (
-- layers/filed_remainders.sqlc against layers/remainder.sqlc, on the layer they share.
SELECT l.filing, l.layer,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent, l.qty_derivation,
       r.r_low, r.r_mode, r.r_high, r.unit,
       r.m_low, r.m_mode, r.m_high,
       r.d_low, r.d_mode, r.d_high,
       r.n_low, r.n_mode, r.n_high, r.amount_unit,
       r.sign, r.derived_fit
FROM      (
    SELECT * FROM layers_filed_remainders
) l
JOIN      (
    SELECT * FROM layers_remainder
) r USING (filing, layer)
),
arithmetic_filed_remainder AS (
-- pm:Remainder/pm:quantity against the size of the layer's remainder in force, via
-- layers/filed_against_derived.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.qty_derivation IS NOT NULL            THEN 'computable'::public.arithmetic_verdict
                WHEN l.qty_low IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN l.qty_unit IS DISTINCT FROM l.unit      THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.qty_derivation IS NOT NULL
                     THEN format('filed as the `%s` derivation, which works out to %s %s',
                                 l.qty_derivation, round(l.m_mode, 3), l.unit)
                WHEN l.qty_low IS NULL THEN format('the quantity is %s', l.qty_absent)
                ELSE format('filed %s %s against a derived magnitude %s %s',
                            l.qty_mode, l.qty_unit, round(l.m_mode, 3), l.unit) END AS detail
    FROM      (
        SELECT * FROM layers_filed_against_derived
    ) l
) p ON true
WHERE a.slug = 'filed_remainder'
),
composition_underived_parts AS (
-- composition/parts.sqlc whose figure composition/derived_quantities.sqlc cannot compute, per
-- fusion.
SELECT p.composition, p.composed_layer, d.quantity,
       'a part files the quantity derived and it cannot be computed' AS suspended_because,
       string_agg(p.part_filing || '/' || p.part_layer || ': ' || d.blocked_because, ', '
                  ORDER BY p.part_filing, p.part_layer) AS note
FROM      (
    SELECT * FROM composition_parts
) p
JOIN      (
    SELECT * FROM composition_derived_quantities
) d ON d.filing = p.part_filing AND d.layer = p.part_layer
WHERE d.low IS NULL
GROUP BY p.composition, p.composed_layer, d.quantity
),
composition_suspension_grounds AS (
-- the grounds that lift the sum rule: those read off the filing, and a derived part that cannot
-- be computed.
SELECT * FROM composition_filed_grounds
UNION ALL
SELECT * FROM composition_underived_parts
),
composition_suspended_fusions AS (
-- composition/suspension_grounds.sqlc reduced to the fusion it suspends.
SELECT DISTINCT g.composition, g.composed_layer, g.quantity
FROM (
    SELECT * FROM composition_suspension_grounds
) g
),
composition_suspended_quantities AS (
-- composition/suspended_fusions.sqlc spread over pm.summed_quantity.
SELECT DISTINCT s.composition, s.composed_layer, q.quantity
FROM      (
    SELECT * FROM composition_suspended_fusions
) s
JOIN      unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
       ON s.quantity IS NULL OR s.quantity = q.quantity
),
composition_derived_fusions AS (
-- composition/fusion_quantities.sqlc filed as a derivation.
SELECT q.filing, q.layer, q.quantity
FROM (
    SELECT * FROM composition_fusion_quantities
) q
WHERE q.derivation IS NOT NULL
),
composition_owed_equality AS (
-- composition/fusions.sqlc for every quantity, minus the suspensions that lift each sum and the
-- composed figures filed `derived`.
SELECT f.filing, f.layer, q.quantity
FROM      (
    SELECT * FROM composition_fusions
) f
CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
EXCEPT
(
    SELECT s.composition, s.composed_layer, s.quantity
    FROM (
        SELECT * FROM composition_suspended_quantities
    ) s
    UNION
    SELECT d.filing, d.layer, d.quantity
    FROM (
        SELECT * FROM composition_derived_fusions
    ) d
)
),
arithmetic_fusion_sum AS (
-- asrt:Fusion/asrt:Part against asrt:eliminations, via composition/owed_equality.sqlc and
-- composition/derived_quantities.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT f.filing, f.layer,
           CASE WHEN o.owed IS NULL AND d.computed IS NOT TRUE
                THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           concat_ws('; ',
                     CASE WHEN o.owed IS NOT NULL THEN format('owed exactly for %s', o.owed) END,
                     d.derived,
                     s.suspended) AS detail
    FROM      (
        SELECT * FROM composition_fusions
    ) f
    LEFT JOIN (
        SELECT o.filing, o.layer, string_agg(o.quantity::text, ', ' ORDER BY o.quantity) AS owed
        FROM (
            SELECT * FROM composition_owed_equality
        ) o
        GROUP BY o.filing, o.layer
    ) o USING (filing, layer)
    LEFT JOIN (
        SELECT g.composition, g.composed_layer,
               string_agg(DISTINCT format('suspended for %s: %s',
                                          coalesce(g.quantity::text, 'every quantity'),
                                          g.suspended_because), '; ') AS suspended
        FROM (
            SELECT * FROM composition_suspension_grounds
        ) g
        GROUP BY g.composition, g.composed_layer
    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
    LEFT JOIN (
        SELECT d.filing, d.layer, bool_or(q.low IS NOT NULL) AS computed,
               string_agg(CASE WHEN q.low IS NOT NULL
                               THEN format('derived for %s: computed [%s, %s, %s]', d.quantity,
                                           q.low, q.mode, q.high)
                               ELSE format('derived for %s, not computable: %s', d.quantity,
                                           q.blocked_because) END,
                          '; ' ORDER BY d.quantity) AS derived
        FROM      (
            SELECT * FROM composition_derived_fusions
        ) d
        JOIN      (
            SELECT * FROM composition_derived_quantities
        ) q ON q.filing = d.filing AND q.layer = d.layer AND q.quantity = d.quantity
        GROUP BY d.filing, d.layer
    ) d ON d.filing = f.filing AND d.layer = f.layer
) p ON true
WHERE a.slug = 'fusion_sum'
),
arithmetic_all AS (
-- arithmetic/roster.sqlc joined to each site's own population.
SELECT * FROM arithmetic_remainder
UNION ALL
SELECT * FROM arithmetic_shares_sum
UNION ALL
SELECT * FROM arithmetic_shares_bounded
UNION ALL
SELECT * FROM arithmetic_whole_multiple
UNION ALL
SELECT * FROM arithmetic_draw_bounded
UNION ALL
SELECT * FROM arithmetic_exposure_bounded
UNION ALL
SELECT * FROM arithmetic_time_slack_derived
UNION ALL
SELECT * FROM arithmetic_filed_remainder
UNION ALL
SELECT * FROM arithmetic_fusion_sum
),
epistemics_scopes AS (
-- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss
),
epistemics_coupling_searches AS (
-- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
),
entries_couplings AS (
-- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c
),
layers_every_layer AS (
-- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l
),
entries_spillovers AS (
-- pm:couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    SELECT * FROM entries_couplings
) c
JOIN      (
    SELECT * FROM layers_every_layer
) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    SELECT * FROM layers_every_layer
) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    SELECT * FROM epistemics_coupling_searches
) s  ON s.filing = b.filing
LEFT JOIN (
    SELECT * FROM epistemics_scopes
) sc ON sc.filing = b.filing
),
layers_remainder_scope AS (
-- layers/remainder.sqlc against pm:Stack/pm:scope, pm:couplings/pm:absent
-- and entries/spillovers.sqlc.
SELECT r.filing, r.layer,
       sc.extent,
       cs.answer AS search,
       sp.observed_in AS spilled_from,
       CASE WHEN sp.observed_in IS NOT NULL THEN 'takes a spillover'::public.remainder_standing
            WHEN sc.extent = 'unbounded'    THEN 'nobody bounded the set'::public.remainder_standing
            WHEN cs.answer  = 'unmeasured'  THEN 'set bounded, pairs untested'::public.remainder_standing
            ELSE 'bounded and the pairs answered'::public.remainder_standing END AS standing
FROM      (
    SELECT * FROM layers_remainder
) r
LEFT JOIN (
    SELECT * FROM epistemics_scopes
) sc ON sc.filing = r.filing
LEFT JOIN (
    SELECT * FROM epistemics_coupling_searches
) cs ON cs.filing = r.filing
LEFT JOIN ( SELECT DISTINCT borne_by, from_layer, observed_in FROM (
    SELECT * FROM entries_spillovers
) x ) sp ON sp.borne_by = r.filing AND sp.from_layer = r.layer
),
checks_fit_axes AS (
-- the fit axis each rule on checks/roster.sqlc reads, declared.
SELECT * FROM (VALUES
  ('fit_disagrees',                        'filed against derived'::public.fit_axis),
  ('shares_do_not_sum',                    'derived fit'),
  ('stated_quantity_is_not_the_magnitude', 'derived fit'),
  ('nobody_named_as_unserved',             'derived fit'),
  ('exposure_unaccounted',                 'derived fit'),
  ('share_exceeds_slack',                  'filed sign'),
  ('slack_unit_mismatch',                  'not read'),
  ('quantum_unit_mismatch',                'not read'),
  ('nameplate_not_a_multiple',             'not read'),
  ('draw_exceeds_the_supply',              'not read'),
  ('clearance_with_unserved',              'filed sign'),
  ('unresolved_part',                      'not read'),
  ('jagged_layer',                         'not read'),
  ('layers_move_together',                 'not read'),
  ('coupling_does_not_attenuate',          'not read'),
  ('narrows_a_point_value',                'not read'),
  ('range_says_no_range',                  'not read'),
  ('bound_fell_with_no_range',             'not read'),
  ('identity_does_not_compute_the_claim',  'not read'),
  ('window_lost_or_summed',                'not read'),
  ('derived_slack_over_a_window',          'not read'),
  ('window_not_applicable_on_a_rate',      'not read'),
  ('window_size_not_applicable',           'not read'),
  ('elimination_not_applicable_with_parts','not read'),
  ('fusion_sum_disagrees',                 'not read'),
  ('local_part_dangles',                   'not read'),
  ('unit_crossing_without_a_factor',       'not read'),
  ('regime_crossing_without_a_citation',   'not read'),
  ('part_regime_disagrees',                'not read'),
  ('conversion_cycle_does_not_close',      'not read'),
  ('one_part_fusion_alters_its_part',      'not read'),
  ('denied_remainder_is_not_contradicted', 'not read')
) AS a(slug, axis)
),
checks_fit_domain AS (
-- the declared standing of each rule on checks/fit_axes.sqlc in each cell of its axis.
SELECT * FROM (VALUES
  ('fit_disagrees', 'clearance'::pm.fit, 'exercised'::public.fit_standing, NULL::text),
  ('fit_disagrees', 'transition',   'exercised', NULL),
  ('fit_disagrees', 'interference', 'exercised', NULL),
  ('fit_disagrees', NULL,           'outside',
   'layers/signed.sqlc reads layers/remainder.sqlc, which needs a demand and a nameplate to derive the fit a filed sign is compared with'),

  ('shares_do_not_sum', 'clearance',    'exercised', NULL),
  ('shares_do_not_sum', 'transition',   'open',
   'a transition whose shares sum to the magnitude of its larger side is a legitimate filing; nothing loaded states shares on a transition'),
  ('shares_do_not_sum', 'interference', 'exercised', NULL),
  ('shares_do_not_sum', NULL,           'outside',
   'the magnitude the shares sum to comes from layers/remainder.sqlc, which needs a demand and a nameplate'),

  ('stated_quantity_is_not_the_magnitude', 'clearance',    'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'transition',   'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'interference', 'open',
   'a remainder under interference may state its quantity; nothing loaded does'),
  ('stated_quantity_is_not_the_magnitude', NULL,           'outside',
   'layers/filed_against_derived.sqlc compares against the magnitude layers/remainder.sqlc derives from a demand and a nameplate'),

  ('nobody_named_as_unserved', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none: nothing went unserved'),
  ('nobody_named_as_unserved', 'transition',   'exercised', NULL),
  ('nobody_named_as_unserved', 'interference', 'exercised', NULL),
  ('nobody_named_as_unserved', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('exposure_unaccounted', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none'),
  ('exposure_unaccounted', 'transition',   'open',
   'refutation/compute reaches it with every buffer empty, and the rule suspends because its unserved share is unmeasured; a transition stating every unserved share would be examined'),
  ('exposure_unaccounted', 'interference', 'exercised', NULL),
  ('exposure_unaccounted', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('share_exceeds_slack', 'clearance',    'outside',
   'layers/pressed.sqlc keeps a filed interference or transition'),
  ('share_exceeds_slack', 'transition',   'outside',
   'entries/borne.sqlc keeps interference alone: under a transition the shares and the slack bound opposite edges of one buffer'),
  ('share_exceeds_slack', 'interference', 'open',
   'a served share under interference, every served share stated, whose absorbing buffer states its slack; every such layer loaded leaves that slack unsized'),
  ('share_exceeds_slack', NULL,           'outside',
   'layers/pressed.sqlc keeps a filed sign'),

  ('clearance_with_unserved', 'clearance',    'exercised', NULL),
  ('clearance_with_unserved', 'transition',   'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', 'interference', 'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', NULL,           'outside',
   'its population is a filed clearance')
) AS d(slug, fit, standing, reason)
),
layers_quantities AS (
-- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand'::public.layer_quantity AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    SELECT * FROM layers_demand
) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::public.layer_quantity,
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    SELECT * FROM layers_nameplate
) n
UNION ALL
SELECT s.filing, s.layer, (s.buffer || 'Slack')::public.layer_quantity,
       s.low, s.mode, s.high, s.unit
FROM (
    SELECT * FROM entries_slacks
) s
WHERE s.low IS NOT NULL
),
epistemics_class_cells AS (
-- every declared class of every classification, LEFT JOINed to the rows that landed in it.
SELECT 'arithmetic/all.sqlc' AS relation, (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)) AS codomain,
       c.class::text AS class, c.ord,
       z.site || ' / ' || z.filing || ' / ' || z.layer AS ball,
       z.filing AS filing
FROM unnest(enum_range(NULL::public.arithmetic_verdict)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM arithmetic_all
) z ON z.verdict = c.class
UNION ALL
SELECT 'layers/remainder_scope.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::public.remainder_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers_remainder_scope
) z ON z.standing = c.class
UNION ALL
SELECT 'layers/exposure_scope.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::public.exposure_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers_exposure_scope
) z ON z.standing = c.class
UNION ALL
SELECT 'layers/remainder.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::pm.fit)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers_remainder
) z ON z.derived_fit = c.class
UNION ALL
SELECT 'checks/fit_axes.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.slug, NULL
FROM unnest(enum_range(NULL::public.fit_axis)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM checks_fit_axes
) z ON z.axis = c.class
UNION ALL
SELECT 'checks/fit_domain.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.slug || ' / ' || coalesce(z.fit::text, 'no fit'), NULL
FROM unnest(enum_range(NULL::public.fit_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM checks_fit_domain
) z ON z.standing = c.class
UNION ALL
SELECT 'composition/part_references.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.composition || ' / ' || z.composed_layer || ' / ' || z.part_filing || ' / ' || z.part_layer,
       z.composition
FROM unnest(enum_range(NULL::public.factor_state)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM composition_part_references
) z ON z.factor_state = c.class
UNION ALL
SELECT 'layers/quantities.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer || ' / ' || z.quantity::text, z.filing
FROM unnest(enum_range(NULL::public.layer_quantity)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers_quantities
) z ON z.quantity = c.class
),
epistemics_class_sets AS (
-- every classification, its type, what each counts, and whether it is filed.
SELECT * FROM (VALUES
  ('arithmetic/all.sqlc',              'arithmetic_verdict', 'computation', true),
  ('layers/remainder.sqlc',            'fit',                'layer',       true),
  ('layers/remainder_scope.sqlc',      'remainder_standing', 'layer',       true),
  ('layers/exposure_scope.sqlc',       'exposure_standing',  'layer',       true),
  ('layers/quantities.sqlc',           'layer_quantity',     'quantity',    true),
  ('composition/part_references.sqlc', 'factor_state',       'part',        true),
  ('checks/fit_axes.sqlc',             'fit_axis',           'rule',        false),
  ('checks/fit_domain.sqlc',           'fit_standing',       'rule cell',   false)
) AS s(relation, codomain, subject, filed)
),
scope_fixtures AS (
-- from pm.filing where evidence = 'stipulation'; see assets/fixtures/README.md.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'stipulation'
)
SELECT k.relation, k.class, s.subject, count(w.filing) AS balls, k.ord
FROM      (
    SELECT * FROM epistemics_class_cells
) k
JOIN      (
    SELECT * FROM epistemics_class_sets
) s ON s.relation = k.relation AND s.filed
LEFT JOIN (
    SELECT * FROM scope_fixtures
) w ON w.filing = k.filing
GROUP BY k.relation, k.class, s.subject, k.ord
ORDER BY k.relation, k.ord

