-- §3  Every classification this tree makes, against the set of classes it declares.
-- epistemics/classes.sqlc beside its declared standings, in each type's declared order.
SELECT c.relation AS "relation!", c.codomain AS "codomain!", c.class AS "class!",
       c.subject AS "subject?", c.balls AS "balls!",
       d.standing::text AS "standing?", d.reason AS "reason?"
FROM      (
    SELECT * FROM epistemics.classes
) c
LEFT JOIN (
    SELECT * FROM epistemics.class_domain
) d ON d.relation = c.relation AND d.class = c.class
ORDER BY c.relation, c.ord
