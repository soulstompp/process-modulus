-- §4  Every question the absence census asks, the column it claims to read, and what it found.
-- epistemics/absence_questions.sqlc, each question counted in epistemics/absences.sqlc.
SELECT q.question AS "question!", q.table_name AS "table_name!", q.column_name AS "column_name!",
       count(a.question) AS "census!"
FROM      (
    SELECT * FROM epistemics.absence_questions
) q
LEFT JOIN (
    SELECT * FROM epistemics.absences
) a ON a.question = q.question
GROUP BY q.question, q.table_name, q.column_name
ORDER BY q.table_name, q.column_name
