-- rank/graph_measures.sqlc's layer row at the corpus scope against checks/jagged_layer.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/cycle_space' AS subject,
           x.nodes > 0 AND x.edges > 0 AND x.examined > 0
           AND (x.dim = 0) = (x.violations = 0)                                      AS holds,
           format('dim %s over %s node(s), %s edge(s), %s component(s); %s of %s fusion(s) '
                  'examined violate the partition',
                  x.dim, x.nodes, x.edges, x.components, x.violations, x.examined)   AS detail
    FROM (
        SELECT m.cycle_space_dim AS dim, m.n_nodes AS nodes, m.m_edges AS edges,
               m.c_components AS components, j.violations, j.examined
        FROM      (
            SELECT * FROM rank.graph_measures
        ) m
        CROSS JOIN (
            SELECT count(*) FILTER (WHERE k.violates)             AS violations,
                   count(*) FILTER (WHERE k.violates IS NOT NULL) AS examined
            FROM ( SELECT * FROM checks.jagged_layer ) k
        ) j
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'cycle_space'
