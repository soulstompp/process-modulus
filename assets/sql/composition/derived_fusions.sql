-- composition/fusion_quantities.sqlc filed as a derivation.
SELECT q.filing, q.layer, q.quantity
FROM (
    SELECT * FROM composition.fusion_quantities
) q
WHERE q.derivation IS NOT NULL
