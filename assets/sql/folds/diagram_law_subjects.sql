-- diagrams/roster.sqlc against diagrams/expected.sqlc, one row per diagram law.
SELECT coalesce(l.slug, e.slug)     AS subject,
       l.slug IS NOT NULL           AS declared,
       count(e.slug)                AS rows
FROM      (
    SELECT * FROM diagrams.roster
) l
FULL JOIN (
    SELECT * FROM diagrams.expected
) e ON e.slug = l.slug
GROUP BY l.slug, e.slug
