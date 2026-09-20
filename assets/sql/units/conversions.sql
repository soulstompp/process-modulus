-- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       p.part_unit     AS from_unit,
       p.composed_unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
FROM (
    SELECT * FROM composition.part_quantities
) p
WHERE p.quantity = 'nameplate'
  AND p.factor_state = 'stated'
