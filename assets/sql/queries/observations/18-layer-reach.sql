-- §18 Every filed layer by how many of this repository's rules can say anything about it.
-- rank/layer_reach.sqlc, thinnest first.
SELECT c.filing        AS "filing!",
       c.layer         AS "layer!",
       c.examined_by   AS "examined_by!",
       c.violated      AS "violated!"
FROM (
    SELECT * FROM rank.layer_reach
) c
ORDER BY c.examined_by, c.filing, c.layer
