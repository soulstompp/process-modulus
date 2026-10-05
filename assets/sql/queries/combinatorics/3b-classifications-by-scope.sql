-- §3b  The same classes, counted over the corpus and over the fixtures instead of pooled.
-- reports/class_census.sqlc at both scopes, matched on the class.
SELECT k.relation AS "relation!", k.class AS "class!", k.subject AS "subject?",
       k.balls AS "corpus!", f.balls AS "fixtures?"
FROM      (
    -- reports/class_census.sqlc at corpus scope.
-- epistemics/class_cells.sqlc counted per class, restricted by the caller's @scope.
SELECT k.relation, k.class, s.subject, count(w.filing) AS balls, k.ord
FROM      (
    SELECT * FROM epistemics.class_cells
) k
JOIN      (
    SELECT * FROM epistemics.class_sets
) s ON s.relation = k.relation AND s.filed
LEFT JOIN (
    SELECT * FROM scope.corpus
) w ON w.filing = k.filing
GROUP BY k.relation, k.class, s.subject, k.ord
ORDER BY k.relation, k.ord


) k
LEFT JOIN (
    -- reports/class_census.sqlc at fixtures scope.
-- epistemics/class_cells.sqlc counted per class, restricted by the caller's @scope.
SELECT k.relation, k.class, s.subject, count(w.filing) AS balls, k.ord
FROM      (
    SELECT * FROM epistemics.class_cells
) k
JOIN      (
    SELECT * FROM epistemics.class_sets
) s ON s.relation = k.relation AND s.filed
LEFT JOIN (
    SELECT * FROM scope.fixtures
) w ON w.filing = k.filing
GROUP BY k.relation, k.class, s.subject, k.ord
ORDER BY k.relation, k.ord


) f ON f.relation = k.relation AND f.class = k.class
ORDER BY k.relation, k.ord
