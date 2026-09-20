-- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL
