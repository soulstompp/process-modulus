-- composition/filed_grounds.sqlc restricted to the two quantities r is built from, at the layer or a node its walk passes;
-- composition/resolved_quantities.sqlc without a demand or nameplate figure at the layer or a node the walk reaches.
SELECT DISTINCT t.root_filing AS composition, t.root_layer AS composed_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM composition.fusions
    ) f
    UNION ALL
    SELECT w.root_filing, w.root_layer, w.filing, w.layer
    FROM (
        SELECT * FROM composition.passed_nodes
    ) w
) t
JOIN      (
    SELECT * FROM composition.filed_grounds
) s ON s.composition = t.filing AND s.composed_layer = t.layer
WHERE s.quantity IS NULL
   OR s.quantity IN ('demand', 'nameplate')
UNION
SELECT w.root_filing, w.root_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM composition.fusions
    ) f
    UNION ALL
    SELECT r.root_filing, r.root_layer, r.filing, r.layer
    FROM (
        SELECT * FROM composition.remainder_frontier
    ) r
) w
JOIN      (
    SELECT * FROM composition.resolved_quantities
) q ON q.filing = w.filing AND q.layer = w.layer
WHERE q.quantity IN ('demand', 'nameplate')
  AND q.low IS NULL
