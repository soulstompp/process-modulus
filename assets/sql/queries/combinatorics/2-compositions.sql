-- §2  The compositions as balls into boxes: every splice site, and the template it lands in.
-- rank/compose_edges.sqlc, the edge list as it stands.
SELECT e.parent AS "parent!", e.child AS "child!", e.splices::bigint AS "splices!"
FROM (
    SELECT * FROM rank.compose_edges
) e
ORDER BY e.parent, e.child
