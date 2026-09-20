-- §1  Every site the model does arithmetic at, and what guards the join.
-- arithmetic/roster.sqlc beside folds/site_subjects.sqlc, one row per declared site.
SELECT r.site                        AS "site!",
       coalesce(r.guarded_by, '')    AS "guarded_by!",
       f.computable                  AS "computable!",
       f.suspended                   AS "suspended!",
       f.not_comparable              AS "not_comparable!"
FROM (
    SELECT * FROM arithmetic.roster
) r
JOIN (
    SELECT * FROM folds.site_subjects
) f ON f.subject = r.site
ORDER BY r.slug
