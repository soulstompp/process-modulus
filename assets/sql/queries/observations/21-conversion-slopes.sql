-- §21 Which corner of the path's factor each bound of a carried remainder took, and whether it mattered.
-- composition/conversion_slopes.sqlc, ordered so any biting row reads first.
SELECT c.composition                AS "composition!",
       c.composed_layer             AS "composed_layer!",
       c.node_filing                AS "node_filing!",
       c.node_layer                 AS "node_layer!",
       c.depth                      AS "depth!",
       c.spread_factor              AS "spread_factor!",
       c.operand_low::float8        AS operand_low,
       c.operand_high::float8       AS operand_high,
       c.low_took                   AS "low_took!",
       c.high_took                  AS "high_took!",
       c.corner_rule_bites          AS corner_rule_bites
FROM (
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

) c
ORDER BY c.corner_rule_bites DESC NULLS LAST, c.spread_factor DESC, 1, 2, 4
