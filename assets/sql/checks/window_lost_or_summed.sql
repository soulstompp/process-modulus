-- pm:Part's pm:Divisibility/window against the composed pm:Layer's.
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
  ('conversion_cycle_does_not_close',     'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part',    'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted',
                                          'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, rule)

) r
LEFT JOIN (
    SELECT w.composition AS filing, w.composed_layer AS layer,
           (w.composed_window_low IS NULL
            OR w.composed_window_low <> w.window_low) AS violates,
           CASE WHEN w.composed_window_low IS NULL
                THEN format('the part %s/%s files a %s-%s duty cycle and the composed '
                            'layer files `%s`', w.part_filing, w.part_layer, w.window_low,
                            w.window_unit, w.composed_window_absent)
                ELSE format('composed window %s against a part''s %s -- carried, never summed',
                            w.composed_window_low, w.window_low)
           END AS detail
    FROM (
        -- pm:Part's own pm:Divisibility/window against the composed pm:Layer's.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       pw.window_low, pw.window_unit,
       cw.window_low    AS composed_window_low,
       cw.window_absent AS composed_window_absent
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN      (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) cw
       ON cw.filing = p.composition  AND cw.layer = p.composed_layer
WHERE pw.window_low IS NOT NULL

    ) w
) p ON true
WHERE r.slug = 'window_lost_or_summed'
