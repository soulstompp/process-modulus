-- the conformance rules XSD 1.0 cannot reach, one file each; checks/roster.sqlc is the list.
-- pm:Remainder/sign against pm:Demand and pm:Nameplate; conformance rule "sign agrees".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT s.filing, s.layer,
           s.sign IS DISTINCT FROM s.derived_fit::pm.fit AS violates,
           format('filed %s, ranges say %s', s.sign, s.derived_fit) AS detail
    FROM (
        SELECT * FROM layers.signed
    ) s
) p ON true
WHERE r.slug = 'fit_disagrees'
UNION ALL
-- pm:Remainder/pm:holder summed against |r| from layers/remainder.sqlc, via entries/holder_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
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
               r.m_mode       AS magnitude,
               h.shares_mode  AS shares,
               h.shares_low, h.shares_high,
               r.m_low        AS mag_low,
               r.m_high       AS mag_high
        FROM      (
            SELECT * FROM layers.remainder
        ) r
        JOIN      (
            SELECT * FROM entries.holder_totals
        ) h USING (filing, layer)
        WHERE h.unstated = 0
          AND h.share_units = ARRAY[r.unit]
    ) x
) p ON true
WHERE r.slug = 'shares_do_not_sum'
UNION ALL
-- pm:Remainder/pm:quantity against |r| from layers/remainder.sqlc, via layers/filed_against_derived.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           abs(l.qty_low  - l.m_low)  > 1e-9
           OR abs(l.qty_mode - l.m_mode) > 1e-9
           OR abs(l.qty_high - l.m_high) > 1e-9                           AS violates,
           format('stated [%s, %s, %s] against a magnitude of [%s, %s, %s]',
                  l.qty_low, l.qty_mode, l.qty_high, l.m_low, l.m_mode, l.m_high) AS detail
    FROM (
        SELECT * FROM layers.filed_against_derived
    ) l
    WHERE l.qty_low IS NOT NULL
      AND l.qty_unit = l.unit
) p ON true
WHERE r.slug = 'stated_quantity_is_not_the_magnitude'
UNION ALL
-- every slack on the layer accounted for and empty, against pm:HolderKind of every holder.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           u.filing IS NULL OR (c.derived_fit = 'interference' AND s.filing IS NOT NULL) AS violates,
           CASE WHEN u.filing IS NULL
                THEN format('%s could not be served and no holder says so', c.exposure)
                WHEN c.derived_fit = 'interference' AND s.filing IS NOT NULL
                THEN format('%s could not be served, and a %s holder says part of it was',
                            c.exposure, s.kinds)
                ELSE format('%s could not be served, and the holders say who went without',
                            c.exposure)
           END AS detail
    FROM (
        SELECT e.filing, e.layer, e.exposure, e.derived_fit
        FROM (
            SELECT * FROM layers.unabsorbed_exposure
        ) e
        WHERE e.exposure > 1e-9
    ) c
    LEFT JOIN ( SELECT DISTINCT filing, layer
                FROM (
                    SELECT * FROM entries.unserved_holders
                ) h ) u USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM folds.served_totals
    ) s USING (filing, layer)
) p ON true
WHERE r.slug = 'nobody_named_as_unserved'
UNION ALL
-- every slack on the layer accounted for and empty, against entries/unserved_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT e.filing, e.layer,
           e.exposure > e.unserved + 1e-9 AS violates,
           format('exposure %s, absorbable %s, unserved %s',
                  e.exposure, e.absorbable, e.unserved) AS detail
    FROM (
        SELECT x.filing, x.layer, x.exposure, x.absorbable, u.unserved_high AS unserved
        FROM      (
            SELECT * FROM layers.unabsorbed_exposure
        ) x
        JOIN      (
            SELECT * FROM entries.unserved_totals
        ) u USING (filing, layer)
        WHERE u.unstated = 0
          AND u.share_units = ARRAY[x.unit]
    ) e
) p ON true
WHERE r.slug = 'exposure_unaccounted'
UNION ALL
-- pm:Remainder/pm:holder against the three slack elements, keyed by pm:Remainder/pm:absorber through pm.buffer_term.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT b.filing, b.layer,
           coalesce(b.borne > b.slack_mode + 1e-9, false) AS violates,
           format('%s attributed to the %s buffer, whose slack is %s',
                  b.borne, b.buffer, b.slack_mode) AS detail
    FROM (
        -- pm:Remainder/pm:holder summed against the slack it names, keyed by pm:Remainder/pm:absorber.
SELECT b.filing, b.layer, b.buffer, b.borne, s.mode AS slack_mode, s.unit AS slack_unit, b.unstated
FROM (
    SELECT p.filing, p.layer, a.buffer, h.served_mode AS borne, h.unstated
    FROM      (
        SELECT * FROM layers.pressed
    ) p
    JOIN      (
        SELECT * FROM layers.absorber
    ) a USING (filing, layer)
    JOIN      (
        SELECT * FROM folds.served_totals
    ) h USING (filing, layer)
    WHERE p.sign = 'interference'
) b
JOIN (
    SELECT * FROM entries.slacks
) s USING (filing, layer, buffer)
WHERE s.mode IS NOT NULL

    ) b
    WHERE b.unstated = 0
) p ON true
WHERE r.slug = 'share_exceeds_slack'
UNION ALL
-- the slack claims and pm:Remainder/pm:holder claims, each carrying its own unit.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.slack_unit <> c.share_unit AS violates,
           format('slack in %s, shares in %s', c.slack_unit, c.share_unit) AS detail
    FROM (
        -- entries/absorbing_slack.sqlc against pm:Remainder/pm:holder, each carrying its own unit.
SELECT s.filing, s.layer, s.buffer, h.kind,
       s.unit AS slack_unit, h.share_unit
FROM      (
    SELECT * FROM entries.absorbing_slack
) s
JOIN      (
    SELECT * FROM entries.holders
) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL

    ) c
) p ON true
WHERE r.slug = 'slack_unit_mismatch'
UNION ALL
-- pm:LumpyQuantum/size unit against pm:Nameplate/amount unit.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           l.quantum_unit IS DISTINCT FROM l.amount_unit AS violates,
           format('quantum in %s, nameplate in %s', l.quantum_unit, l.amount_unit) AS detail
    FROM (
        SELECT * FROM layers.lumpy
    ) l
    WHERE l.quantum_low IS NOT NULL
) p ON true
WHERE r.slug = 'quantum_unit_mismatch'
UNION ALL
-- pm:Nameplate/amount against pm:LumpyQuantum/size.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           abs(d.n_low  - d.quantum_mode * round(d.n_low  / d.quantum_mode)) > 1e-9
           OR abs(d.n_mode - d.quantum_mode * round(d.n_mode / d.quantum_mode)) > 1e-9
           OR abs(d.n_high - d.quantum_mode * round(d.n_high / d.quantum_mode)) > 1e-9 AS violates,
           format('a quantum of %s against a nameplate of [%s, %s, %s]',
                  d.quantum_mode, d.n_low, d.n_mode, d.n_high) AS detail
    FROM (
        -- pm:LumpyQuantum/size, strictly positive.
SELECT l.*
FROM (
    SELECT * FROM layers.lumpy
) l
WHERE l.quantum_mode > 0

    ) d
) p ON true
WHERE r.slug = 'nameplate_not_a_multiple'
UNION ALL
-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount plus pm:Nameplate/pm:capacitySlack.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           -- the whole draw above the whole of what the supply could make
           d.draw_low > d.n_high + d.capacity_high + 1e-9              AS violates,
           CASE WHEN d.draw_low  > d.n_high + d.capacity_high + 1e-9
                THEN format('served [%s, %s] against at most %s: the whole range is over the '
                            'line', d.draw_low, d.draw_high,
                            d.n_high + d.capacity_high)
                WHEN d.draw_high <= d.n_low + d.capacity_low + 1e-9
                THEN format('served [%s, %s] against at least %s: the whole range clears',
                            d.draw_low, d.draw_high, d.n_low + d.capacity_low)
                ELSE format('served [%s, %s] against [%s, %s]: the ranges overlap, so this '
                            'document does not settle whether the supply was overrun',
                            d.draw_low, d.draw_high,
                            d.n_low + d.capacity_low, d.n_high + d.capacity_high)
           END                                                        AS detail
    FROM (
        SELECT * FROM layers.drawn
    ) d
    WHERE d.capacity_slack IS NOT NULL
      AND d.draw_unit = d.n_unit
      AND d.capacity_unit = d.n_unit
) p ON true
WHERE r.slug = 'draw_exceeds_the_supply'
UNION ALL
-- pm:Remainder/sign = clearance against pm:HolderKind customer/unrealised.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT r.filing, r.layer,
           u.kind IS NOT NULL AS violates,
           format('%s holder under a clearance fit', h.kind) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM entries.holders
    ) h USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM entries.unserved_holders
    ) u USING (filing, layer, kind)
    WHERE r.sign = 'clearance'
) p ON true
WHERE r.slug = 'clearance_with_unserved'
UNION ALL
SELECT * FROM checks.unresolved_part
UNION ALL
SELECT * FROM checks.jagged_layer
UNION ALL
-- composition/descent.sqlc intersected with its converse; conformance rule "layers that always move together are one layer".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT f.filing, f.layer,
           c.filing IS NOT NULL AS violates,
           CASE WHEN c.filing IS NULL
                THEN format('`%s` holds its remainder independently', f.layer)
                WHEN c.partner IS NULL
                THEN format('`%s` is composed from ITSELF, so its figure depends on its own value and no rank exists for it', f.layer)
                ELSE format('`%s` moves with `%s`, and %s layers here were one layer: the repair is to merge them, not to break a part',
                            f.layer, c.partner, c.members)
           END AS detail
    FROM      (
        SELECT * FROM composition.fusions
    ) f
    LEFT JOIN (
        SELECT m.filing, m.layer, m.class, m.members,
               bool_or(m.co_moves_with_filing = m.filing AND m.co_moves_with_layer = m.layer)
                 AS reaches_itself,
               min(m.co_moves_with_filing || '/' || m.co_moves_with_layer)
                 FILTER (WHERE NOT (m.co_moves_with_filing = m.filing
                                AND m.co_moves_with_layer = m.layer)) AS partner
        FROM (
            -- composition/descent.sqlc intersected with its own converse; the classes of F+ ∩ (F+)ᵀ.
SELECT p.filing, p.layer, p.co_moves_with_filing, p.co_moves_with_layer,
       min(p.co_moves_with_filing || '/' || p.co_moves_with_layer) OVER w AS class,
       count(*) OVER w                                                    AS members
FROM (
    SELECT DISTINCT a.root_filing AS filing, a.root_layer AS layer,
           a.filing AS co_moves_with_filing, a.layer AS co_moves_with_layer
    FROM      (
        SELECT * FROM composition.descent
    ) a
    JOIN      (
        SELECT * FROM composition.descent
    ) b ON  b.root_filing = a.filing      AND b.root_layer = a.layer
        AND b.filing      = a.root_filing AND b.layer      = a.root_layer
) p
WINDOW w AS (PARTITION BY p.filing, p.layer)

        ) m
        GROUP BY m.filing, m.layer, m.class, m.members
    ) c ON c.filing = f.filing AND c.layer = f.layer
) p ON true
WHERE r.slug = 'layers_move_together'
UNION ALL
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
UNION ALL
-- pm:Claim/pm:narrowsWhen on any pm:Claim where low = high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.narrows_absent IS DISTINCT FROM 'notApplicable' AS violates,
           format('%s claim %s: %s exactly, and it still answers %s', c.owns, c.seq, c.mode,
                  coalesce(c.narrows_kind::text, 'absent: ' || c.narrows_absent)) AS detail
    FROM (
        SELECT * FROM epistemics.point_claims
    ) c
) p ON true
WHERE r.slug = 'narrows_a_point_value'
UNION ALL
-- pm:Claim/pm:narrowsWhen with pm:absent/reason = notApplicable on any claim where low <> high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.narrows_absent IS NOT DISTINCT FROM 'notApplicable' AS violates,
           format('%s claim %s: spans %s to %s %s, yet says there is no range to narrow',
                  c.owns, c.seq, c.low, c.high, c.unit) AS detail
    FROM (
        -- pm:Claim where low <> high, at every element that carries one.
SELECT c.*
FROM (
    SELECT * FROM epistemics.claims
) c
WHERE NOT c.is_a_point

    ) c
) p ON true
WHERE r.slug = 'range_says_no_range'
UNION ALL
-- pm:Claim/pm:boundOrigin with pm:absent/reason = none on a claim where low = high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.origin_absent IS NOT DISTINCT FROM 'none' AS violates,
           format('%s claim %s: %s %s exactly, and nothing is said to set it',
                  c.owns, c.seq, c.mode, c.unit) AS detail
    FROM (
        SELECT * FROM epistemics.point_claims
    ) c
) p ON true
WHERE r.slug = 'bound_fell_with_no_range'
UNION ALL
-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking pm:derivation, against the identity that computes the claim.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           i.identity IS NULL AS violates,
           format('%s claim %s files its %s as the output of `%s`', c.owns, c.seq, c.element,
                  c.identity) AS detail
    FROM      (
        SELECT * FROM epistemics.claim_derivations
    ) c
    LEFT JOIN (
        SELECT * FROM identities.roster
    ) i
           ON i.identity = c.identity::text
          AND i.owns     = c.owns
          AND i.element  = c.element
) p ON true
WHERE r.slug = 'identity_does_not_compute_the_claim'
UNION ALL
-- asrt:Part's pm:Divisibility/window against the composed pm:Layer's.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT w.composition AS filing, w.composed_layer AS layer,
           (w.composed_window_low IS NULL
            OR w.composed_window_low  <> w.window_low
            OR w.composed_window_mode <> w.window_mode
            OR w.composed_window_high <> w.window_high
            OR (w.units_agree AND w.composed_window_unit <> w.window_unit)) AS violates,
           CASE WHEN w.composed_window_low IS NULL
                THEN format('the part %s/%s files a %s-%s duty cycle and the composed '
                            'layer files `%s`', w.part_filing, w.part_layer, w.window_low,
                            w.window_unit, w.composed_window_absent)
                ELSE format('composed window [%s, %s, %s] %s against a part''s [%s, %s, %s] %s, '
                            'carried and never summed',
                            w.composed_window_low, w.composed_window_mode, w.composed_window_high,
                            w.composed_window_unit, w.window_low, w.window_mode, w.window_high,
                            w.window_unit)
           END AS detail
    FROM (
        -- asrt:Part's own pm:Divisibility/window against the composed pm:Layer's.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       pw.window_low, pw.window_mode, pw.window_high, pw.window_unit,
       cw.window_low    AS composed_window_low,
       cw.window_mode   AS composed_window_mode,
       cw.window_high   AS composed_window_high,
       cw.window_unit   AS composed_window_unit,
       cw.window_absent AS composed_window_absent,
       (p.factor_state = 'omitted')
           AS units_agree
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM layers.windows
) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    SELECT * FROM layers.windows
) cw
       ON cw.filing = p.composition  AND cw.layer = p.composed_layer
