-- algebra/roster.sqlc against public.compose_edge: who composes the layer dimension.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/every_layer.sqlc' AS subject,
           count(*) = 0              AS holds,
           format('%s undeclared parent(s) compose the layer dimension: %s',
                  count(*), coalesce(string_agg(u.parent, ', ' ORDER BY u.parent), '(none)'))
                                     AS detail
    FROM (
        SELECT e.parent
        FROM ( SELECT * FROM rank.compose_edges ) e
        WHERE e.child = 'layers/every_layer.sqlc'
          AND e.inner_joins > 0
          AND e.parent NOT IN ('entries/spillovers.sqlc')
    ) u
) p ON true
WHERE a.slug = 'dimension_use'
