-- layers/remainder.sqlc against layers/demand.sqlc and layers/nameplate.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           (r.pivoted OR (r.r_low  = n.n_low  - d.d_high
                      AND r.r_mode = n.n_mode - d.d_mode
                      AND r.r_high = n.n_high - d.d_low))
           AND r.r_low <= r.r_mode AND r.r_mode <= r.r_high
           AND (r.derived_fit = 'clearance')    = (r.r_low >= 0)
           AND (r.derived_fit = 'interference') = (r.r_high <= 0 AND r.r_low < 0)
           AND (r.derived_fit = 'transition')   = (r.r_low < 0 AND r.r_high > 0)
           AND r.m_low  = greatest(r.r_low, -r.r_high, 0)
           AND r.m_mode = abs(r.r_mode)
           AND r.m_high = greatest(r.r_high, -r.r_low) AS holds,
           format('%s [%s, %s, %s] from n [%s, %s, %s] and d [%s, %s, %s]; %s; |r| [%s, %s, %s]',
                  CASE WHEN r.pivoted THEN 'pivoted r' ELSE 'r' END,
                  r.r_low, r.r_mode, r.r_high, n.n_low, n.n_mode, n.n_high,
                  d.d_low, d.d_mode, d.d_high, r.derived_fit, r.m_low, r.m_mode, r.m_high) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM layers.demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
) p ON true
WHERE a.slug = 'crossed_remainder'
