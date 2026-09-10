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
