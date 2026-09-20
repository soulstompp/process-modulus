-- composition/carriable.sqlc partitioned by eliminations/filed.sqlc and composition/suspended_quantities.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/carried' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s carriable = %s carried + %s eliminated or suspended',
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.carriable ) c) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.carried ) k)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.carriable ) c
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                              WHERE e.composition = c.filing AND e.composed_layer = c.layer)
                  OR EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_quantities ) s
                              WHERE s.composition = c.filing AND s.composed_layer = c.layer
                                AND s.quantity::text = c.quantity::text)) AS removed
         ) x
) p ON true
WHERE a.slug = 'carried'
