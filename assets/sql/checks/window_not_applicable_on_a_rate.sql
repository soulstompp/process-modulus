-- pm:Divisibility/window with pm:Absent reason="notApplicable", against pm:Claim/pm:denominator.
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
  ('denied_remainder_is_not_contradicted',
                                          'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, rule)

) r
LEFT JOIN (
    SELECT w.filing, w.layer,
           r.filing IS NOT NULL AS violates,
           CASE WHEN r.filing IS NOT NULL
                THEN format('%s runs on a period, so the duty cycle question is answerable',
                            w.amount_unit)
                ELSE format('%s has no period under the line, so the question really is malformed',
                            w.amount_unit)
           END AS detail
    FROM      (
        -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

    ) w
    LEFT JOIN (
        -- pm:Claim/pm:denominator/pm:period, at pm:Nameplate/amount.
SELECT c.filing, c.layer, c.unit, c.denominator AS period
FROM      (
    -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)

) c
WHERE c.owns = 'pm:amount'
  AND c.denominator_kind = 'period'

    ) r USING (filing, layer)
    WHERE w.window_absent = 'notApplicable'
      AND w.amount_unit IS NOT NULL
) p ON true
WHERE r.slug = 'window_not_applicable_on_a_rate'
