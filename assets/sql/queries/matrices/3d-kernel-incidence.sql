-- §3d The incidence and the diagonal, as the two things whose product has a null space.
-- asrt:Fusion/asrt:Part resolved, projected to the incidence and its diagonal.
SELECT p.composition                             AS "composition!",
       p.composed_layer                          AS "composed_layer!",
       p.part_filing || '/' || p.part_layer      AS "part!",
       CASE WHEN p.factor_state = 'omitted' THEN 1::double precision
            ELSE p.factor_mode::double precision END AS factor
FROM (
    SELECT * FROM composition.parts
) p
ORDER BY p.composition, p.composed_layer, "part!"
