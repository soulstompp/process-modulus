-- §6  The residue's three points, whether they came back in order, and whether the demand crossed a tooth.
-- layers/lumpy.sqlc at corpus scope; the sawtooth is mod(d, q) at the three points.
SELECT l.filing               AS "filing!",
       l.layer                AS "layer!",
       l.d_low::float8        AS "d_low!",
       l.d_mode::float8       AS "d_mode!",
       l.d_high::float8       AS "d_high!",
       l.quantum_low::float8  AS "q_low!",
       l.quantum_mode::float8 AS "q_mode!",
       l.quantum_high::float8 AS "q_high!",
       (NOT (mod(l.d_low,  l.quantum_mode) <= mod(l.d_mode, l.quantum_mode)
         AND mod(l.d_mode, l.quantum_mode) <= mod(l.d_high, l.quantum_mode)))
                              AS "sawtoothed!",
       (floor(l.d_low / l.quantum_mode) <> floor(l.d_high / l.quantum_mode))
                              AS "crosses_tooth!"
FROM (
    SELECT * FROM layers.lumpy
) l
JOIN (
    SELECT * FROM scope.corpus
) f USING (filing)
WHERE l.d_low IS NOT NULL
ORDER BY l.filing, l.layer
