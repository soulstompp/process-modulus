-- composition/settled_remainders.sqlc against layers/differenced_remainder.sqlc at the node the
-- walk stops on, one row per settled node.
SELECT s.composition, s.composed_layer, s.node_filing, s.node_layer, s.depth,
       s.factor_low, s.factor_mode, s.factor_high, s.spread_factor,
       b.r_low  AS operand_low,
       b.r_mode AS operand_mode,
       b.r_high AS operand_high,
       s.r_low  AS converted_low,
       s.r_mode AS converted_mode,
       s.r_high AS converted_high,
       b.r_low  * s.factor_low  AS bound_by_bound_low,
       b.r_high * s.factor_high AS bound_by_bound_high,
       CASE WHEN b.r_low  < 0 THEN 'the factor high' ELSE 'the factor low'  END AS low_took,
       CASE WHEN b.r_high < 0 THEN 'the factor low'  ELSE 'the factor high' END AS high_took,
       (abs(s.r_low  - b.r_low  * s.factor_low)  > 1e-9
        OR abs(s.r_high - b.r_high * s.factor_high) > 1e-9) AS corner_rule_bites
FROM      (
    SELECT * FROM composition.settled_remainders
) s
JOIN      (
    SELECT * FROM layers.differenced_remainder
) b ON b.filing = s.node_filing AND b.layer = s.node_layer
