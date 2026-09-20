-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount plus pm:Nameplate/pm:capacitySlack.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           -- the whole draw above the whole of what the supply could make
           d.draw_low > d.n_high + d.capacity_high + 1e-9              AS violates,
           CASE WHEN d.draw_low  > d.n_high + d.capacity_high + 1e-9
                THEN format('served [%s, %s] against at most %s: the whole range is over the '
                            'line', d.draw_low, d.draw_high,
                            d.n_high + d.capacity_high)
                WHEN d.draw_high <= d.n_low + d.capacity_low + 1e-9
                THEN format('served [%s, %s] against at least %s: the whole range clears',
                            d.draw_low, d.draw_high, d.n_low + d.capacity_low)
                ELSE format('served [%s, %s] against [%s, %s]: the ranges overlap, so this '
                            'document does not settle whether the supply was overrun',
                            d.draw_low, d.draw_high,
                            d.n_low + d.capacity_low, d.n_high + d.capacity_high)
           END                                                        AS detail
    FROM (
        SELECT * FROM layers.drawn
    ) d
    WHERE d.capacity_slack IS NOT NULL
      AND d.draw_unit = d.n_unit
      AND d.capacity_unit = d.n_unit
) p ON true
WHERE r.slug = 'draw_exceeds_the_supply'
