-- composition/fused_remainders.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/remainder_frontier.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.subject,
           x.pivoted_low <= x.pivoted_mode AND x.pivoted_mode <= x.pivoted_high
           AND x.pivoted_low >= x.cross_low - 1e-9 AND x.pivoted_high <= x.cross_high + 1e-9
           AND (NOT x.sums_agree OR abs(x.pivoted_mode - x.cross_mode) < 1e-9)
           AND (NOT x.sums_agree OR x.spread
                OR (abs(x.pivoted_low - x.cross_low) < 1e-9
                    AND abs(x.pivoted_high - x.cross_high) < 1e-9)) AS holds,
           format('pivot [%s, %s, %s] against n - d [%s, %s, %s]; %s',
                  x.pivoted_low, x.pivoted_mode, x.pivoted_high,
                  x.cross_low, x.cross_mode, x.cross_high,
                  CASE WHEN NOT x.sums_agree THEN 'a composed sum disagrees with its filing'
                       WHEN x.spread THEN 'a factor on the walk has width'
                       ELSE 'no factor on the walk has width' END) AS detail
    FROM (
        SELECT r.composition || ' / ' || r.composed_layer AS subject,
               r.pivoted_low, r.pivoted_mode, r.pivoted_high,
               n.n_low  - d.d_high AS cross_low,
               n.n_mode - d.d_mode AS cross_mode,
               n.n_high - d.d_low  AS cross_high,
               EXISTS (SELECT 1 FROM ( SELECT * FROM composition.remainder_frontier ) w
                        WHERE w.root_filing = r.composition AND w.root_layer = r.composed_layer
                          AND w.factor_low IS DISTINCT FROM w.factor_high) AS spread,
               NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fused ) f
                            WHERE f.composition = r.composition
                              AND f.composed_layer = r.composed_layer
                              AND f.quantity IN ('demand', 'nameplate')
                              AND NOT f.agrees) AS sums_agree
        FROM      (
            SELECT * FROM composition.fused_remainders
        ) r
        JOIN      (
            SELECT * FROM layers.demand
        ) d ON d.filing = r.composition AND d.layer = r.composed_layer
        JOIN      (
            SELECT * FROM layers.nameplate
        ) n ON n.filing = r.composition AND n.layer = r.composed_layer
    ) x
) p ON true
WHERE a.slug = 'composed_remainder'
