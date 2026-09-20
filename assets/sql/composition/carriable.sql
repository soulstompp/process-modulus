-- composition/part_quantities.sqlc for a fusion that files one part, where the factor has a figure.
SELECT q.composition AS filing, q.composed_layer AS layer, q.quantity,
       least(   q.part_low  * coalesce(q.factor_low, 1),
                q.part_low  * coalesce(q.factor_high, 1)) AS part_low,
       q.part_mode * coalesce(q.factor_mode, 1)           AS part_mode,
       greatest(q.part_high * coalesce(q.factor_low, 1),
                q.part_high * coalesce(q.factor_high, 1)) AS part_high,
       q.part_unit,
       q.composed_low AS filed_low, q.composed_mode AS filed_mode, q.composed_high AS filed_high,
       q.composed_unit AS filed_unit
FROM      (
    SELECT * FROM composition.part_quantities
) q
JOIN      (
    SELECT * FROM folds.fusion_parts
) f ON f.composition = q.composition AND f.composed_layer = q.composed_layer
WHERE q.factor_state IN ('omitted', 'stated')
  AND f.parts = 1
