-- epistemics/absence_questions.sqlc against epistemics/absence_columns.sqlc, one row per column.
SELECT coalesce(q.table_name, k.table_name) || '.' || coalesce(q.column_name, k.column_name)
                                            AS subject,
       q.column_name IS NOT NULL            AS declared,
       count(k.column_name)                 AS rows
FROM      (
    SELECT * FROM epistemics.absence_questions
) q
FULL JOIN (
    SELECT * FROM epistemics.absence_columns
) k ON k.table_name = q.table_name AND k.column_name = q.column_name
GROUP BY q.table_name, q.column_name, k.table_name, k.column_name
