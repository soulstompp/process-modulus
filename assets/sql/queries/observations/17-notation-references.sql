-- §17 Every operation beside the notation position it names, or the fact that it names none.
-- entries/operations.sqlc against entries/notation_references.sqlc, the whole beside the part.
SELECT o.filing                                       AS "filing!",
       o.label                                        AS "label!",
       coalesce(r.foreign_notation, '')               AS "notation!",
       coalesce(r.foreign_id, '')                     AS "node!",
       -- ⛔ NOT `coalesce(reason, 'stated')`: the two arms are exclusive by CHECK, so a row with
       --   neither is a load that should not have happened, and printing a word for it here would
       --   be this query answering for the document.
       coalesce(o.foreign_absent, '')                 AS "why_not!",
       (r.filing IS NOT NULL)                         AS "crosses!"
FROM      (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
-- ⚠️ `foreign_absent` AS TEXT, for `diagrams/searches.sqlc`'s reason: an emitter reads this and
--    a Postgres enum has no built-in mapping on the Rust side. The type still guards the INSERT,
--    which is where a wrong word has to be caught. `epistemics/absences.sqlc` casts it back.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

) o
LEFT JOIN (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
-- ⚠️ `foreign_absent` AS TEXT, for `diagrams/searches.sqlc`'s reason: an emitter reads this and
--    a Postgres enum has no built-in mapping on the Rust side. The type still guards the INSERT,
--    which is where a wrong word has to be caught. `epistemics/absences.sqlc` casts it back.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o
 ) o
WHERE o.foreign_notation IS NOT NULL

) r USING (filing, label)
ORDER BY (r.filing IS NOT NULL) DESC, 1, 2
