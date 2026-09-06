-- pm:Part with a local pm:ForeignId, followed transitively; SQL:2016 CYCLE, Postgres 14+.
WITH RECURSIVE
local AS (
    -- pm.part where pm:ForeignId/notation equals the composition's own pm:notation.
SELECT p.*
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

) fi ON fi.filing = p.composition AND fi.notation = p.part_filing

),
walk(filing, root, layer) AS (
        SELECT p.composition, p.composed_layer, p.part_layer FROM local p
    UNION ALL
        SELECT w.filing, w.root, p.part_layer
        FROM walk w
        JOIN local p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT DISTINCT filing, root, route
FROM walk
WHERE is_cycle
