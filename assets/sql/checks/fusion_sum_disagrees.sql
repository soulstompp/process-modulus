-- asrt:Fusion/asrt:Part summed against the composed layer's demand, nameplate and draw, via composition/fused.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT f.composition AS filing, f.composed_layer AS layer,
           bool_or(NOT f.agrees) AS violates,
           string_agg(format('%s: parts less eliminations give [%s, %s, %s]; the filing states [%s, %s, %s]',
                             f.quantity, f.computed_low, f.computed_mode, f.computed_high,
                             f.filed_low, f.filed_mode, f.filed_high),
                      '; ' ORDER BY f.quantity) AS detail
    FROM (
        SELECT * FROM composition.fused
    ) f
    GROUP BY f.composition, f.composed_layer
) p ON true
WHERE r.slug = 'fusion_sum_disagrees'
