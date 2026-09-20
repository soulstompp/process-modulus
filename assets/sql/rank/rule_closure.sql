-- rank/compose_edges.sqlc walked from each rule on checks/roster.sqlc.
WITH RECURSIVE closure(slug, template) AS (
    SELECT r.slug, 'checks/' || r.slug || '.sqlc'
    FROM (
        SELECT * FROM checks.roster
    ) r
    UNION
    SELECT c.slug, e.child
    FROM closure c
    JOIN (
        SELECT * FROM rank.compose_edges
    ) e ON e.parent = c.template
)
SELECT slug, template FROM closure
