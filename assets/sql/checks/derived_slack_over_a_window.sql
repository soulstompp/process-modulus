-- pm:Layer/pm:timeSlack filed as a clearance derivation, against pm:Divisibility/pm:window.
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
  ('jagged_layer', 'layer', 'a fusion''s parts partition what they compose'),
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
layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
),
entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
),
entries_derived_time_slacks AS (
-- pm:Layer/pm:timeSlack filed as a clearance derivation, beside pm:Divisibility/pm:window.
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    SELECT * FROM layers_windows
) w
JOIN      (
    SELECT * FROM entries_slacks
) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.derivation = 'clearance'
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
units_with_a_period AS (
-- pm:Claim/pm:denominator/pm:period, at pm:Nameplate/amount.
SELECT c.filing, c.layer, c.unit, c.denominator AS period
FROM      (
    SELECT * FROM epistemics_claims
) c
WHERE c.owns = 'pm:nameplate/pm:amount'
  AND c.denominator_kind = 'period'
),
layers_derivation_licensed AS (
-- pm:Divisibility/window: absent notApplicable, or filed as one whole period.
SELECT w.filing, w.layer,
       CASE WHEN w.window_absent IS NOT NULL THEN 'the question has no denominator'
            ELSE 'it runs the whole period' END AS licensed_because
FROM (
    SELECT * FROM layers_windows
) w
WHERE w.window_absent = 'notApplicable'
   OR (w.window_low = 1 AND w.window_low = w.window_high
       AND EXISTS (
           SELECT 1
           FROM (
               SELECT * FROM units_with_a_period
           ) p
           WHERE p.filing = w.filing AND p.layer = w.layer
             AND p.period = w.window_unit
       ))
)
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           lic.filing IS NULL AS violates,
           format('timeSlack is the `clearance` and the window is %s',
                  coalesce(d.window_absent::text,
                           format('%s %s', d.window_low, d.window_unit))) AS detail
    FROM      (
        SELECT * FROM entries_derived_time_slacks
    ) d
    LEFT JOIN (
        SELECT * FROM layers_derivation_licensed
    ) lic USING (filing, layer)
) p ON true
WHERE r.slug = 'derived_slack_over_a_window'
