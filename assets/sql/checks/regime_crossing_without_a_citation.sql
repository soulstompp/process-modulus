-- composition/regime_crossings.sqlc; conformance rule "a part crossing a regime boundary files
-- what reconciles it".
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
    SELECT x.composition AS filing, x.composed_layer AS layer,
           (x.crosses AND x.instrument IS NULL) AS violates,
           CASE WHEN NOT x.crosses
                THEN format('`%s` composes `%s/%s` inside %s', x.composed_layer,
                            x.part_filing, x.part_layer, x.composed_framework)
                WHEN x.instrument IS NOT NULL
                THEN format('`%s` crosses %s to %s, reconciled by %s %s', x.composed_layer,
                            x.part_framework, x.composed_framework, x.instrument, x.clause)
                ELSE format('`%s` crosses %s to %s and cites no instrument', x.composed_layer,
                            x.part_framework, x.composed_framework)
           END AS detail
    FROM (
        --
-- composition/part_regimes.sqlc: the composer's framework for each part against the framework
-- the composition itself reports under.
SELECT x.composition, x.composed_layer, x.part_filing, x.part_layer,
       own.framework_taxonomy AS composed_taxonomy,
       own.framework_value    AS composed_framework,
       x.composer_taxonomy    AS part_taxonomy,
       x.composer_value       AS part_framework,
       (own.states = 1 AND x.composer_value IS NOT NULL)                  AS crossing_known,
       (own.states = 1 AND x.composer_value IS NOT NULL
        AND (own.framework_taxonomy, own.framework_value)
            IS DISTINCT FROM (x.composer_taxonomy, x.composer_value))     AS crosses,
       c.instrument, c.clause
FROM      (
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
-- ⛔⛔ `seq = 1` WOULD BE A GUESS THAT COULD NOT ANNOUNCE ITSELF. A filing may
--   declare more than one regime, which is the whole reason `regime` is tall, and taking the
--   first silently picks one of them. Probed by giving the composition a second declaration: the
--   crossing count did not move, which is the danger rather than the reassurance. `states`
--   counts them, and a composition reporting under two frameworks makes "the framework it
--   composes INTO" a question with two answers, so the crossing is not KNOWN rather than absent.
LEFT JOIN (
    SELECT r.filing,
           count(*) FILTER (WHERE r.framework_value IS NOT NULL) AS states,
           min(r.framework_taxonomy) AS framework_taxonomy,
           min(r.framework_value)    AS framework_value
    FROM pm.regime r GROUP BY r.filing
) own ON own.filing = x.composition
LEFT JOIN (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

) c ON c.composition = x.composition

    ) x
    WHERE x.crossing_known
) p ON true
WHERE r.slug = 'regime_crossing_without_a_citation'
