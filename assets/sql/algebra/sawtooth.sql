-- layers/decomposed.sqlc, restricted to demands inside one tooth.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           x.d_low_residue <= x.d_mode_residue AND x.d_mode_residue <= x.d_high_residue AS holds,
           format('demand [%s, %s, %s] inside tooth %s of %s, residues [%s, %s, %s]',
                  x.d_low, x.d_mode, x.d_high, x.d_low_tooth, x.q,
                  x.d_low_residue, x.d_mode_residue, x.d_high_residue) AS detail
    FROM (
        SELECT * FROM layers.decomposed
    ) x
    WHERE NOT x.crosses_tooth
) p ON true
WHERE a.slug = 'sawtooth'
