-- §11  Whether a fused supply still arrives in whole units, and where that question has no answer.
-- composition/composed_quantum.sqlc, ordered by whether the question has an answer.
SELECT c.composition                                   AS "composition!",
       c.composed_layer                                AS "composed_layer!",
       c.parts                                         AS "parts!",
       coalesce(c.unit, '(none)')                      AS "unit!",
       coalesce(c.composed_quantum::text || CASE WHEN c.spread THEN ' (at a factor''s mode)' ELSE '' END,
                '(' || c.absent || ')')                AS "quantum!"
FROM (
    SELECT * FROM composition.composed_quantum
) c
ORDER BY (c.absent IS NOT NULL) DESC, c.composition, c.composed_layer
