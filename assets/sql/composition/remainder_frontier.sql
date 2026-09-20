-- composition/parts.sqlc walked while composition/unsettled.sqlc holds, carrying the product.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition.parts
),
open_node AS (
    SELECT * FROM composition.unsettled
),
frontier(root_filing, root_layer, filing, layer, depth,
         factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation')
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation')
        FROM frontier w
        JOIN open_node o ON o.filing = w.filing AND o.layer = w.layer
        JOIN resolved p  ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT f.root_filing, f.root_layer, f.filing, f.layer, f.depth,
       f.factor_low, f.factor_mode, f.factor_high, f.factor_absent, f.is_cycle,
       (NOT f.factor_absent AND NOT f.is_cycle) AS usable
FROM frontier f
