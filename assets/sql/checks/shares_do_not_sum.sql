-- pm:Remainder/pm:holder summed against |r| at the mode, via entries/holder_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    -- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees',                        'sign agrees with the range comparison'),
  ('shares_do_not_sum',                    'stated shares sum to the magnitude'),
  ('nobody_named_as_unserved',             'a supply with nowhere to put its excess names who went unserved'),
  ('exposure_unaccounted',                 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack',                  'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch',                  'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch',                'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple',             'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply',              'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved',              'a clearance fit rules out customer and unrealised'),
  ('unresolved_part',                      'a part reference resolves to a filing that is here'),
  ('leaf_reached_twice',                   'no leaf layer is reachable through two paths'),
  ('coupling_does_not_attenuate',          'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value',                'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range',                  'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range',             'a point value does not say its bound is where the measurements fell'),
  ('window_lost_or_summed',                'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window',          'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate',      'a window is notApplicable only where the unit has no period under the line'),
  ('elimination_not_applicable_with_parts','a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees',                 'a composed demand equals the sum of its converted parts less its eliminations'),
  ('local_part_dangles',                   'a local part names a layer in its own stack'),
  ('local_cycle',                          'local parts do not cycle'),
  ('one_part_fusion_alters_its_part',    'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted',
                                          'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, rule)

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
               abs(r.r_mode)  AS magnitude,
               h.shares_mode  AS shares,
               h.shares_low, h.shares_high,
               -- ⭐ |r| OVER AN INTERVAL, AND THE STRADDLE IS THE CASE THAT NEEDS SAYING. A
               --   remainder whose range crosses zero has a magnitude that reaches 0, which is
               --   the transition fit: short at the top of the demand range and spare at the
               --   bottom, both at once.
               CASE WHEN r.r_low <= 0 AND r.r_high >= 0 THEN 0
                    ELSE least(abs(r.r_low), abs(r.r_high)) END       AS mag_low,
               greatest(abs(r.r_low), abs(r.r_high))                  AS mag_high
        FROM      (
            -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

        ) r
        JOIN      (
            -- entries/holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                     AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)  AS unstated,
       sum(h.share_low)                              AS shares_low,
       sum(h.share_mode)                             AS shares_mode,
       sum(h.share_high)                             AS shares_high,
       array_agg(DISTINCT h.share_unit)              AS share_units
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
GROUP BY h.filing, h.layer

        ) h USING (filing, layer)
        WHERE h.unstated = 0
          AND h.share_units = ARRAY[r.unit]
    ) x
) p ON true
WHERE r.slug = 'shares_do_not_sum'
