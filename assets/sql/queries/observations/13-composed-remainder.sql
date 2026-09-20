-- composition/fused_remainders.sqlc, with the two figures set against each other.
SELECT f.composition                                             AS "composition!",
       f.composed_layer                                          AS "composed_layer!",
       f.parts                                                   AS "parts!",
       f.unit                                                    AS "unit!",
       f.pivoted_low::float8                                     AS "pivoted_low!",
       f.pivoted_mode::float8                                    AS "pivoted_mode!",
       f.pivoted_high::float8                                    AS "pivoted_high!",
       f.derived_low::float8                                     AS "derived_low!",
       f.derived_mode::float8                                    AS "derived_mode!",
       f.derived_high::float8                                    AS "derived_high!",
       f.spread                                                  AS "spread!",
       (f.pivoted_low = f.derived_low
    AND f.pivoted_mode = f.derived_mode
    AND f.pivoted_high = f.derived_high)                         AS "agrees!"
FROM (
    SELECT * FROM composition.fused_remainders
) f
ORDER BY "agrees!", f.composition, f.composed_layer
