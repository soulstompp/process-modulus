-- arithmetic/roster.sqlc against arithmetic/all.sqlc, one row per site.
SELECT coalesce(a.site, z.site)                                                AS subject,
       a.site IS NOT NULL                                                      AS declared,
       count(z.site)                                                           AS rows,
       count(z.site) FILTER (WHERE z.verdict IS NOT NULL)                      AS answered,
       count(z.site) FILTER (WHERE z.verdict = 'computable')                   AS computable,
       count(z.site) FILTER (WHERE z.verdict = 'suspended')                    AS suspended,
       count(z.site) FILTER (WHERE z.verdict = 'not comparable')               AS not_comparable,
       count(z.site) FILTER (WHERE z.verdict IS NULL AND z.filing IS NOT NULL) AS silent,
       count(z.site) FILTER (WHERE z.verdict IS NULL AND z.filing IS NULL)     AS vacuous
FROM      (
    SELECT * FROM arithmetic.roster
) a
FULL JOIN (
    SELECT * FROM arithmetic.all
) z ON z.site = a.site
GROUP BY a.site, z.site
