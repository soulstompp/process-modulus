-- §3  The SQL's own F Φ x: each owed sum of converted parts, before the elimination.
-- composition/fused.sqlc, the sums before the elimination.
SELECT f.composition        AS "composition!",
       f.composed_layer     AS "composed!",
       f.quantity::text     AS "quantity!",
       f.sum_low::float8    AS "sum_low!",
       f.sum_mode::float8   AS "sum_mode!",
       f.sum_high::float8   AS "sum_high!"
FROM (
    SELECT * FROM composition.fused
) f
ORDER BY f.quantity, f.composition, f.composed_layer
