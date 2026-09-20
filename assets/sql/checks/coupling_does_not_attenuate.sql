-- pm:Coupling at two levels related through asrt:Fusion/asrt:Part; see composition/attenuated.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT a.upper_filing AS filing, a.from_layer AS layer,
           coalesce(a.low  > a.ceil_low  + 1e-9, false)
        OR coalesce(a.mode > a.ceil_mode + 1e-9, false)
        OR coalesce(a.high > a.ceil_high + 1e-9, false) AS violates,
           format('%s->%s files [%s, %s, %s]; %s''s coupling at a share of at most %s caps it at [%s, %s, %s]',
                  a.from_layer, a.to_layer, a.low, a.mode, a.high, a.lower_filing,
                  round(a.share, 3), round(a.ceil_low, 3), round(a.ceil_mode, 3),
                  round(a.ceil_high, 3)) AS detail
    FROM (
        -- pm:Coupling at two levels, related through asrt:Fusion/asrt:Part, capped by the part's nameplate share.
SELECT x.upper_filing, x.from_layer, x.to_layer, x.lower_filing, x.share,
       x.lo_low  * x.share AS ceil_low,
       x.lo_mode * x.share AS ceil_mode,
       x.lo_high * x.share AS ceil_high,
       x.low, x.mode, x.high
FROM (
    SELECT up.filing AS upper_filing, up.from_layer, up.to_layer,
           lo.filing AS lower_filing,
           lo.low AS lo_low, lo.mode AS lo_mode, lo.high AS lo_high,
           pn.n_high * coalesce(pf.factor_high, 1) / cn.n_low AS share,
           up.low, up.mode, up.high
    FROM      (
        SELECT * FROM entries.couplings
    ) up
    JOIN      (
        SELECT * FROM composition.parts
    ) pf
           ON pf.composition = up.filing AND pf.composed_layer = up.from_layer
    JOIN      (
        SELECT * FROM entries.couplings
    ) lo
           ON lo.filing = pf.part_filing AND lo.from_layer = pf.part_layer
    JOIN      (
        SELECT * FROM composition.parts
    ) pt
           ON pt.composition = up.filing AND pt.composed_layer = up.to_layer
          AND pt.part_layer = lo.to_layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) pn
           ON pn.filing = pf.part_filing AND pn.layer = pf.part_layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) cn
           ON cn.filing = up.filing      AND cn.layer = up.from_layer
    WHERE up.mode IS NOT NULL AND lo.mode IS NOT NULL
      AND pf.factor_state IN ('omitted', 'stated')
      AND cn.n_low > 0
) x

    ) a
) p ON true
WHERE r.slug = 'coupling_does_not_attenuate'
