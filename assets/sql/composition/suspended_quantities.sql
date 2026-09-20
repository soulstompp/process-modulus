-- composition/suspended_fusions.sqlc expanded onto pm.summed_quantity.
SELECT DISTINCT s.composition, s.composed_layer, q.quantity
FROM      (
    SELECT * FROM composition.suspended_fusions
) s
JOIN      unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
       ON s.quantity IS NULL OR s.quantity = q.quantity
