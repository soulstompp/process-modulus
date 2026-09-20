-- §4b  Every question the absence census actually files a row under.
-- epistemics/absences.sqlc, its questions.
SELECT DISTINCT a.question AS "question!"
FROM (
    SELECT * FROM epistemics.absences
) a
ORDER BY a.question
