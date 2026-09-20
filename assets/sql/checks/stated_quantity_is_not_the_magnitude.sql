-- pm:Remainder/pm:quantity against |r| from layers/remainder.sqlc, via layers/filed_against_derived.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           abs(l.qty_low  - l.m_low)  > 1e-9
           OR abs(l.qty_mode - l.m_mode) > 1e-9
           OR abs(l.qty_high - l.m_high) > 1e-9                           AS violates,
           format('stated [%s, %s, %s] against a magnitude of [%s, %s, %s]',
                  l.qty_low, l.qty_mode, l.qty_high, l.m_low, l.m_mode, l.m_high) AS detail
    FROM (
        SELECT * FROM layers.filed_against_derived
    ) l
    WHERE l.qty_low IS NOT NULL
      AND l.qty_unit = l.unit
) p ON true
WHERE r.slug = 'stated_quantity_is_not_the_magnitude'
