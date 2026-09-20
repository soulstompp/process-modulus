-- layers/summed_quantities.sqlc where no derivation is filed, beside composition/derived_quantities.sqlc where one is.
SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent,
       false                  AS derived,
       s.derivation,
       NULL::text             AS blocked_because
FROM (
    SELECT * FROM layers.summed_quantities
) s
WHERE s.derivation IS NULL
UNION ALL
SELECT d.filing, d.layer, d.quantity, d.low, d.mode, d.high, d.unit,
       NULL::pm.absence_reason,
       d.low IS NOT NULL,
       d.derivation,
       d.blocked_because
FROM (
    SELECT * FROM composition.derived_quantities
) d
