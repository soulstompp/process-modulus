-- layers/figures.sqlc where both figures are present, beside the sign and absorber of
-- layers/filed_remainders.sqlc.
SELECT x.filing, x.layer,
       f.sign, f.sign_absent,
       f.absorber_taxonomy, f.absorber_value, f.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.d_unit AS unit,
       x.n_low, x.n_mode, x.n_high, x.n_unit AS amount_unit,
       x.n_low  - x.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.high
       x.n_mode - x.d_mode AS r_mode,
       x.n_high - x.d_low  AS r_high,
       CASE WHEN x.n_low  - x.d_high >= 0 THEN 'clearance'::pm.fit
            WHEN x.n_high - x.d_low  <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(x.d_high - x.n_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit
FROM      (
    SELECT * FROM layers.figures
) x
LEFT JOIN (
    SELECT * FROM layers.filed_remainders
) f USING (filing, layer)
WHERE x.d_low IS NOT NULL
  AND x.n_low IS NOT NULL
