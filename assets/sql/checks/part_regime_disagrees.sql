-- composition/part_regimes.sqlc; conformance rule "a composer's regime for a part is one that
-- part's own filing declares".
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
    SELECT x.composition AS filing, x.composed_layer AS layer,
           NOT x.agrees AS violates,
           CASE WHEN x.agrees
                THEN format('`%s` is under `%s` and `%s` declares it', x.part_layer,
                            x.composer_value, x.part_filing)
                ELSE format('the composer puts `%s/%s` under `%s` (%s), and that filing declares %s framework(s), none of them this one',
                            x.part_filing, x.part_layer, x.composer_value,
                            x.composer_taxonomy, x.frameworks_the_filing_states)
           END AS detail
    FROM (
        -- pm.part's regime handle resolved into pm.composition_regime, against the part filing's own pm.regime.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_taxonomy IS NOT NULL AND EXISTS (
            SELECT 1 FROM pm.regime r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*) FROM pm.regime r WHERE r.filing = p.part_filing
          AND r.framework_taxonomy IS NOT NULL)                          AS frameworks_the_filing_states
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
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
JOIN pm.composition_regime cr
  ON cr.composition = p.composition AND cr.id = p.part_regime

    ) x
    WHERE x.composer_absent IS NULL
      AND x.frameworks_the_filing_states > 0
) p ON true
WHERE r.slug = 'part_regime_disagrees'
