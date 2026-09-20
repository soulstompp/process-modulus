-- layers/remainder.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/fused_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           r.exposure = CASE WHEN r.pivoted THEN greatest(-f.pivoted_low, 0)
                             ELSE greatest(d.d_high - n.n_low, 0) END
           AND (r.exposure = 0) = (r.derived_fit = 'clearance')
           AND r.exposure <= r.m_high AS holds,
           format('exposure %s from %s; %s; |r| at most %s',
                  r.exposure,
                  CASE WHEN r.pivoted THEN format('the pivoted low %s', f.pivoted_low)
                       ELSE format('d_high %s against n_low %s', d.d_high, n.n_low) END,
                  r.derived_fit, r.m_high) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM layers.demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
    LEFT JOIN (
        SELECT * FROM composition.fused_remainders
    ) f ON f.composition = r.filing AND f.composed_layer = r.layer
) p ON true
WHERE a.slug = 'exposure'
