-- asrt:Fusion/asrt:Part summed against the composed pm:Layer/pm:Demand, via composition/fused.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    -- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees',                        'sign agrees with the range comparison'),
  ('shares_do_not_sum',                    'stated shares sum to the magnitude'),
  ('nobody_named_as_unserved',             'a supply with nowhere to put its excess names who went unserved'),
  ('exposure_unaccounted',                 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack',                  'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch',                  'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch',                'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple',             'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply',              'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved',              'a clearance fit rules out customer and unrealised'),
  ('unresolved_part',                      'a part reference resolves to a filing that is here'),
  ('leaf_reached_twice',                   'no leaf layer is reachable through two paths'),
  ('coupling_does_not_attenuate',          'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value',                'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range',                  'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range',             'a point value does not say its bound is where the measurements fell'),
  ('window_lost_or_summed',                'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window',          'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate',      'a window is notApplicable only where the unit has no period under the line'),
  ('elimination_not_applicable_with_parts','a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees',                 'a composed demand equals the sum of its converted parts less its eliminations'),
  ('local_part_dangles',                   'a local part names a layer in its own stack'),
  ('local_cycle',                          'local parts do not cycle'),
  ('denied_remainder_is_not_contradicted',
                                          'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, rule)

) r
LEFT JOIN (
    SELECT f.composition AS filing, f.composed_layer AS layer,
           NOT f.agrees AS violates,
           format('parts less eliminations give [%s, %s, %s]; the filing states [%s, %s, %s]',
                  f.computed_low, f.computed_mode, f.computed_high,
                  f.filed_low, f.filed_mode, f.filed_high) AS detail
    FROM (
        -- pm:Fusion/pm:Part against the composed pm:Layer/pm:Demand, less pm:Eliminations.
SELECT c.composition, c.composed_layer,
       'demand' AS quantity,
       sum(c.d_low)  - coalesce(max(e.low),  0) AS computed_low,
       sum(c.d_mode) - coalesce(max(e.mode), 0) AS computed_mode,
       sum(c.d_high) - coalesce(max(e.high), 0) AS computed_high,
       max(d.d_low)  AS filed_low,
       max(d.d_mode) AS filed_mode,
       max(d.d_high) AS filed_high,
       (sum(c.d_low)  - coalesce(max(e.low),  0) = max(d.d_low)
    AND sum(c.d_mode) - coalesce(max(e.mode), 0) = max(d.d_mode)
    AND sum(c.d_high) - coalesce(max(e.high), 0) = max(d.d_high)) AS agrees
FROM      (
    -- asrt:Part/asrt:factor applied to the part layer's pm:Demand.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       'demand' AS quantity,
       d.d_low  * coalesce(p.factor_low, 1)  AS d_low,
       d.d_mode * coalesce(p.factor_mode, 1) AS d_mode,
       d.d_high * coalesce(p.factor_high, 1) AS d_high
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
       ON d.filing = p.part_filing AND d.layer = p.part_layer

) c
JOIN      (
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

) o
       ON o.filing = c.composition AND o.layer = c.composed_layer
JOIN      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
       ON d.filing = c.composition AND d.layer = c.composed_layer
LEFT JOIN (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
       ON e.composition = c.composition
      AND e.composed_layer = c.composed_layer
      AND e.quantity = 'demand'
GROUP BY c.composition, c.composed_layer

    ) f
) p ON true
WHERE r.slug = 'fusion_sum_disagrees'
