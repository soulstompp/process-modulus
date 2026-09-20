-- composition/parts.sqlc with layers/quantities.sqlc at the part's layer and at the composed layer.
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       p.factor_state, p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       part.quantity,
       part.low  AS part_low,  part.mode AS part_mode,  part.high AS part_high,  part.unit AS part_unit,
       comp.low  AS composed_low, comp.mode AS composed_mode, comp.high AS composed_high,
       comp.unit AS composed_unit
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM layers.quantities
) part ON part.filing = p.part_filing AND part.layer = p.part_layer
JOIN      (
    SELECT * FROM layers.quantities
) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = part.quantity
