-- composition/fusions.sqlc joined to layers/summed_quantities.sqlc on the composed layer.
SELECT f.filing, f.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation
FROM      (
    SELECT * FROM composition.fusions
) f
JOIN      (
    SELECT * FROM layers.summed_quantities
) s ON s.filing = f.filing AND s.layer = f.layer
