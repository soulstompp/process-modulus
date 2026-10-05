-- epistemics/class_cells.sqlc counted per class over every loaded document, with its declared unit.
SELECT k.relation, k.codomain, k.class, s.subject,
       count(k.ball)   AS balls,
       count(k.filing) AS filed_balls,
       k.ord
FROM      (
    SELECT * FROM epistemics.class_cells
) k
LEFT JOIN (
    SELECT * FROM epistemics.class_sets
) s ON s.relation = k.relation
GROUP BY k.relation, k.codomain, k.class, s.subject, k.ord
