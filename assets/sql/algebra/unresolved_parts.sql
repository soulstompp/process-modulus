-- composition/part_references.sqlc partitioned by composition/parts.sqlc into composition/unresolved_parts.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/unresolved_parts' AS subject,
           x.total = x.kept + x.resolved AS holds,
           format('%s part references = %s unresolved + %s resolved', x.total, x.kept, x.resolved)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.part_references ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.unresolved_parts ) u) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_references ) r
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.parts ) p
                             WHERE p.composition = r.composition
                               AND p.composed_layer = r.composed_layer
                               AND p.part_notation = r.part_filing
                               AND p.part_layer = r.part_layer))                    AS resolved
         ) x
) p ON true
WHERE a.slug = 'unresolved_parts'
