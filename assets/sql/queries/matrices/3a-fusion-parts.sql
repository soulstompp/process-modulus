-- §3  The parts going into each composed layer, with their conversion factors, per quantity.
-- composition/parts.sqlc against composition/resolved_quantities.sqlc; F and Phi live in one table.
SELECT p.composition                      AS "composition!",
       p.composed_layer                   AS "composed!",
       s.quantity::text                   AS "quantity!",
       coalesce(p.factor_low, 1)::float8  AS "f_low!",
       coalesce(p.factor_mode, 1)::float8 AS "f_mode!",
       coalesce(p.factor_high, 1)::float8 AS "f_high!",
       s.low::float8                      AS "x_low!",
       s.mode::float8                     AS "x_mode!",
       s.high::float8                     AS "x_high!"
FROM (
    SELECT * FROM composition.parts
) p
JOIN (
    SELECT * FROM composition.resolved_quantities
) s
  ON s.filing = p.part_filing AND s.layer = p.part_layer
 AND s.low IS NOT NULL
WHERE p.factor_state IN ('omitted', 'stated')
ORDER BY s.quantity, p.composition, p.composed_layer, p.part_layer
