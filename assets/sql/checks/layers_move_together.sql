-- composition/descent.sqlc intersected with its converse; conformance rule "layers that always move together are one layer".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT f.filing, f.layer,
           c.filing IS NOT NULL AS violates,
           CASE WHEN c.filing IS NULL
                THEN format('`%s` holds its remainder independently', f.layer)
                WHEN c.partner IS NULL
                THEN format('`%s` is composed from ITSELF, so its figure depends on its own value and no rank exists for it', f.layer)
                ELSE format('`%s` moves with `%s`, and %s layers here were one layer: the repair is to merge them, not to break a part',
                            f.layer, c.partner, c.members)
           END AS detail
    FROM      (
        SELECT * FROM composition.fusions
    ) f
    LEFT JOIN (
        SELECT m.filing, m.layer, m.class, m.members,
               bool_or(m.co_moves_with_filing = m.filing AND m.co_moves_with_layer = m.layer)
                 AS reaches_itself,
               min(m.co_moves_with_filing || '/' || m.co_moves_with_layer)
                 FILTER (WHERE NOT (m.co_moves_with_filing = m.filing
                                AND m.co_moves_with_layer = m.layer)) AS partner
        FROM (
            -- composition/descent.sqlc intersected with its own converse; the classes of F+ ∩ (F+)ᵀ.
SELECT p.filing, p.layer, p.co_moves_with_filing, p.co_moves_with_layer,
       min(p.co_moves_with_filing || '/' || p.co_moves_with_layer) OVER w AS class,
       count(*) OVER w                                                    AS members
FROM (
    SELECT DISTINCT a.root_filing AS filing, a.root_layer AS layer,
           a.filing AS co_moves_with_filing, a.layer AS co_moves_with_layer
    FROM      (
        SELECT * FROM composition.descent
    ) a
    JOIN      (
        SELECT * FROM composition.descent
    ) b ON  b.root_filing = a.filing      AND b.root_layer = a.layer
        AND b.filing      = a.root_filing AND b.layer      = a.root_layer
) p
WINDOW w AS (PARTITION BY p.filing, p.layer)

        ) m
        GROUP BY m.filing, m.layer, m.class, m.members
    ) c ON c.filing = f.filing AND c.layer = f.layer
) p ON true
WHERE r.slug = 'layers_move_together'
