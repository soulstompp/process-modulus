-- composition/remainder_frontier.sqlc partitioned into composition/settled_remainders.sqlc, composition/passed_nodes.sqlc and the stops layers/differenced_remainder.sqlc has no row for,
-- the figureless stops held to composition/suspended_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH stops AS (
        SELECT w.root_filing, w.root_layer
        FROM ( SELECT * FROM composition.remainder_frontier ) w
        WHERE w.usable
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.unsettled ) o
                          WHERE o.filing = w.filing AND o.layer = w.layer)
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM layers.differenced_remainder ) r
                          WHERE r.filing = w.filing AND r.layer = w.layer)
    ),
    x AS (
        SELECT
          (SELECT count(*) FROM ( SELECT * FROM composition.remainder_frontier ) w
            WHERE w.usable)                                                          AS total,
          (SELECT count(*) FROM ( SELECT * FROM composition.settled_remainders ) s) AS kept,
          (SELECT count(*) FROM ( SELECT * FROM composition.passed_nodes ) w
            WHERE w.usable)                                                          AS removed,
          (SELECT count(*) FROM stops)                                               AS figureless,
          (SELECT string_agg(DISTINCT s.root_filing || ' / ' || s.root_layer, ', ')
           FROM stops s
           WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_remainders ) l
                             WHERE l.composition = s.root_filing
                               AND l.composed_layer = s.root_layer))                 AS unlifted
    )
    SELECT 'composition/settled_remainders' AS subject,
           x.total = x.kept + x.removed + x.figureless AND x.unlifted IS NULL AS holds,
           format('%s frontier rows = %s settled + %s walked through + %s stopped with no figure%s',
                  x.total, x.kept, x.removed, x.figureless,
                  CASE WHEN x.unlifted IS NOT NULL
                       THEN format('; owed although a node it reaches has none: %s', x.unlifted) END)
               AS detail
    FROM x
) p ON true
WHERE a.slug = 'settled_remainders'
