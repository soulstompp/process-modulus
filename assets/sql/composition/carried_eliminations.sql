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