WHERE pw.window_low IS NOT NULL

    ) w
) p ON true
WHERE r.slug = 'window_lost_or_summed'
UNION ALL
-- pm:Layer/pm:timeSlack filed as a clearance derivation, against pm:Divisibility/pm:window.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           lic.filing IS NULL AS violates,
           format('timeSlack is the `clearance` and the window is %s',
                  coalesce(d.window_absent::text,
                           format('%s %s', d.window_low, d.window_unit))) AS detail
    FROM      (
        SELECT * FROM entries.derived_time_slacks
    ) d
    LEFT JOIN (
        -- pm:Divisibility/window: absent notApplicable, or filed as one whole period.
SELECT w.filing, w.layer,
       CASE WHEN w.window_absent IS NOT NULL THEN 'the question has no denominator'
            ELSE 'it runs the whole period' END AS licensed_because
FROM (
    SELECT * FROM layers.windows
) w
WHERE w.window_absent = 'notApplicable'
   OR (w.window_low = 1 AND w.window_low = w.window_high
       AND EXISTS (
           SELECT 1
           FROM (
               SELECT * FROM units.with_a_period
           ) p
           WHERE p.filing = w.filing AND p.layer = w.layer
             AND p.period = w.window_unit
       ))

    ) lic USING (filing, layer)
) p ON true
WHERE r.slug = 'derived_slack_over_a_window'
UNION ALL
-- pm:Divisibility/window with pm:absent/reason = notApplicable, against pm:Claim/pm:denominator.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
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
        SELECT * FROM layers.windows
    ) w
    LEFT JOIN (
        SELECT * FROM units.with_a_period
    ) r USING (filing, layer)
    WHERE w.window_absent = 'notApplicable'
      AND w.amount_unit IS NOT NULL
) p ON true
WHERE r.slug = 'window_not_applicable_on_a_rate'
UNION ALL
-- pm:Divisibility/pm:window/pm:quantum/pm:size with pm:absent/pm:reason = notApplicable.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT w.filing, w.layer,
           w.window_size_absent IS NOT DISTINCT FROM 'notApplicable' AS violates,
           CASE WHEN w.window_size_absent IS NOT NULL
                THEN format('the window is filed as a quantum and its size as %s', w.window_size_absent)
                ELSE format('the window is filed as %s %s', w.window_low, w.window_unit)
           END AS detail
    FROM (
        SELECT * FROM layers.windows
    ) w
    WHERE w.window_low IS NOT NULL OR w.window_size_absent IS NOT NULL
) p ON true
WHERE r.slug = 'window_size_not_applicable'
UNION ALL
-- asrt:eliminations with pm:absent/reason = notApplicable, counted over asrt:Part.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT m.composition AS filing, m.composed_layer AS layer,
           m.parts > 1 AS violates,
           format('%s parts and the search is `notApplicable`', m.parts) AS detail
    FROM (
        -- eliminations/searched.sqlc answering "notApplicable", beside folds/fusion_parts.sqlc.
SELECT es.composition, es.composed_layer, f.parts
FROM (
    SELECT * FROM eliminations.searched
) es
JOIN (
    SELECT * FROM folds.fusion_parts
) f
  ON f.composition = es.composition AND f.composed_layer = es.composed_layer
WHERE es.answer = 'notApplicable'
  AND f.parts > 0

    ) m
) p ON true
WHERE r.slug = 'elimination_not_applicable_with_parts'
UNION ALL
-- asrt:Fusion/asrt:Part summed against the composed layer's demand, nameplate and draw, via composition/fused.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT f.composition AS filing, f.composed_layer AS layer,
           bool_or(NOT f.agrees) AS violates,
           string_agg(format('%s: parts less eliminations give [%s, %s, %s]; the filing states [%s, %s, %s]',
                             f.quantity, f.computed_low, f.computed_mode, f.computed_high,
                             f.filed_low, f.filed_mode, f.filed_high),
                      '; ' ORDER BY f.quantity) AS detail
    FROM (
        SELECT * FROM composition.fused
    ) f
    GROUP BY f.composition, f.composed_layer
) p ON true
WHERE r.slug = 'fusion_sum_disagrees'
UNION ALL
-- asrt:Part whose pm:ForeignId/notation is its own composition's, against pm.layer.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT p.composition AS filing, p.composed_layer AS layer,
           l.layer IS NULL AS violates,
           format('local part `%s` is not a layer of this filing', p.part_layer) AS detail
    FROM      (
        -- pm.part where pm:ForeignId/notation equals the composition's own pm:notation.
SELECT p.*
FROM      (
    SELECT * FROM composition.part_references
) p
JOIN      (
    SELECT * FROM composition.notations
) fi ON fi.filing = p.composition AND fi.notation = p.part_filing

    ) p
    LEFT JOIN (
        SELECT * FROM layers.every_layer
    ) l ON l.filing = p.composition AND l.layer = p.part_layer
) p ON true
WHERE r.slug = 'local_part_dangles'
UNION ALL
-- pm:StatedRemainder's absent branch against the layer's own pm:Demand and pm:Nameplate, from layers/figures.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           (f.d_low IS NOT NULL AND f.n_low IS NOT NULL)     AS violates,
           CASE WHEN f.d_low IS NULL OR f.n_low IS NULL
                THEN format('`%s`, and no remainder is derivable: %s',
                            d.reason,
                            CASE WHEN f.d_low IS NULL THEN 'no demand is stated'
                                 ELSE 'no nameplate is stated' END)
                ELSE format('`%s`, yet demand [%s, %s] against a nameplate of [%s, %s] '
                            'gives a remainder the filing supplies itself',
                            d.reason, f.d_low, f.d_high, f.n_low, f.n_high)
           END AS detail
    FROM      (
        SELECT * FROM layers.denied_remainders
    ) d
    LEFT JOIN (
        SELECT * FROM layers.figures
    ) f USING (filing, layer)
) p ON true
WHERE r.slug = 'denied_remainder_is_not_contradicted'
UNION ALL
-- composition/carried.sqlc: the part's figure against the composed layer's, per quantity.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           abs(c.part_low  - c.filed_low)  > 1e-9
        OR abs(c.part_mode - c.filed_mode) > 1e-9
        OR abs(c.part_high - c.filed_high) > 1e-9                    AS violates,
           format('%s carried as [%s, %s, %s] against a part of [%s, %s, %s]',
                  c.quantity, c.filed_low, c.filed_mode, c.filed_high,
                  c.part_low, c.part_mode, c.part_high)              AS detail
    FROM (
        SELECT * FROM composition.carried
    ) c
) p ON true
WHERE r.slug = 'one_part_fusion_alters_its_part'
UNION ALL
-- units/conversions.sqlc walked until a unit repeats; the product against one.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    WITH RECURSIVE e AS (
        SELECT * FROM units.conversions
    ),
    walk(start, at, depth, p_low, p_mode, p_high, path, filing, layer) AS (
        SELECT from_unit, to_unit, 1, factor_low, factor_mode, factor_high,
               ARRAY[from_unit, to_unit], filing, layer
        FROM e
        UNION ALL
        SELECT w.start, e.to_unit, w.depth + 1,
               w.p_low * e.factor_low, w.p_mode * e.factor_mode, w.p_high * e.factor_high,
               w.path || e.to_unit, w.filing, w.layer
        FROM walk w
        JOIN e ON e.from_unit = w.at
        WHERE NOT (e.to_unit = ANY (w.path[2:array_length(w.path, 1)]))
    )
    SELECT w.filing, w.layer,
           NOT (w.p_low <= 1 AND w.p_high >= 1) AS violates,
           format('%s: the factors multiply to [%s, %s] round it, and one %s inside',
                  array_to_string(w.path, ' to '),
                  round(w.p_low, 6), round(w.p_high, 6),
                  CASE WHEN w.p_low <= 1 AND w.p_high >= 1 THEN 'lies' ELSE 'DOES NOT lie' END)
           AS detail
    FROM walk w
    WHERE w.at = w.start
      AND w.start = (SELECT min(u) FROM unnest(w.path) u)
) p ON true
WHERE r.slug = 'conversion_cycle_does_not_close'
UNION ALL
-- asrt:Part against its composed pm:Layer's unit, per quantity they both file.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT DISTINCT x.filing, x.layer, x.violates, x.detail
    FROM (
        SELECT p.composition AS filing, p.composed_layer AS layer,
               p.factor_state = 'omitted' AS violates,
               format('the part %s/%s is quoted in %s and this layer in %s, and the conversion '
                      'is %s', p.part_filing, p.part_layer, p.part_unit, p.composed_unit,
                      CASE p.factor_state
                           WHEN 'stated'     THEN 'filed'
                           WHEN 'absent'     THEN format('filed as `%s`', p.factor_absent)
                           WHEN 'derivation' THEN format('filed as the output of `%s`', p.factor_derivation)
                           WHEN 'omitted'    THEN 'NOT FILED, so a reader supplies one' END) AS detail
        FROM (
            SELECT * FROM composition.part_quantities
        ) p
        WHERE p.part_unit IS DISTINCT FROM p.composed_unit
    ) x
) p ON true
WHERE r.slug = 'unit_crossing_without_a_factor'
UNION ALL
-- composition/regime_crossings.sqlc; conformance rule "a part crossing a regime boundary files what reconciles it".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
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
    SELECT * FROM composition.part_regimes
) x
LEFT JOIN (
    SELECT r.filing,
           count(*) FILTER (WHERE r.framework_value IS NOT NULL) AS states,
           min(r.framework_taxonomy) AS framework_taxonomy,
           min(r.framework_value)    AS framework_value
    FROM (
        SELECT * FROM composition.regimes
    ) r
    GROUP BY r.filing
) own ON own.filing = x.composition
LEFT JOIN (
    SELECT * FROM composition.citations
) c ON c.composition = x.composition

    ) x
    WHERE x.crossing_known
) p ON true
WHERE r.slug = 'regime_crossing_without_a_citation'
UNION ALL
-- composition/part_regimes.sqlc; conformance rule "a composer's regime for a part is one that part's own filing declares".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
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
        SELECT * FROM composition.part_regimes
    ) x
    WHERE x.composer_absent IS NULL
      AND x.frameworks_the_filing_states > 0
) p ON true
WHERE r.slug = 'part_regime_disagrees'

