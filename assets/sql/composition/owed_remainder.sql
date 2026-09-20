-- composition/fusions.sqlc less composition/suspended_remainders.sqlc.
SELECT f.filing, f.layer
FROM      (
    SELECT * FROM composition.fusions
) f
LEFT JOIN (
    SELECT * FROM composition.suspended_remainders
) s ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL
