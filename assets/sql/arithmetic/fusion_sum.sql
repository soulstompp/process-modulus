-- asrt:Fusion/asrt:Part against asrt:Eliminations, via composition/owed_equality.sqlc.
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
        -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p

    ) f
    LEFT JOIN (
        -- composition/fusions.sqlc minus the suspensions that lift the demand sum.
SELECT f.filing, f.layer, 'demand' AS quantity
FROM (
    -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p

) f
EXCEPT
SELECT s.composition, s.composed_layer, 'demand'
FROM (
    -- the two filings that lift the sum rule, each carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::text AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
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
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
WHERE e.absent IS NOT NULL


) s
WHERE s.quantity IS NULL OR s.quantity = 'demand'

    ) o USING (filing, layer)
    LEFT JOIN (
        -- the two filings that lift the sum rule, each carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::text AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
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
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
WHERE e.absent IS NOT NULL


    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
       AND coalesce(s.quantity, 'demand') = 'demand'
) p ON true
WHERE a.slug = 'fusion_sum'
