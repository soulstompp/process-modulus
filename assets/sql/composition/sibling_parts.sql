-- composition/parts.sqlc crossed with itself on the composed layer and the part filing.
SELECT x.composition, x.composed_layer,
       x.part_filing,
       x.part_layer AS from_layer,
       y.part_layer AS to_layer,
       x.factor_low  AS from_factor_low,  x.factor_mode AS from_factor_mode,
       y.factor_low  AS to_factor_low,    y.factor_mode AS to_factor_mode
FROM (
    SELECT * FROM composition.parts
) x
JOIN (
    SELECT * FROM composition.parts
) y
  ON y.composition    = x.composition
 AND y.composed_layer = x.composed_layer
 AND y.part_filing    = x.part_filing
