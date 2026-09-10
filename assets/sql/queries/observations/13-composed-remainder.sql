-- composition/fused_remainders.sqlc, with the two figures set against each other.
SELECT f.composition                                             AS "composition!",
       f.composed_layer                                          AS "composed_layer!",
       f.parts                                                   AS "parts!",
       f.unit                                                    AS "unit!",
       f.pivoted_low::float8                                     AS "pivoted_low!",
       f.pivoted_mode::float8                                    AS "pivoted_mode!",
       f.pivoted_high::float8                                    AS "pivoted_high!",
       f.derived_low::float8                                     AS "derived_low!",
       f.derived_mode::float8                                    AS "derived_mode!",
       f.derived_high::float8                                    AS "derived_high!",
       (f.pivoted_low = f.derived_low
    AND f.pivoted_mode = f.derived_mode
    AND f.pivoted_high = f.derived_high)                         AS "agrees!"
FROM (
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
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) en ON en.composition = c.composition AND en.composed_layer = c.composed_layer
    AND en.quantity = 'nameplate'
LEFT JOIN (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
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
    -- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

) o ON o.filing = w.filing AND o.layer = w.layer
JOIN      (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
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
    -- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
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
WHERE p.factor_low IS DISTINCT FROM p.factor_high

) o ON o.filing = w.filing AND o.layer = w.layer
JOIN      (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
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

) f
ORDER BY "agrees!", f.composition, f.composed_layer
