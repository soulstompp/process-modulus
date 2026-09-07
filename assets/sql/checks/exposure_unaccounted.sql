-- every slack on the layer accounted for and empty, against entries/unserved_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    -- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees', 'layer', 'sign agrees with the range comparison'),
  ('shares_do_not_sum', 'layer', 'stated shares sum to the magnitude'),
  ('nobody_named_as_unserved', 'layer', 'a supply with nowhere to put its excess names who went unserved'),
  ('exposure_unaccounted', 'layer', 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack', 'layer', 'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch', 'slack', 'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch', 'layer', 'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple', 'layer', 'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply', 'layer', 'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved', 'layer', 'a clearance fit rules out customer and unrealised'),
  ('unresolved_part', 'part', 'a part reference resolves to a filing that is here'),
  ('jagged_layer', 'layer', 'a fusion''s parts partition what they compose'),
  ('layers_move_together', 'layer', 'layers that always move together are one layer'),
  ('coupling_does_not_attenuate', 'layer', 'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value', 'layer', 'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range', 'layer', 'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range', 'layer', 'a point value does not say its bound is where the measurements fell'),
  ('window_lost_or_summed', 'part', 'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window', 'layer', 'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate', 'layer', 'a window is notApplicable only where the unit has no period under the line'),
  ('elimination_not_applicable_with_parts', 'layer', 'a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees', 'layer', 'a composed demand equals the sum of its converted parts less its eliminations'),
  ('local_part_dangles', 'part', 'a local part names a layer in its own stack'),
  ('unit_crossing_without_a_factor', 'layer', 'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'part', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees', 'part', 'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close', 'layer', 'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part', 'part', 'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted', 'layer', 'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, subject, rule)

) r
LEFT JOIN (
    SELECT e.filing, e.layer,
           e.exposure > e.unserved + 1e-9 AS violates,
           format('exposure %s, absorbable %s, unserved %s',
                  e.exposure, e.absorbable, e.unserved) AS detail
    FROM (
        SELECT x.filing, x.layer, x.exposure, x.absorbable, u.unserved_high AS unserved
        FROM      (
            -- layers/exposure_scope.sqlc, restricted to the standing that licenses a conclusion.
SELECT s.*
FROM (
    -- layers/remainder.sqlc where exposure > 0, classified by layers/absorption.sqlc.
SELECT r.*, a.absorbable, a.unknown,
       CASE WHEN a.unknown    > 0 THEN 'a buffer nobody sized'
            WHEN a.absorbable > 0 THEN 'a buffer with room in it'
            ELSE                       'every buffer sized and empty' END AS standing
FROM      (
    -- layers/differenced_remainder.sqlc, overridden by composition/fused_remainders.sqlc where a
-- composed layer owes an exact remainder.
SELECT b.filing, b.layer,
       b.sign, b.sign_absent,
       b.absorber_taxonomy, b.absorber_value,
       b.d_low, b.d_mode, b.d_high, b.unit,
       b.n_low, b.n_mode, b.n_high, b.amount_unit,
       coalesce(f.pivoted_low,  b.r_low)  AS r_low,
       coalesce(f.pivoted_mode, b.r_mode) AS r_mode,
       coalesce(f.pivoted_high, b.r_high) AS r_high,
       CASE WHEN coalesce(f.pivoted_low,  b.r_low)  >= 0 THEN 'clearance'
            WHEN coalesce(f.pivoted_high, b.r_high) <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(-coalesce(f.pivoted_low, b.r_low), 0) AS exposure,
       b.lumpy, b.quantum_mode, b.quantum_unit,
       (f.pivoted_low IS NOT NULL) AS pivoted
FROM      (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
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
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) b
LEFT JOIN (
    -- composition/settled_remainders.sqlc summed over the settled frontier, less eliminations/filed.sqlc.
SELECT c.composition, c.composed_layer,
       sum(c.r_low)  - coalesce(max(en.low),  0) - coalesce(max(cn.e_low),  0)
         + CASE WHEN bool_or(c.spread_factor) AND sum(c.r_low) >= 0
                THEN coalesce(max(ed.low),  0) + coalesce(max(cd.e_low),  0)
                ELSE coalesce(max(ed.high), 0) + coalesce(max(cd.e_high), 0) END AS pivoted_low,
       sum(c.r_mode) - coalesce(max(en.mode), 0) - coalesce(max(cn.e_mode), 0)
                     + coalesce(max(ed.mode), 0) + coalesce(max(cd.e_mode), 0)   AS pivoted_mode,
       sum(c.r_high) - coalesce(max(en.high), 0) - coalesce(max(cn.e_high), 0)
         + CASE WHEN bool_or(c.spread_factor) AND sum(c.r_low) >= 0
                THEN coalesce(max(ed.high), 0) + coalesce(max(cd.e_high), 0)
                ELSE coalesce(max(ed.low),  0) + coalesce(max(cd.e_low),  0) END AS pivoted_high,
       max(d.r_low)  AS derived_low,
       max(d.r_mode) AS derived_mode,
       max(d.r_high) AS derived_high,
       max(d.derived_fit) AS derived_fit,
       max(d.unit)   AS unit,
       count(*)      AS parts
FROM      (
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
    -- composition/parts.sqlc walked while composition/unsettled.sqlc holds, carrying the product.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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

),
open_node AS (
    -- composition/parts.sqlc, restricted to the parts whose factor has width.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

),
frontier(root_filing, root_layer, filing, layer, depth,
         factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               (p.factor_absent IS NOT NULL)
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR (p.factor_absent IS NOT NULL)
        FROM frontier w
        JOIN open_node o ON o.filing = w.filing AND o.layer = w.layer
        JOIN resolved p  ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM frontier

) w
JOIN      (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
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
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) r ON r.filing = w.filing AND r.layer = w.layer
LEFT JOIN (
    -- composition/parts.sqlc, restricted to the parts whose factor has width.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

) o ON o.filing = w.filing AND o.layer = w.layer
WHERE w.factor_absent = false
  AND NOT w.is_cycle
  AND o.filing IS NULL

) c
JOIN      (
    -- composition/fusions.sqlc less composition/suspended_remainders.sqlc.
SELECT f.filing, f.layer
FROM      (
    -- distinct (composition, composedLayerName) over pm:Fusion/pm:Part.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p

) f
LEFT JOIN (
    -- composition/suspended_fusions.sqlc restricted to the two quantities r is built from.
SELECT DISTINCT s.composition, s.composed_layer
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
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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
WHERE p.factor_absent IS NOT NULL


) g

) s
WHERE s.quantity IS NULL
   OR s.quantity IN ('demand', 'nameplate')

) s ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL

) o  ON o.filing = c.composition AND o.layer = c.composed_layer
JOIN      (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
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
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) d  ON d.filing = c.composition AND d.layer = c.composed_layer
LEFT JOIN (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) en ON en.composition = c.composition AND en.composed_layer = c.composed_layer
    AND en.quantity = 'nameplate'
LEFT JOIN (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) ed ON ed.composition = c.composition AND ed.composed_layer = c.composed_layer
    AND ed.quantity = 'demand'
LEFT JOIN (
    -- eliminations/filed.sqlc at the unsettled nodes composition/descent.sqlc runs through, times
-- that path's factor product.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer, e.quantity,
       count(*)                                                     AS through_layers,
       sum(least(   e.low  * w.factor_low, e.low  * w.factor_high)) AS e_low,
       sum(e.mode * w.factor_mode)                                  AS e_mode,
       sum(greatest(e.high * w.factor_low, e.high * w.factor_high)) AS e_high
FROM      (
    -- pm:Fusion/pm:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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

),
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               (p.factor_absent IS NOT NULL)
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR (p.factor_absent IS NOT NULL)
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM walk

) w
JOIN      (
    -- composition/parts.sqlc, restricted to the parts whose factor has width.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

) o ON o.filing = w.filing AND o.layer = w.layer
JOIN      (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e ON e.composition = w.filing AND e.composed_layer = w.layer
WHERE w.factor_absent = false
  AND NOT w.is_cycle
GROUP BY w.root_filing, w.root_layer, e.quantity

) cn ON cn.composition = c.composition AND cn.composed_layer = c.composed_layer
    AND cn.quantity = 'nameplate'
LEFT JOIN (
    -- eliminations/filed.sqlc at the unsettled nodes composition/descent.sqlc runs through, times
-- that path's factor product.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer, e.quantity,
       count(*)                                                     AS through_layers,
       sum(least(   e.low  * w.factor_low, e.low  * w.factor_high)) AS e_low,
       sum(e.mode * w.factor_mode)                                  AS e_mode,
       sum(greatest(e.high * w.factor_low, e.high * w.factor_high)) AS e_high
FROM      (
    -- pm:Fusion/pm:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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

),
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               (p.factor_absent IS NOT NULL)
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR (p.factor_absent IS NOT NULL)
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT * FROM walk

) w
JOIN      (
    -- composition/parts.sqlc, restricted to the parts whose factor has width.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

) o ON o.filing = w.filing AND o.layer = w.layer
JOIN      (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e ON e.composition = w.filing AND e.composed_layer = w.layer
WHERE w.factor_absent = false
  AND NOT w.is_cycle
GROUP BY w.root_filing, w.root_layer, e.quantity

) cd ON cd.composition = c.composition AND cd.composed_layer = c.composed_layer
    AND cd.quantity = 'demand'
GROUP BY c.composition, c.composed_layer

) f ON f.composition = b.filing AND f.composed_layer = b.layer

) r
JOIN      (
    -- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack, summed across the row.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE s.sized OR s.absent = 'notApplicable')            AS absorbable,
       count(*)
         FILTER (WHERE NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable') AS unknown
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
GROUP BY s.filing, s.layer

) a USING (filing, layer)
WHERE r.exposure > 1e-9

) s
WHERE s.standing = 'every buffer sized and empty'

        ) x
        JOIN      (
            -- entries/unserved_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_high IS NULL)     AS unstated,
       sum(h.share_high)                                AS unserved_high,
       sum(h.share_mode)                                AS unserved_mode,
       array_agg(DISTINCT h.share_unit)                 AS share_units
FROM (
    -- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
WHERE h.kind IN ('customer', 'unrealised')

) h
GROUP BY h.filing, h.layer

        ) u USING (filing, layer)
        WHERE u.unstated = 0
    ) e
) p ON true
WHERE r.slug = 'exposure_unaccounted'
