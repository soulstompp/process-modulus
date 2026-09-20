-- composition/jagged_layers.sqlc partitioned by eliminations/filed.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/jagged_layers' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s jagged rows = %s nobody admitted + %s on a fusion that filed one', 
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                                  WHERE e.composition = j.filing
                                    AND e.composed_layer = j.layer))            AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                              WHERE e.composition = j.filing
                                AND e.composed_layer = j.layer))                AS removed
         ) x
) p ON true
WHERE a.slug = 'jagged_layers'
