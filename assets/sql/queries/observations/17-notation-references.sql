-- §17 Every operation beside the notation position it names, or the fact that it names none.
-- entries/operations.sqlc against entries/notation_references.sqlc, the whole beside the part.
WITH entries_operations AS (
-- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o
),
entries_notation_references AS (
-- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM entries_operations ) o
WHERE o.foreign_notation IS NOT NULL
)
SELECT o.filing                                       AS "filing!",
       o.label                                        AS "label!",
       coalesce(r.foreign_notation, '')               AS "notation!",
       coalesce(r.foreign_id, '')                     AS "node!",
       coalesce(o.foreign_absent, '')                 AS "why_not!",
       (r.filing IS NOT NULL)                         AS "crosses!"
FROM      (
    SELECT * FROM entries_operations
) o
LEFT JOIN (
    SELECT * FROM entries_notation_references
) r USING (filing, label)
ORDER BY (r.filing IS NOT NULL) DESC, 1, 2
