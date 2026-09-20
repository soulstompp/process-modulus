-- composition/remainder_frontier.sqlc less the nodes composition/unsettled.sqlc names,
-- against layers/differenced_remainder.sqlc at the node the walk stops on.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer,
       w.filing AS node_filing, w.layer AS node_layer, w.depth,
       w.factor_low, w.factor_mode, w.factor_high,
       least(   r.r_low  * w.factor_low, r.r_low  * w.factor_high) AS r_low,
       r.r_mode * w.factor_mode                                    AS r_mode,
       greatest(r.r_high * w.factor_low, r.r_high * w.factor_high) AS r_high,
       (w.factor_low IS DISTINCT FROM w.factor_high)               AS spread_factor
FROM      (
    SELECT * FROM composition.remainder_frontier
) w
JOIN      (
    SELECT * FROM layers.differenced_remainder
) r ON r.filing = w.filing AND r.layer = w.layer
LEFT JOIN (
    SELECT * FROM composition.unsettled
) o ON o.filing = w.filing AND o.layer = w.layer
WHERE w.usable
  AND o.filing IS NULL
