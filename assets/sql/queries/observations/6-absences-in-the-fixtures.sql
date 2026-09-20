-- §6  What the fixtures decline to answer, which is the whole reason they exist.
-- reports/absences_in_the_fixtures.sqlc, given the caller that makes it readable.
SELECT a.question AS "question!", a.reason::text AS "reason!", a.times AS "times!"
FROM (
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


) a
ORDER BY a.times DESC, a.question
