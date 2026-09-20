-- rank/decomposition.sqlc's two scopes, counted: the whole against the sum of the parts.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/decomposition' AS subject,
           x.whole = x.per_filing AS holds,
           format('%s edges corpus-wide = %s summed over %s filings, across %s graphs',
                  x.whole, x.per_filing, x.filings, x.graphs) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.from_node, g.to_node
                 FROM ( SELECT * FROM rank.graph_edges ) g) e)                      AS whole,
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.filing, g.from_node, g.to_node
                 FROM ( SELECT * FROM rank.graph_edges ) g) e)                      AS per_filing,
             (SELECT count(DISTINCT g.filing)
              FROM ( SELECT * FROM rank.graph_edges ) g)                            AS filings,
             (SELECT count(DISTINCT g.graph)
              FROM ( SELECT * FROM rank.graph_edges ) g)                            AS graphs
         ) x
) p ON true
WHERE a.slug = 'decomposition'
