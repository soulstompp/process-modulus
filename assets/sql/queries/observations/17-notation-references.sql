-- §17 Every operation beside the notation position it names, or the fact that it names none.
-- entries/operations.sqlc against entries/notation_references.sqlc, the whole beside the part.
SELECT o.filing                                       AS "filing!",
       o.label                                        AS "label!",
       coalesce(r.foreign_notation, '')               AS "notation!",
       coalesce(r.foreign_id, '')                     AS "node!",
       coalesce(o.foreign_absent, '')                 AS "why_not!",
       (r.filing IS NOT NULL)                         AS "crosses!"
FROM      (
    SELECT * FROM entries.operations
) o
LEFT JOIN (
    SELECT * FROM entries.notation_references
) r USING (filing, label)
ORDER BY (r.filing IS NOT NULL) DESC, 1, 2
