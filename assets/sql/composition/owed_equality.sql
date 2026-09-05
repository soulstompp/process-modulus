-- pm.part minus the two suspensions; see composition/suspended_fusions.sqlc.
SELECT f.filing, f.layer
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
    -- the two pm:Absent reason="unmeasured" filings that lift the sum rule.
-- pm:Fusion/pm:Eliminations with pm:Absent reason="unmeasured".
SELECT es.composition, es.composed_layer,
       'the search was never made' AS suspended_because,
       es.note
FROM pm.elimination_search es
WHERE es.absent = 'unmeasured'
UNION ALL
-- pm:Eliminations/pm:Elimination quantity="demand" with pm:Absent reason="unmeasured".
SELECT e.composition, e.composed_layer,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM pm.elimination e
WHERE e.quantity = 'demand' AND e.absent = 'unmeasured'


) s
       ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL
