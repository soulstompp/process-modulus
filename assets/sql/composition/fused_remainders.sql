-- composition/settled_remainders.sqlc summed over the settled frontier, less eliminations/paired.sqlc at their own corners.
SELECT y.composition, y.composed_layer,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_low  ELSE y.r_low  - y.n_high + y.d_low  END AS pivoted_low,
       y.pivoted_mode,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_high ELSE y.r_high - y.n_low  + y.d_high END AS pivoted_high,
       y.derived_low, y.derived_mode, y.derived_high, y.derived_fit, y.unit, y.parts, y.spread
FROM (
    SELECT x.*,
           x.r_low  - x.n_at_low
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_low  ELSE x.d_at_high END AS paired_low,
           x.r_mode - x.n_mode + x.d_mode                                            AS pivoted_mode,
           x.r_high - x.n_at_high
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_high ELSE x.d_at_low  END AS paired_high,
           least(x.n_at_low, x.n_at_high)    AS n_low,
           greatest(x.n_at_low, x.n_at_high) AS n_high,
           least(x.d_at_low, x.d_at_high)    AS d_low,
           greatest(x.d_at_low, x.d_at_high) AS d_high
    FROM (
        SELECT c.composition, c.composed_layer,
               sum(c.r_low)  AS r_low,
               sum(c.r_mode) AS r_mode,
               sum(c.r_high) AS r_high,
               bool_or(c.spread_factor) AS spread,
               coalesce(max(e.n_at_low),  0) + coalesce(max(k.n_low),  0) AS n_at_low,
               coalesce(max(e.n_mode),    0) + coalesce(max(k.n_mode), 0) AS n_mode,
               coalesce(max(e.n_at_high), 0) + coalesce(max(k.n_high), 0) AS n_at_high,
               coalesce(max(e.d_at_low),  0) + coalesce(max(k.d_low),  0) AS d_at_low,
               coalesce(max(e.d_mode),    0) + coalesce(max(k.d_mode), 0) AS d_mode,
               coalesce(max(e.d_at_high), 0) + coalesce(max(k.d_high), 0) AS d_at_high,
               max(d.r_low)  AS derived_low,
               max(d.r_mode) AS derived_mode,
               max(d.r_high) AS derived_high,
               max(d.derived_fit) AS derived_fit,
               max(d.unit)   AS unit,
               count(*)      AS parts
        FROM      (
            SELECT * FROM composition.settled_remainders
        ) c
        JOIN      (
            SELECT * FROM composition.owed_remainder
        ) o  ON o.filing = c.composition AND o.layer = c.composed_layer
        JOIN      (
            SELECT * FROM layers.differenced_remainder
        ) d  ON d.filing = c.composition AND d.layer = c.composed_layer
        LEFT JOIN (
            SELECT p.composition, p.composed_layer,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'nameplate') AS n_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'nameplate') AS n_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'nameplate') AS n_at_high,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'demand')    AS d_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'demand')    AS d_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'demand')    AS d_at_high
            FROM (
                SELECT * FROM eliminations.paired
            ) p
            GROUP BY p.composition, p.composed_layer
        ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
        LEFT JOIN (
            SELECT w.composition, w.composed_layer,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'nameplate') AS n_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'nameplate') AS n_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'nameplate') AS n_high,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'demand')    AS d_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'demand')    AS d_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'demand')    AS d_high
            FROM (
                -- eliminations/paired.sqlc at the nodes composition/passed_nodes.sqlc names, along a usable path.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer, e.quantity,
       count(*)                                                        AS through_layers,
       sum(least(   e.at_low  * w.factor_low, e.at_low  * w.factor_high)) AS e_low,
       sum(e.mode * w.factor_mode)                                     AS e_mode,
       sum(greatest(e.at_high * w.factor_low, e.at_high * w.factor_high)) AS e_high,
       bool_or(e.absent IS NOT NULL OR e.derivation IS NOT NULL)       AS unsized
FROM      (
    SELECT * FROM composition.passed_nodes
) w
JOIN      (
    SELECT * FROM eliminations.paired
) e ON e.composition = w.filing AND e.composed_layer = w.layer
WHERE w.usable
GROUP BY w.root_filing, w.root_layer, e.quantity

            ) w
            GROUP BY w.composition, w.composed_layer
        ) k ON k.composition = c.composition AND k.composed_layer = c.composed_layer
        GROUP BY c.composition, c.composed_layer
    ) x
) y
