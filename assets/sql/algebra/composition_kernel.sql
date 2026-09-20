-- rank/composition_kernel.sqlc folded, against rank/graph_measures.sqlc's layer row.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/composition_kernel' AS subject,
           x.parts > 0 AND x.fusions > 0 AND x.edges > 0
           AND x.parts = x.edges
           AND x.kernel = x.edges - x.fusions                                        AS holds,
           format('dim ker %s over %s part(s) in %s fusion(s); the layer graph has %s edge(s), '
                  '%s node(s), %s component(s) and cycle space %s',
                  x.kernel, x.parts, x.fusions, x.edges,
                  x.nodes, x.components, x.dim)                                      AS detail
    FROM (
        SELECT k.parts, k.fusions, k.kernel,
               m.m_edges AS edges, m.n_nodes AS nodes,
               m.c_components AS components, m.cycle_space_dim AS dim
        FROM      (
            SELECT coalesce(sum(c.parts), 0)      AS parts,
                   count(*)                       AS fusions,
                   coalesce(sum(c.kernel_dim), 0) AS kernel
            FROM ( SELECT * FROM rank.composition_kernel ) c
        ) k
        CROSS JOIN (
            SELECT * FROM rank.graph_measures
        ) m
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'composition_kernel'
