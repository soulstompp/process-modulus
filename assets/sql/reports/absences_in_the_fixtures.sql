-- reports/absence_census.sqlc at fixture scope.
-- epistemics/absences.sqlc, restricted by the caller's @scope.
SELECT a.question, a.reason, count(*) AS times
FROM (
    SELECT * FROM epistemics.absences
) a
JOIN (
    -- from pm.filing where evidence = 'stipulation'; see assets/fixtures/README.md.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'stipulation'

) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2

