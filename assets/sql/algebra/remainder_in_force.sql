-- layers/differenced_remainder.sqlc partitioned by composition/figureless_remainders.sqlc into layers/remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/remainder' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s differenced = %s in force + %s with no legitimate figure', x.total, x.kept,
                  x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.differenced_remainder ) b) AS total,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r)             AS kept,
             (SELECT count(*) FROM ( SELECT * FROM layers.differenced_remainder ) b
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.figureless_remainders ) g
                             WHERE g.filing = b.filing AND g.layer = b.layer))  AS removed
         ) x
) p ON true
WHERE a.slug = 'remainder_in_force'
