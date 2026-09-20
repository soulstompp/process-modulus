-- eliminations/filed.sqlc against folds/part_sums.sqlc.
SELECT x.composition, x.composed_layer, x.quantity,
       x.low, x.mode, x.high, x.unit, x.absent, x.derivation, x.reason, x.claim_seq, x.crossed,
       CASE WHEN x.crossed THEN x.high ELSE x.low  END AS at_low,
       CASE WHEN x.crossed THEN x.low  ELSE x.high END AS at_high
FROM (
    SELECT e.composition, e.composed_layer, e.quantity,
           e.low, e.mode, e.high, e.unit, e.absent, e.derivation, e.reason, e.claim_seq,
           coalesce(NOT (s.sum_low  - e.low  <= s.sum_mode - e.mode
                     AND s.sum_mode - e.mode <= s.sum_high - e.high), false) AS crossed
    FROM      (
        SELECT * FROM eliminations.filed
    ) e
    LEFT JOIN (
        SELECT * FROM folds.part_sums
    ) s ON s.composition = e.composition AND s.composed_layer = e.composed_layer
       AND s.quantity = e.quantity
) x
