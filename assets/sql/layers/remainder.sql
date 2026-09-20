
-- layers/differenced_remainder.sqlc, overridden by composition/fused_remainders.sqlc where a
-- composed layer owes an exact remainder, less composition/figureless_remainders.sqlc.
SELECT x.filing, x.layer,
       x.sign, x.sign_absent,
       x.absorber_taxonomy, x.absorber_value, x.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.unit,
       x.n_low, x.n_mode, x.n_high, x.amount_unit,
       x.r_low, x.r_mode, x.r_high,
       CASE WHEN x.r_low  >= 0 THEN 'clearance'::pm.fit
            WHEN x.r_high <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(-x.r_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit,
       x.pivoted,
       CASE WHEN x.r_low <= 0 AND x.r_high >= 0 THEN 0
            ELSE least(abs(x.r_low), abs(x.r_high)) END AS m_low,
       abs(x.r_mode)                                    AS m_mode,
       greatest(abs(x.r_low), abs(x.r_high))            AS m_high
FROM (
    SELECT b.filing, b.layer,
           b.sign, b.sign_absent,
           b.absorber_taxonomy, b.absorber_value, b.absorber_absent,
           b.d_low, b.d_mode, b.d_high, b.unit,
           b.n_low, b.n_mode, b.n_high, b.amount_unit,
           coalesce(f.pivoted_low,  b.r_low)  AS r_low,
           coalesce(f.pivoted_mode, b.r_mode) AS r_mode,
           coalesce(f.pivoted_high, b.r_high) AS r_high,
           b.lumpy, b.quantum_mode, b.quantum_unit,
           (f.pivoted_low IS NOT NULL) AS pivoted
    FROM      (
        SELECT * FROM layers.differenced_remainder
    ) b
    LEFT JOIN (
        SELECT * FROM composition.fused_remainders
    ) f ON f.composition = b.filing AND f.composed_layer = b.layer
    WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.figureless_remainders ) g
                      WHERE g.filing = b.filing AND g.layer = b.layer)
) x
