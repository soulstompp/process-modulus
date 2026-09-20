-- every slack on the layer accounted for and empty, against entries/unserved_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT e.filing, e.layer,
           e.exposure > e.unserved + 1e-9 AS violates,
           format('exposure %s, absorbable %s, unserved %s',
                  e.exposure, e.absorbable, e.unserved) AS detail
    FROM (
        SELECT x.filing, x.layer, x.exposure, x.absorbable, u.unserved_high AS unserved
        FROM      (
            SELECT * FROM layers.unabsorbed_exposure
        ) x
        JOIN      (
            SELECT * FROM entries.unserved_totals
        ) u USING (filing, layer)
        WHERE u.unstated = 0
          AND u.share_units = ARRAY[x.unit]
    ) e
) p ON true
WHERE r.slug = 'exposure_unaccounted'
