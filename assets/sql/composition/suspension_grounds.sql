-- the grounds that lift the sum rule: those read off the filing, and a derived part that cannot be computed.
SELECT * FROM composition.filed_grounds
UNION ALL
-- composition/parts.sqlc whose figure composition/derived_quantities.sqlc cannot compute, per fusion.
SELECT p.composition, p.composed_layer, d.quantity,
       'a part files the quantity derived and it cannot be computed' AS suspended_because,
       string_agg(p.part_filing || '/' || p.part_layer || ': ' || d.blocked_because, ', '
                  ORDER BY p.part_filing, p.part_layer) AS note
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM composition.derived_quantities
) d ON d.filing = p.part_filing AND d.layer = p.part_layer
WHERE d.low IS NULL
GROUP BY p.composition, p.composed_layer, d.quantity

