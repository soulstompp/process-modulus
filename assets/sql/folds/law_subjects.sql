-- algebra/roster.sqlc against algebra/all.sqlc, one row per law.
SELECT coalesce(g.slug, w.law)                                                AS subject,
       g.slug IS NOT NULL                                                     AS declared,
       count(w.law)                                                           AS rows,
       count(w.law) FILTER (WHERE w.holds IS NOT NULL)                        AS answered,
       count(w.law) FILTER (WHERE w.holds)                                    AS holding,
       count(w.law) FILTER (WHERE NOT w.holds)                                AS failing,
       count(w.law) FILTER (WHERE w.holds IS NULL AND w.subject IS NOT NULL)  AS silent,
       count(w.law) FILTER (WHERE w.holds IS NULL AND w.subject IS NULL)      AS vacuous
FROM      (
    SELECT * FROM algebra.roster
) g
FULL JOIN (
    SELECT * FROM algebra.all
) w ON w.law = g.slug
GROUP BY g.slug, w.law
