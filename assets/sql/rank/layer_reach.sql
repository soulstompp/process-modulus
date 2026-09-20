-- checks/all.sqlc counted per layer, against layers/every_layer.sqlc as the whole dimension.
SELECT l.filing,
       l.layer,
       count(DISTINCT c.rule)                                   AS examined_by,
       count(DISTINCT c.rule) FILTER (WHERE c.violates)         AS violated,
       count(DISTINCT c.rule) = 0                               AS nothing_reaches_it
FROM      (
    SELECT * FROM layers.every_layer
) l
LEFT JOIN (
    SELECT * FROM checks.all
) c ON c.filing = l.filing AND c.layer = l.layer
GROUP BY l.filing, l.layer
