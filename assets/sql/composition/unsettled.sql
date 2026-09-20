-- composition/parts.sqlc restricted to the parts whose factor has width or no figure.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    SELECT * FROM composition.parts
) p
WHERE p.factor_state IN ('absent', 'derivation')
   OR (p.factor_state = 'stated' AND p.factor_low <> p.factor_high)
