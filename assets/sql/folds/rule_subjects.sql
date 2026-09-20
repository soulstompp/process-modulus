-- checks/roster.sqlc against checks/all.sqlc, one row per rule.
SELECT coalesce(r.rule, c.rule)                                                 AS subject,
       r.rule IS NOT NULL                                                       AS declared,
       count(c.rule)                                                            AS rows,
       count(c.rule) FILTER (WHERE c.violates IS NOT NULL)                      AS answered,
       count(c.rule) FILTER (WHERE c.violates)                                  AS violated,
       count(c.rule) FILTER (WHERE NOT c.violates)                              AS passed,
       count(c.rule) FILTER (WHERE c.violates IS NULL AND c.filing IS NOT NULL) AS silent,
       count(c.rule) FILTER (WHERE c.violates IS NULL AND c.filing IS NULL)     AS vacuous
FROM      (
    SELECT * FROM checks.roster
) r
FULL JOIN (
    SELECT * FROM checks.all
) c ON c.rule = r.rule
GROUP BY r.rule, c.rule
