-- folds/part_sums.sqlc against the composed layer's own figure, less eliminations/paired.sqlc at its corners.
SELECT x.composition, x.composed_layer, x.quantity,
       x.sum_low, x.sum_mode, x.sum_high, x.crossed,
       x.sum_low  - x.e_at_low  AS computed_low,
       x.sum_mode - x.e_mode    AS computed_mode,
       x.sum_high - x.e_at_high AS computed_high,
       x.filed_low, x.filed_mode, x.filed_high,
       (x.sum_low  - x.e_at_low  = x.filed_low
    AND x.sum_mode - x.e_mode    = x.filed_mode
    AND x.sum_high - x.e_at_high = x.filed_high) AS agrees
FROM (
    SELECT s.composition, s.composed_layer, s.quantity,
           s.sum_low, s.sum_mode, s.sum_high,
           coalesce(e.crossed, false) AS crossed,
           coalesce(e.at_low,  0) AS e_at_low,
           coalesce(e.mode,    0) AS e_mode,
           coalesce(e.at_high, 0) AS e_at_high,
           d.low  AS filed_low,
           d.mode AS filed_mode,
           d.high AS filed_high
    FROM      (
        SELECT * FROM folds.part_sums
    ) s
    JOIN      (
        SELECT * FROM composition.owed_equality
    ) o
           ON o.filing = s.composition AND o.layer = s.composed_layer
          AND o.quantity = s.quantity
    JOIN      (
        SELECT * FROM layers.summed_quantities
    ) d
           ON d.filing = s.composition AND d.layer = s.composed_layer
          AND d.quantity = s.quantity
    LEFT JOIN (
        SELECT * FROM eliminations.paired
    ) e
           ON e.composition = s.composition
          AND e.composed_layer = s.composed_layer
          AND e.quantity = s.quantity
) x
