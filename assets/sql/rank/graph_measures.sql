-- rank/graph_edges.sqlc, symmetrised and walked for components, counted at both scopes.
WITH RECURSIVE
edges AS (
    SELECT DISTINCT g.graph, g.filing, g.from_node AS a, g.to_node AS b
    FROM ( SELECT * FROM rank.graph_edges ) g
),
scoped AS (
    SELECT DISTINCT graph, NULL::text AS filing, a, b FROM edges
  UNION ALL
    SELECT graph, filing, a, b FROM edges
),
nodes AS (SELECT graph, filing, a AS u FROM scoped UNION SELECT graph, filing, b FROM scoped),
sym   AS (SELECT graph, filing, a, b FROM scoped UNION SELECT graph, filing, b, a FROM scoped),
reach(graph, filing, root, at) AS (
      SELECT graph, filing, u, u FROM nodes
    UNION
      SELECT r.graph, r.filing, r.root, s.b
      FROM reach r JOIN sym s ON s.graph = r.graph AND s.filing IS NOT DISTINCT FROM r.filing
                              AND s.a = r.at
),
comp AS (SELECT graph, filing, root, min(at) AS component FROM reach GROUP BY graph, filing, root)
SELECT n.graph, n.filing,
       count(DISTINCT n.u)                                         AS n_nodes,
       (SELECT count(*) FROM scoped w
         WHERE w.graph = n.graph AND w.filing IS NOT DISTINCT FROM n.filing) AS m_edges,
       count(DISTINCT c.component)                                 AS c_components,
       (SELECT count(*) FROM scoped w
         WHERE w.graph = n.graph AND w.filing IS NOT DISTINCT FROM n.filing)
         - count(DISTINCT n.u) + count(DISTINCT c.component)       AS cycle_space_dim,
       count(DISTINCT n.u) - count(DISTINCT c.component)           AS rank_of_incidence
FROM nodes n
JOIN comp c ON c.graph = n.graph AND c.filing IS NOT DISTINCT FROM n.filing AND c.root = n.u
GROUP BY n.graph, n.filing
