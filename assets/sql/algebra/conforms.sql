-- folds/rule_subjects.sqlc for every rule checks/roster.sqlc declares, one verdict per rule.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.slug AS subject,
           f.violated = 0 AS holds,
           format('%s examined, %s violating', f.answered, f.violated) AS detail
    FROM (
        SELECT * FROM checks.roster
    ) r
    JOIN (
        SELECT * FROM folds.rule_subjects
    ) f ON f.subject = r.rule
) p ON true
WHERE a.slug = 'conforms'
