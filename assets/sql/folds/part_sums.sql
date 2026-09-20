-- composition/converted.sqlc folded to one row per composed layer and quantity.
SELECT c.composition, c.composed_layer, c.quantity,
       sum(c.low)  AS sum_low,
       sum(c.mode) AS sum_mode,
       sum(c.high) AS sum_high,
       count(*)    AS parts
FROM (
    SELECT * FROM composition.converted
) c
GROUP BY c.composition, c.composed_layer, c.quantity
