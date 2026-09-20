-- checks/all.sqlc, restricted to the rows that fail.
SELECT c.rule, c.filing, c.layer, c.detail
FROM (
    SELECT * FROM checks.all
) c
WHERE c.violates
ORDER BY 1, 2, 3
