-- diagrams/calls.sqlc's foreign parts, and the filed layers an elimination is stated between.
SELECT DISTINCT x.composition, x.part_notation
FROM (
    SELECT c.composition, c.part_notation
    FROM ( SELECT * FROM diagrams.calls ) c
    WHERE NOT c.is_local
    UNION
    SELECT b.composition, b.notation
    FROM ( SELECT * FROM eliminations.references ) b
) x
