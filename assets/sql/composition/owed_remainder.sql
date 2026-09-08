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
