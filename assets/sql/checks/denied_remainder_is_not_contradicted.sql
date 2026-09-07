--
-- pm:StatedRemainder's absent branch against the layer's own pm:Demand and pm:Nameplate.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    -- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees', 'layer', 'sign agrees with the range comparison'),
  ('shares_do_not_sum', 'layer', 'stated shares sum to the magnitude'),
  ('nobody_named_as_unserved', 'layer', 'a supply with nowhere to put its excess names who went unserved'),
  ('exposure_unaccounted', 'layer', 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack', 'layer', 'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch', 'slack', 'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch', 'layer', 'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple', 'layer', 'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply', 'layer', 'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved', 'layer', 'a clearance fit rules out customer and unrealised'),
  ('unresolved_part', 'part', 'a part reference resolves to a filing that is here'),
  ('jagged_layer', 'layer', 'a fusion''s parts partition what they compose'),
  ('layers_move_together', 'layer', 'layers that always move together are one layer'),
  ('coupling_does_not_attenuate', 'layer', 'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value', 'layer', 'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range', 'layer', 'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range', 'layer', 'a point value does not say its bound is where the measurements fell'),
  ('window_lost_or_summed', 'part', 'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window', 'layer', 'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate', 'layer', 'a window is notApplicable only where the unit has no period under the line'),
  ('elimination_not_applicable_with_parts', 'layer', 'a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees', 'layer', 'a composed demand equals the sum of its converted parts less its eliminations'),
  ('local_part_dangles', 'part', 'a local part names a layer in its own stack'),
  ('unit_crossing_without_a_factor', 'layer', 'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'part', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees', 'part', 'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close', 'layer', 'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part', 'part', 'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted', 'layer', 'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, subject, rule)

) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           (dm.d_low IS NOT NULL AND np.n_low IS NOT NULL
            AND d.reason <> 'derived')                             AS violates,
           CASE WHEN dm.d_low IS NULL OR np.n_low IS NULL
                THEN format('`%s`, and no remainder is derivable: %s',
                            d.reason,
                            CASE WHEN dm.d_low IS NULL THEN 'no demand is stated'
                                 ELSE 'no nameplate is stated' END)
                WHEN d.reason = 'derived'
                THEN format('`derived`, and demand [%s, %s] against a nameplate of [%s, %s] '
                            'is exactly what the receiver computes it from',
                            dm.d_low, dm.d_high, np.n_low, np.n_high)
                ELSE format('`%s`, yet demand [%s, %s] against a nameplate of [%s, %s] '
                            'gives a remainder the filing supplies itself',
                            d.reason, dm.d_low, dm.d_high, np.n_low, np.n_high)
           END AS detail
    FROM      (
        -- pm:Layer/pm:remainder taking the pm:absent branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.remainder_absent      AS reason,
       l.remainder_absent_note AS argument
FROM pm.layer l
WHERE l.remainder_absent IS NOT NULL

    ) d
    LEFT JOIN (
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

    ) dm USING (filing, layer)
    LEFT JOIN (
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

    ) np USING (filing, layer)
) p ON true
WHERE r.slug = 'denied_remainder_is_not_contradicted'
