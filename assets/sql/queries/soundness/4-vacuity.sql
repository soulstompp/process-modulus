-- §4  Every declared rule and site, and how many rows its check actually emits.
-- folds/rule_subjects.sqlc and folds/site_subjects.sqlc, restricted to what each roster declares.
SELECT 'rules' AS "contract!", f.subject AS "subject!", f.rows AS "rows!",
       f.answered AS "verdicts!"
FROM (
    SELECT * FROM folds.rule_subjects
) f
WHERE f.declared
UNION ALL
SELECT 'arithmetic', f.subject, f.rows, f.answered
FROM (
    SELECT * FROM folds.site_subjects
) f
WHERE f.declared
