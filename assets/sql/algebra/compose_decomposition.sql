-- algebra/roster.sqlc against rank/compose_measures.sqlc: the directory cut is a partition.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/compose_decomposition' AS subject,
           x.whole_nodes = x.cut_nodes
             AND x.whole_edges = x.cut_edges + x.crossing                            AS holds,
           format('%s templates whole = %s summed over %s directories; %s edges = %s kept + %s crossing',
                  x.whole_nodes, x.cut_nodes, x.directories,
                  x.whole_edges, x.cut_edges, x.crossing)                            AS detail
    FROM ( SELECT
             (SELECT m.n_nodes FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_nodes,
             (SELECT coalesce(sum(m.n_nodes), 0) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_nodes,
             (SELECT m.m_edges FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_edges,
             (SELECT coalesce(sum(m.m_edges), 0) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_edges,
             (SELECT count(*) FROM ( SELECT * FROM rank.compose_edges ) e
               WHERE (CASE WHEN position('/' IN e.parent) > 0
                           THEN split_part(e.parent, '/', 1) ELSE '(root)' END)
                  <> (CASE WHEN position('/' IN e.child) > 0
                           THEN split_part(e.child, '/', 1) ELSE '(root)' END))       AS crossing,
             (SELECT count(*) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS directories
         ) x
) p ON true
WHERE a.slug = 'compose_decomposition'
