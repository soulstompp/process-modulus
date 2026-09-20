-- layers/remainder.sqlc where exposure > 0, against layers/exposure_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/exposure_scope' AS subject,
           x.exposed = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s exposed layers, %s classified, %s classified twice, %s with no standing',
                  x.exposed, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r
               WHERE r.exposure > 1e-9)                                          AS exposed,
             (SELECT count(*) FROM ( SELECT * FROM layers.exposure_scope ) z)   AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer
                                     FROM ( SELECT * FROM layers.exposure_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM layers.exposure_scope ) z
               WHERE z.standing IS NULL)                                         AS unclassified
         ) x
) p ON true
WHERE a.slug = 'exposure_standing'
