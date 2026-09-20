-- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM layers.every_layer
) l
LEFT JOIN (
    SELECT * FROM diagrams.lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
