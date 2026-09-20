-- composition/carriable.sqlc less the fusions that eliminate or owe no sum.
SELECT c.*
FROM      (
    SELECT * FROM composition.carriable
) c
WHERE NOT EXISTS (
        SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
        WHERE e.composition = c.filing AND e.composed_layer = c.layer)
  AND NOT EXISTS (
        SELECT 1 FROM ( SELECT * FROM composition.suspended_quantities ) s
        WHERE s.composition = c.filing AND s.composed_layer = c.layer
          AND s.quantity::text = c.quantity::text)
