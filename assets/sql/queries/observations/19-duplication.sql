-- §19 The same shape in two graphs, and the opposite verdict on it.
-- rank/compose_edges.sqlc beside composition/parts.sqlc, the same duplication in two graphs.
SELECT 'compose DAG'                                   AS "graph!",
       'a parent splicing one child twice'             AS "duplication!",
       count(*) FILTER (WHERE e.splices > 1)           AS "duplicated!",
       count(*)                                        AS "edges!",
       'ordinary: a query is idempotent, so the repeated relation is read once'
                                                       AS "verdict!"
FROM (
    SELECT * FROM rank.compose_edges
) e
UNION ALL
SELECT 'F, the part graph',
       'one fusion reaching one layer twice',
       (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j),
       (SELECT count(*) FROM ( SELECT * FROM composition.parts ) p),
       'a violation: supply is conserved, so one total closes over both occurrences'
