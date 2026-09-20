-- layers/quantities.sqlc folded to one row per layer: how many units its quantities name.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/quantities' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE x.units > 0) > 0
           AND count(*) FILTER (WHERE x.units > 1) = 0                               AS holds,
           format('%s layer(s) file a quantity, %s state a unit, %s state more than one%s',
                  count(*), count(*) FILTER (WHERE x.units > 0),
                  count(*) FILTER (WHERE x.units > 1),
                  coalesce(': ' || string_agg(x.filing || '/' || x.layer, ', '
                                              ORDER BY x.filing, x.layer)
                                   FILTER (WHERE x.units > 1), ''))                  AS detail
    FROM (
        SELECT q.filing, q.layer, count(DISTINCT q.unit) AS units
        FROM      (
            SELECT * FROM layers.quantities
        ) q
        GROUP BY q.filing, q.layer
    ) x
    UNION ALL
    SELECT 'composition/part_quantities',
           count(*) > 0
           AND count(*) FILTER (WHERE y.stated) > 0
           AND count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin) = 0            AS holds,
           format('%s part(s), %s with a stated factor, %s of those file no nameplate%s',
                  count(*), count(*) FILTER (WHERE y.stated),
                  count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin),
                  coalesce(': ' || string_agg(y.composition || '/' || y.part_layer, ', '
                                              ORDER BY y.composition, y.part_layer)
                                   FILTER (WHERE y.stated AND NOT y.at_the_pin), ''))
    FROM (
        SELECT r.composition, r.composed_layer, r.part_filing, r.part_layer,
               bool_or(r.factor_state = 'stated')  AS stated,
               bool_or(r.quantity = 'nameplate')   AS at_the_pin
        FROM      (
            SELECT * FROM composition.part_quantities
        ) r
        GROUP BY r.composition, r.composed_layer, r.part_filing, r.part_layer
    ) y
) p ON true
WHERE a.slug = 'layer_units'
