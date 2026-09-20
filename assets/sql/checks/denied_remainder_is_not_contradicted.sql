-- pm:StatedRemainder's absent branch against the layer's own pm:Demand and pm:Nameplate, from layers/figures.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           (f.d_low IS NOT NULL AND f.n_low IS NOT NULL)     AS violates,
           CASE WHEN f.d_low IS NULL OR f.n_low IS NULL
                THEN format('`%s`, and no remainder is derivable: %s',
                            d.reason,
                            CASE WHEN f.d_low IS NULL THEN 'no demand is stated'
                                 ELSE 'no nameplate is stated' END)
                ELSE format('`%s`, yet demand [%s, %s] against a nameplate of [%s, %s] '
                            'gives a remainder the filing supplies itself',
                            d.reason, f.d_low, f.d_high, f.n_low, f.n_high)
           END AS detail
    FROM      (
        SELECT * FROM layers.denied_remainders
    ) d
    LEFT JOIN (
        SELECT * FROM layers.figures
    ) f USING (filing, layer)
) p ON true
WHERE r.slug = 'denied_remainder_is_not_contradicted'
