-- rank/compose_edges.sqlc, symmetrised and walked for components, counted whole and by directory.
WITH RECURSIVE
edge AS (
    SELECT DISTINCT e.parent AS a, e.child AS b
    FROM ( SELECT * FROM rank.compose_edges ) e
),
node AS (
    SELECT a AS name FROM edge UNION SELECT b FROM edge
),
placed AS (
    SELECT n.name,
           CASE WHEN position('/' IN n.name) > 0 THEN split_part(n.name, '/', 1) ELSE '(root)' END
             AS directory
    FROM node n
),
scoped_node AS (
    SELECT NULL::text AS scope, p.name FROM placed p
  UNION ALL
    SELECT p.directory, p.name FROM placed p
),
scoped_edge AS (
    SELECT NULL::text AS scope, e.a, e.b FROM edge e
  UNION ALL
    SELECT pa.directory, e.a, e.b
    FROM edge e
    JOIN placed pa ON pa.name = e.a
    JOIN placed pb ON pb.name = e.b AND pb.directory = pa.directory
),
sym AS (
    SELECT scope, a, b FROM scoped_edge
  UNION
    SELECT scope, b, a FROM scoped_edge
),
reach(scope, root, at) AS (
      SELECT s.scope, s.name, s.name FROM scoped_node s
    UNION
      SELECT r.scope, r.root, y.b
      FROM reach r JOIN sym y ON y.scope IS NOT DISTINCT FROM r.scope AND y.a = r.at
),
comp AS (SELECT scope, root, min(at) AS component FROM reach GROUP BY scope, root)
SELECT n.scope,
       count(DISTINCT n.name)                                              AS n_nodes,
       (SELECT count(*) FROM scoped_edge w
         WHERE w.scope IS NOT DISTINCT FROM n.scope)                       AS m_edges,
       count(DISTINCT c.component)                                         AS c_components,
       count(DISTINCT n.name) - count(DISTINCT c.component)                AS rank_of_incidence,
       (SELECT count(*) FROM scoped_edge w
         WHERE w.scope IS NOT DISTINCT FROM n.scope)
         - count(DISTINCT n.name) + count(DISTINCT c.component)            AS cycle_space_dim
FROM      scoped_node n
JOIN      comp c ON c.scope IS NOT DISTINCT FROM n.scope AND c.root = n.name
GROUP BY  n.scope
