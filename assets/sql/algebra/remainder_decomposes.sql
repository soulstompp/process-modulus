-- layers/decomposed.sqlc against layers/differenced_remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.m_low  * x.q - x.d_high_residue - r.r_low)  < 1e-9
           AND abs(x.m_mode * x.q - x.d_mode_residue - r.r_mode) < 1e-9
           AND abs(x.m_high * x.q - x.d_low_residue  - r.r_high) < 1e-9
           AND x.d_low_residue  >= 0 AND x.d_low_residue  < x.q
           AND x.d_mode_residue >= 0 AND x.d_mode_residue < x.q
           AND x.d_high_residue >= 0 AND x.d_high_residue < x.q AS holds,
           format('m [%s, %s, %s] quanta of %s, residues [%s, %s, %s], against r [%s, %s, %s]',
                  round(x.m_low, 6), round(x.m_mode, 6), round(x.m_high, 6), x.q,
                  x.d_high_residue, x.d_mode_residue, x.d_low_residue,
                  r.r_low, r.r_mode, r.r_high) AS detail
    FROM      (
        SELECT * FROM layers.decomposed
    ) x
    JOIN      (
        SELECT * FROM layers.differenced_remainder
    ) r ON r.filing = x.filing AND r.layer = x.layer
) p ON true
WHERE a.slug = 'remainder_decomposes'
