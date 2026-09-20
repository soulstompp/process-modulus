-- folds/rule_subjects.sqlc, one row per rule either side names.
SELECT f.subject                        AS rule,
       f.answered                       AS examined,
       f.violated                       AS violations,
       CASE WHEN f.answered = 0 THEN '⛔ VACUOUS - proves nothing'
            WHEN f.answered < 3 THEN 'thin'
            ELSE 'ok' END               AS verdict
FROM (
    SELECT * FROM folds.rule_subjects
) f
ORDER BY examined DESC, rule
