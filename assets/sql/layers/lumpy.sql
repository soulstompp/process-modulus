-- layers/figures.sqlc where the nameplate is lumpy, the demand beside it where stated.
SELECT f.filing, f.layer,
       f.n_low, f.n_mode, f.n_high, f.n_unit AS amount_unit,
       f.quantum_low, f.quantum_mode, f.quantum_high, f.quantum_unit, f.quantum_absent,
       f.d_low, f.d_mode, f.d_high, f.d_unit AS unit
FROM (
    SELECT * FROM layers.figures
) f
WHERE f.lumpy
