-- reports/absence_census.sqlc at corpus scope.
-- epistemics/absences.sqlc, restricted by the caller's @scope.
SELECT a.question, a.reason, count(*) AS times
FROM (
    SELECT * FROM epistemics.absences
) a
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2

