-- diagrams/domain_objects.sqlc against diagrams/catalogue.sqlc, one row per table.
SELECT coalesce(d.object, k.object) AS subject,
       d.object IS NOT NULL         AS declared,
       count(k.object)              AS rows
FROM      (
    SELECT * FROM diagrams.domain_objects
) d
FULL JOIN (
    SELECT * FROM diagrams.catalogue
) k ON k.object = d.object
GROUP BY d.object, k.object
