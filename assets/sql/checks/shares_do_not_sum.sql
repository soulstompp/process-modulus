-- pm:Remainder/pm:holder summed against |r| from layers/remainder.sqlc, via entries/holder_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT x.filing, x.layer,
           abs(x.shares - x.magnitude) > 1e-9
           OR x.shares_low  < x.mag_low  - 1e-9
           OR x.shares_high > x.mag_high + 1e-9                       AS violates,
           format('shares [%s, %s, %s] against a magnitude of [%s, %s, %s]',
                  x.shares_low, x.shares, x.shares_high,
                  x.mag_low, x.magnitude, x.mag_high)                 AS detail
    FROM (
        SELECT r.filing, r.layer,
               r.m_mode       AS magnitude,
               h.shares_mode  AS shares,
               h.shares_low, h.shares_high,
               r.m_low        AS mag_low,
               r.m_high       AS mag_high
        FROM      (
            SELECT * FROM layers.remainder
        ) r
        JOIN      (
            SELECT * FROM entries.holder_totals
        ) h USING (filing, layer)
        WHERE h.unstated = 0
          AND h.share_units = ARRAY[r.unit]
    ) x
) p ON true
WHERE r.slug = 'shares_do_not_sum'
