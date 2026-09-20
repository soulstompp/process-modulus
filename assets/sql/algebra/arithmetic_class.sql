-- arithmetic/all.sqlc, one candidate to exactly one verdict.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT z.site AS subject,
           count(*) FILTER (WHERE z.classes <> 1) = 0 AS holds,
           format('%s candidates, %s in exactly one class', count(*),
                  count(*) FILTER (WHERE z.classes = 1)) AS detail
    FROM ( SELECT site, filing, layer,
                  count(*) FILTER (WHERE w.verdict IS NOT NULL) AS classes
           FROM ( SELECT * FROM arithmetic.all ) w
           GROUP BY site, filing, layer ) z
    GROUP BY z.site
) p ON true
WHERE a.slug = 'arithmetic_class'
