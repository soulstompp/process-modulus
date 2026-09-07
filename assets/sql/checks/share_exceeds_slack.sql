-- pm:Remainder/pm:holder against the three slack elements, keyed by pm:Remainder/pm:absorber through pm.buffer_term.
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
  ('jagged_layer',                       'a fusion''s parts partition what they compose'),
  ('layers_move_together',               'layers that always move together are one layer'),
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
  ('unit_crossing_without_a_factor',      'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees',              'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close',     'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part',    'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted',
                                          'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, rule)

) r
LEFT JOIN (
    SELECT b.filing, b.layer,
           coalesce(b.borne > b.slack_mode + 1e-9, false) AS violates,
           format('%s attributed to the %s buffer, whose slack is %s',
                  b.borne, b.buffer, b.slack_mode) AS detail
    FROM (
        -- pm:Remainder/pm:holder summed against the slack it names, keyed by pm:Remainder/pm:absorber.
SELECT b.filing, b.layer, b.buffer, b.borne, s.mode AS slack_mode, s.unit AS slack_unit
FROM (
    SELECT p.filing, p.layer, a.buffer, sum(h.share_mode) AS borne
    FROM      (
        -- pm:Remainder/sign in {interference, transition}.
SELECT r.*
FROM (
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
WHERE r.sign IN ('interference', 'transition')

    ) p
    JOIN      (
        -- pm:Remainder/absorber, resolved through pm.buffer_term.
SELECT l.filing, l.layer,
       l.absorber_taxonomy AS taxonomy,
       l.absorber_value    AS term,
       bt.buffer,
       bt.note AS the_readers_warrant
FROM pm.layer l
JOIN pm.buffer_term bt ON bt.taxonomy = l.absorber_taxonomy AND bt.value = l.absorber_value

    ) a USING (filing, layer)
    JOIN      (
        -- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
WHERE h.kind IN ('booked', 'counterparty', 'people')

    ) h USING (filing, layer)
    WHERE p.sign = 'interference'
    GROUP BY p.filing, p.layer, a.buffer
) b
JOIN (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s USING (filing, layer, buffer)
WHERE s.mode IS NOT NULL

    ) b
) p ON true
WHERE r.slug = 'share_exceeds_slack'
