-- layers/lumpy.sqlc, split as r = m*q - (demand mod q) at the crossed pairs.
SELECT l.filing, l.layer, l.unit,
       l.quantum_mode AS q,
       l.n_low, l.n_mode, l.n_high,
       l.d_low, l.d_mode, l.d_high,
       floor(l.d_low  / l.quantum_mode) AS d_low_tooth,
       floor(l.d_mode / l.quantum_mode) AS d_mode_tooth,
       floor(l.d_high / l.quantum_mode) AS d_high_tooth,
       mod(l.d_low,  l.quantum_mode)    AS d_low_residue,
       mod(l.d_mode, l.quantum_mode)    AS d_mode_residue,
       mod(l.d_high, l.quantum_mode)    AS d_high_residue,
       l.n_low  / l.quantum_mode - floor(l.d_high / l.quantum_mode) AS m_low,
       l.n_mode / l.quantum_mode - floor(l.d_mode / l.quantum_mode) AS m_mode,
       l.n_high / l.quantum_mode - floor(l.d_low  / l.quantum_mode) AS m_high,
       floor(l.d_low / l.quantum_mode) <> floor(l.d_high / l.quantum_mode) AS crosses_tooth
FROM (
    SELECT * FROM layers.lumpy
) l
WHERE l.d_low IS NOT NULL
  AND l.quantum_mode > 0
  AND l.quantum_low = l.quantum_high
  AND l.unit = l.amount_unit
  AND l.quantum_unit = l.amount_unit
