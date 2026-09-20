-- composition/fusions.sqlc for every quantity, minus the suspensions that lift each sum and the
-- composed figures filed `derived`.
SELECT f.filing, f.layer, q.quantity
FROM      (
    SELECT * FROM composition.fusions
) f
CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
EXCEPT
(
    SELECT s.composition, s.composed_layer, s.quantity
    FROM (
        SELECT * FROM composition.suspended_quantities
    ) s
    UNION
    SELECT d.filing, d.layer, d.quantity
    FROM (
        SELECT * FROM composition.derived_fusions
    ) d
)
