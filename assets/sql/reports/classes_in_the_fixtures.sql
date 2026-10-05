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

