-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking pm:derivation, against the identity
-- that computes the claim.
WITH checks_roster AS (
-- the conformance rules stated in the schemas' prose and gated by no grammar.
SELECT * FROM (VALUES
  ('fit_disagrees', 'layer', 'sign agrees with the range comparison'),
  ('shares_do_not_sum', 'layer', 'stated shares sum to the magnitude'),
  ('stated_quantity_is_not_the_magnitude', 'layer', 'a stated remainder quantity is the magnitude'),
  ('nobody_named_as_unserved', 'layer', 'a supply with nowhere to put its excess names who went unserved, and under interference names nobody else'),
  ('exposure_unaccounted', 'layer', 'exposure does not exceed slack plus unserved shares'),
  ('share_exceeds_slack', 'layer', 'a share does not exceed the slack of the buffer that absorbed it'),
  ('slack_unit_mismatch', 'slack', 'a slack is expressed in the unit of the shares it bounds'),
  ('quantum_unit_mismatch', 'layer', 'a quantum is expressed in the unit of the nameplate it divides'),
  ('nameplate_not_a_multiple', 'layer', 'the nameplate is a whole multiple of the quantum'),
  ('draw_exceeds_the_supply', 'layer', 'a draw does not exceed what the supply can make'),
  ('clearance_with_unserved', 'layer', 'a clearance fit rules out customer and unrealised'),
  ('unresolved_part', 'part', 'a part reference resolves to a filing that is here'),
  ('jagged_layer', 'layer', 'a fusion''s parts do not overlap'),
  ('layers_move_together', 'layer', 'layers that always move together are one layer'),
  ('coupling_does_not_attenuate', 'layer', 'a coupling attenuates through a fusion, bounded by the part''s share'),
  ('narrows_a_point_value', 'claim', 'a point value files narrowsWhen as notApplicable, having no range'),
  ('range_says_no_range', 'claim', 'a ranged claim does not file narrowsWhen as notApplicable'),
  ('bound_fell_with_no_range', 'claim', 'a point value does not say its bound is where the measurements fell'),
  ('identity_does_not_compute_the_claim', 'claim', 'a claim''s edge or narrowing derives from an identity that computes the claim''s own position'),
  ('window_lost_or_summed', 'part', 'a window is carried through a fusion and never summed'),
  ('derived_slack_over_a_window', 'layer', 'a derived time slack needs a window that permits the derivation'),
  ('window_not_applicable_on_a_rate', 'layer', 'a window is notApplicable only where the unit has no period under the line'),
  ('window_size_not_applicable', 'layer', 'a window that files its live part does not call that part''s size malformed'),
  ('elimination_not_applicable_with_parts', 'layer', 'a fusion calls double counting malformed only when it has one part'),
  ('fusion_sum_disagrees', 'layer', 'a composed figure equals the sum of its converted parts less its eliminations, per quantity'),
  ('local_part_dangles', 'part', 'a local part names a layer in its own stack'),
  ('unit_crossing_without_a_factor', 'layer', 'a part crossing a unit boundary files what converts it'),
  ('regime_crossing_without_a_citation', 'part', 'a part crossing a regime boundary files what reconciles it'),
  ('part_regime_disagrees', 'part', 'a composer''s regime for a part is one that part''s own filing declares'),
  ('conversion_cycle_does_not_close', 'layer', 'converting round a cycle of units returns what it started with'),
  ('one_part_fusion_alters_its_part', 'part', 'a fusion of one part carries that part unchanged'),
  ('denied_remainder_is_not_contradicted', 'layer', 'a denied remainder is not contradicted by the layer''s own figures')
) AS r(slug, subject, rule)
),
epistemics_claims AS (
-- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.prov_entered_by, c.prov_approved_by, c.prov_note, c.as_of,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent,
       n.derivation   AS narrows_derivation,
       b.derivation   AS origin_derivation
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)
),
epistemics_claim_derivations AS (
-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking their pm:derivation branch,
-- at the claim's own position.
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:boundOrigin' AS element,
       c.origin_derivation AS identity
FROM (
    SELECT * FROM epistemics_claims
) c
WHERE c.origin_derivation IS NOT NULL
UNION ALL
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:narrowsWhen', c.narrows_derivation
FROM (
    SELECT * FROM epistemics_claims
) c
WHERE c.narrows_derivation IS NOT NULL
),
identities_roster AS (
-- pm:Identity against every *Derivation restriction in the two schemas, per position and arm.
SELECT * FROM (VALUES
  ('fusionSum',      'pm:demand/pm:amount',            'pm:demand/pm:amount',            'layer',        'demand_derivation', 'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:nameplate/pm:amount',         'nameplate',    'amount_derivation', 'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:jagged/pm:draw',              'nameplate',    'draw_derivation',   'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'asrt:elimination/asrt:quantity', 'elimination',  'derivation',        'as the search says', 'the composer', 'eliminations/unsized'),
  ('fusionSum',      'asrt:part/asrt:factor',          'asrt:part/asrt:factor',          'part',         'factor_derivation', 'as the search says', 'the composer', 'composition/unsized_conversions'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:remainder/pm:quantity',       'layer',        'qty_derivation',    'binds',   'the model',    'layers/remainder'),
  ('fit',            'pm:remainder/pm:sign',           'pm:remainder/pm:sign',           'layer',        'sign_derivation',   'binds',   'the model',    'layers/remainder'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:layer/pm:timeSlack',          'slack',        'derivation',        'defines', 'the model',    'arithmetic/time_slack_derived'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:holder/pm:share',             'holder',       'share_derivation',  'binds',   'the model',    'arithmetic/shares_sum'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'asrt:elimination/asrt:quantity', 'elimination',  'derivation',        'binds',   'the model',    'eliminations/unsized'),
  ('conversionPath', 'asrt:part/asrt:factor',          'asrt:part/asrt:factor',          'part',         'factor_derivation', 'binds',   'the model',    'composition/unsized_conversions'),
  ('fusionSum',      'pm:demand/pm:amount',            'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'asrt:part/asrt:factor',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('conversionPath', 'asrt:part/asrt:factor',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('amountOrigin',   'pm:nameplate/pm:amount',         'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('quantumOrigin',  'pm:lumpy/pm:size',               'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('quantumOrigin',  'pm:quantum/pm:size',             'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:demand/pm:amount',            'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'asrt:part/asrt:factor',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('conversionPath', 'asrt:part/asrt:factor',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths')
) AS r(identity, owns, element, table_name, column_name, binds, origin, handled_by)
)
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           i.identity IS NULL AS violates,
           format('%s claim %s files its %s as the output of `%s`', c.owns, c.seq, c.element,
                  c.identity) AS detail
    FROM      (
        SELECT * FROM epistemics_claim_derivations
    ) c
    LEFT JOIN (
        SELECT * FROM identities_roster
    ) i
           ON i.identity = c.identity::text
          AND i.owns     = c.owns
          AND i.element  = c.element
) p ON true
WHERE r.slug = 'identity_does_not_compute_the_claim'
