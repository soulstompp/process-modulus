-- reports/absence_census.sqlc at fixture scope.
-- epistemics/absences.sqlc, restricted by the caller's @scope.
SELECT a.question, a.reason, count(*) AS times
FROM (
    SELECT * FROM epistemics.absences
) a
JOIN (
    SELECT * FROM scope.fixtures
) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2

