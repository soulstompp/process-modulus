-- §14  Supply that enters one total twice through two of a fusion's own parts, and no elimination for it.
-- composition/jagged_layers.sqlc for fusions with no filed elimination, against the doubled layer's own figures.
SELECT j.filing                                   AS "filing!",
       j.layer                                    AS "layer!",
       j.doubled_filing || '/' || j.doubled_layer AS "doubled!",
       j.via_layer                                AS "via!",
       j.also_via_layer                           AS "also_via!",
       f.d_mode::float8                           AS "twice_demand",
       f.n_mode::float8                           AS "twice_nameplate",
       coalesce(f.d_unit, f.n_unit, '')           AS "unit!"
FROM      (
    SELECT * FROM composition.jagged_layers
) j
LEFT JOIN (
    SELECT * FROM eliminations.filed
) e ON e.composition = j.filing AND e.composed_layer = j.layer
LEFT JOIN (
    SELECT * FROM layers.figures
) f ON f.filing = j.doubled_filing AND f.layer = j.doubled_layer
WHERE e.composition IS NULL
ORDER BY j.filing, j.layer, j.doubled_filing, j.doubled_layer
