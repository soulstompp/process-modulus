-- asrt:Fusion/asrt:Part against asrt:eliminations, via composition/owed_equality.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    -- the arithmetic the schemas' prose owes, against the unit rules that exist to make it mean anything.
SELECT * FROM (VALUES
  ('remainder',          'r = n - d',                    'demand x nameplate',              NULL),
  ('shares_sum',         'sum of shares = |r|',          'holder shares x remainder',       NULL),
  ('shares_bounded',     'sum of shares <= S',           'holder shares x absorbing slack', 'slack_unit_mismatch'),
  ('whole_multiple',     'n mod q = 0',                  'nameplate x quantum',             'quantum_unit_mismatch'),
  ('draw_bounded',       'draw <= n + capacity slack',   'draw x nameplate x slack',        NULL),
  ('exposure_bounded',   'exposure <= unserved shares',  'remainder x unserved shares',     NULL),
  ('time_slack_derived', 'time slack = q / clearance',   'quantum x remainder',             NULL),
  ('filed_remainder',    'filed r = n - d',              'remainder quantity x remainder',  NULL),
  ('fusion_sum',         'x_composed = F.Phi.x - e',     'parts x factors x elimination',   '(forbidden)')
) AS a(slug, site, operands, guarded_by)

) a
LEFT JOIN (
    SELECT f.filing, f.layer,
           CASE WHEN o.filing IS NULL THEN 'suspended'
                ELSE 'computable' END AS verdict,
           CASE WHEN o.filing IS NULL
                     THEN format('no equality is owed: %s', s.suspended_because)
                ELSE 'the sum is owed exactly' END AS detail
    FROM      (
        -- distinct (composition, composedLayerName) over asrt:Fusion/asrt:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p

    ) f
    LEFT JOIN (
        -- composition/fusions.sqlc minus the suspensions that lift the demand sum.
SELECT f.filing, f.layer, 'demand' AS quantity
FROM (
    -- distinct (composition, composedLayerName) over asrt:Fusion/asrt:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p

) f
EXCEPT
SELECT s.composition, s.composed_layer, 'demand'
FROM (
    -- composition/suspension_grounds.sqlc projected onto the fusion it suspends.
SELECT DISTINCT g.composition, g.composed_layer, g.quantity
FROM (
    -- the three filings that lift the sum rule, one row per GROUND, carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::text AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) es
WHERE es.answer = 'unmeasured'
UNION ALL
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
WHERE e.absent IS NOT NULL
UNION ALL
-- asrt:Part/asrt:factor taking its pm:absent branch, as a suspension of the composed sum.
SELECT p.composition, p.composed_layer,
       NULL::text AS quantity,
       'the conversion was filed and could not be sized' AS suspended_because,
       p.factor_absent::text AS note
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
WHERE p.factor_absent IS NOT NULL


) g

) s
WHERE s.quantity IS NULL OR s.quantity = 'demand'

    ) o USING (filing, layer)
    -- ⛔ THE GROUNDS ARE A BAG, so they are folded to one row per fusion before the join. A
    --   fusion suspended on two grounds is suspended once, and joining the bag would emit it
    --   twice. `composition/suspended_fusions.sqlc` is the set; this site needs the REASONS
    --   as well, so it folds them here rather than reaching for the projection.
    LEFT JOIN (
        SELECT g.composition, g.composed_layer,
               string_agg(DISTINCT g.suspended_because, '; ' ORDER BY g.suspended_because)
                   AS suspended_because
        FROM (
            -- the three filings that lift the sum rule, one row per GROUND, carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::text AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) es
WHERE es.answer = 'unmeasured'
UNION ALL
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
WHERE e.absent IS NOT NULL
UNION ALL
-- asrt:Part/asrt:factor taking its pm:absent branch, as a suspension of the composed sum.
SELECT p.composition, p.composed_layer,
       NULL::text AS quantity,
       'the conversion was filed and could not be sized' AS suspended_because,
       p.factor_absent::text AS note
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
WHERE p.factor_absent IS NOT NULL


        ) g
        WHERE coalesce(g.quantity, 'demand') = 'demand'
        GROUP BY g.composition, g.composed_layer
    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
) p ON true
WHERE a.slug = 'fusion_sum'
