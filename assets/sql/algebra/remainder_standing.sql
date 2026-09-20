-- layers/remainder.sqlc against layers/remainder_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/remainder_scope' AS subject,
           x.computable = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s computable remainders, %s classified, %s classified twice, %s with no standing',
                  x.computable, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r)       AS computable,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder_scope ) z) AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer FROM ( SELECT * FROM layers.remainder_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder_scope ) z
               WHERE z.standing IS NULL)                                             AS unclassified
         ) x
) p ON true
WHERE a.slug = 'remainder_standing'
