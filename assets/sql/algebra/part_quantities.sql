-- composition/parts.sqlc with layers/quantities.sqlc, against composition/part_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_quantities' AS subject,
           x.total = x.alone + x.paired AS holds,
           format('%s part quantities = %s the composed layer does not file + %s set beside it',
                  x.total, x.alone, x.paired) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.parts ) p
               JOIN ( SELECT * FROM layers.quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer)                  AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.parts ) p
               JOIN ( SELECT * FROM layers.quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM layers.quantities ) c
                                  WHERE c.filing = p.composition AND c.layer = p.composed_layer
                                    AND c.quantity = q.quantity))                        AS alone,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_quantities ) x)       AS paired
         ) x
) p ON true
WHERE a.slug = 'part_quantities'
