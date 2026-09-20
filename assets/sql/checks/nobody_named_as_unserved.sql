-- every slack on the layer accounted for and empty, against pm:HolderKind of every holder.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           u.filing IS NULL OR (c.derived_fit = 'interference' AND s.filing IS NOT NULL) AS violates,
           CASE WHEN u.filing IS NULL
                THEN format('%s could not be served and no holder says so', c.exposure)
                WHEN c.derived_fit = 'interference' AND s.filing IS NOT NULL
                THEN format('%s could not be served, and a %s holder says part of it was',
                            c.exposure, s.kinds)
                ELSE format('%s could not be served, and the holders say who went without',
                            c.exposure)
           END AS detail
    FROM (
        SELECT e.filing, e.layer, e.exposure, e.derived_fit
        FROM (
            SELECT * FROM layers.unabsorbed_exposure
        ) e
        WHERE e.exposure > 1e-9
    ) c
    LEFT JOIN ( SELECT DISTINCT filing, layer
                FROM (
                    SELECT * FROM entries.unserved_holders
                ) h ) u USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM folds.served_totals
    ) s USING (filing, layer)
) p ON true
WHERE r.slug = 'nobody_named_as_unserved'
