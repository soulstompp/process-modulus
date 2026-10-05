-- epistemics/class_domain.sqlc's occupancy claims against epistemics/classes.sqlc, one row per class.
SELECT coalesce(d.relation, c.relation) || ' / ' || coalesce(d.class, c.class) AS subject,
       d.class IS NOT NULL                                                    AS declared,
       coalesce(c.balls, 0)                                                   AS rows
FROM      (
    SELECT o.relation, o.class
    FROM ( SELECT * FROM epistemics.class_domain ) o
    WHERE o.standing = 'exercised'
) d
FULL JOIN (
    SELECT z.relation, z.class, z.balls
    FROM ( SELECT * FROM epistemics.classes ) z
    WHERE z.balls > 0
) c ON c.relation = d.relation AND c.class = d.class
