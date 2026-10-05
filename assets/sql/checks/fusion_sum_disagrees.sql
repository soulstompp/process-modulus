-- asrt:Fusion/asrt:Part summed against the composed layer's demand, nameplate and draw, via composition/fused.sqlc.
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
composition_part_references AS (
-- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
composition_parts AS (
-- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition_part_references
) p
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer
),
layers_summed_quantities AS (
-- pm:Layer/pm:Demand, pm:Nameplate/pm:amount and pm:Jagged/pm:draw, one row per quantity.
SELECT l.filing, l.layer, 'demand'::pm.summed_quantity AS quantity,
       l.demand_low AS low, l.demand_mode AS mode, l.demand_high AS high, l.demand_unit AS unit,
       l.demand_absent AS absent, l.demand_derivation AS derivation
FROM pm.layer l
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::pm.summed_quantity,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_derivation
FROM pm.nameplate n
UNION ALL
SELECT n.filing, n.layer, 'draw'::pm.summed_quantity,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent, n.draw_derivation
FROM pm.nameplate n
),
folds_fusion_parts AS (
-- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM composition_part_references
) r
GROUP BY r.composition, r.composed_layer
),
composition_fusions AS (
-- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f
),
composition_derived_frontier AS (
-- layers/summed_quantities.sqlc filed as a derivation, walked through composition/parts.sqlc while the node's figure is derived too.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition_parts
),
figure AS (
    SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation,
           (f.filing IS NOT NULL) AS is_fusion
    FROM      (
        SELECT * FROM layers_summed_quantities
    ) s
    LEFT JOIN (
        SELECT * FROM composition_fusions
    ) f ON f.filing = s.filing AND f.layer = s.layer
),
walk(root_filing, root_layer, quantity, filing, layer, depth,
     factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
     conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion) AS (
        SELECT r.filing, r.layer, r.quantity, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation'), p.composed_layer,
               p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      figure r
        JOIN      resolved p ON p.composition = r.filing AND p.composed_layer = r.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = r.quantity
        WHERE r.derivation IS NOT NULL
    UNION ALL
        SELECT w.root_filing, w.root_layer, w.quantity, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation'),
               p.composed_layer, p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      walk w
        JOIN      resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = w.quantity
        WHERE w.derivation IS NOT NULL
) CYCLE filing, layer SET is_cycle USING route
SELECT root_filing, root_layer, quantity, filing, layer, depth,
       factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
       conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion, is_cycle
FROM walk
),
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
),
composition_unresolved_parts AS (
-- composition/part_references.sqlc less composition/parts.sqlc, per fusion and reference.
SELECT r.composition, r.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'a part resolves to no filing here' AS suspended_because,
       r.part_filing || '/' || r.part_layer AS note
FROM      (
    SELECT * FROM composition_part_references
) r
LEFT JOIN (
    SELECT * FROM composition_parts
) p ON  p.composition    = r.composition
    AND p.composed_layer = r.composed_layer
    AND p.part_notation  = r.part_filing
    AND p.part_layer     = r.part_layer
WHERE p.composition IS NULL
),
composition_derived_quantities AS (
-- composition/derived_frontier.sqlc summed at the nodes stating the figure, less eliminations/filed.sqlc at the root and each derived node passed.
WITH
root AS (
    SELECT s.filing, s.layer, s.quantity, s.derivation, coalesce(b.parts, 0) AS parts
    FROM      ( SELECT * FROM layers_summed_quantities ) s
    LEFT JOIN (
        SELECT * FROM folds_fusion_parts
    ) b ON b.composition = s.filing AND b.composed_layer = s.layer
    WHERE s.derivation IS NOT NULL
),
node AS (
    SELECT w.root_filing, w.root_layer, w.quantity, w.filing, w.layer, w.depth,
           w.factor_low, w.factor_mode, w.factor_high, w.part_of, w.conversion_absent,
           w.conversion_derivation, w.is_cycle,
           w.low, w.mode, w.high, w.unit, w.absent, w.derivation, w.is_fusion
    FROM ( SELECT * FROM composition_derived_frontier ) w
),
passed AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity, r.filing, r.layer,
           1::numeric AS factor_low, 1::numeric AS factor_mode, 1::numeric AS factor_high,
           false AS below
    FROM root r
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity, n.filing, n.layer,
           n.factor_low, n.factor_mode, n.factor_high, true
    FROM node n
    WHERE n.derivation IS NOT NULL AND n.is_fusion AND NOT n.is_cycle
),
elimination AS (
    SELECT p.root_filing, p.root_layer, p.quantity, p.filing, p.layer, p.below,
           least(   e.low  * p.factor_low, e.low  * p.factor_high) AS e_low,
           e.mode * p.factor_mode                                  AS e_mode,
           greatest(e.high * p.factor_low, e.high * p.factor_high) AS e_high,
           e.absent AS e_absent, e.derivation AS e_derivation,
           es.answer AS searched
    FROM      passed p
    LEFT JOIN ( SELECT * FROM eliminations_filed ) e
           ON e.composition = p.filing AND e.composed_layer = p.layer AND e.quantity = p.quantity
    LEFT JOIN ( SELECT * FROM eliminations_searched ) es
           ON es.composition = p.filing AND es.composed_layer = p.layer
),
unresolved AS MATERIALIZED (
    SELECT DISTINCT u.composition, u.composed_layer
    FROM ( SELECT * FROM composition_unresolved_parts ) u
),
reason AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity,
           format('no fusion here builds `%s`', r.layer) AS why
    FROM root r
    WHERE r.parts = 0
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           CASE WHEN n.is_cycle THEN format('the walk closes a cycle at `%s`', n.layer)
                WHEN n.low IS NULL AND n.derivation IS NULL
                     THEN format('`%s` files its %s %s', n.layer, n.quantity,
                                 coalesce(n.absent::text, 'nowhere'))
                ELSE format('`%s` files its %s as its fusion''s sum and no fusion builds it',
                            n.layer, n.quantity) END
    FROM node n
    WHERE n.is_cycle
       OR (n.low IS NULL AND (n.derivation IS NULL OR NOT n.is_fusion))
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           format('the conversion of `%s` into `%s` is %s', n.layer, n.part_of,
                  coalesce(n.conversion_absent::text,
                           format('filed as `%s`, and no computation of it is wired in',
                                  n.conversion_derivation)))
    FROM node n
    WHERE n.conversion_absent IS NOT NULL OR n.conversion_derivation IS NOT NULL
    UNION ALL
    SELECT e.root_filing, e.root_layer, e.quantity,
           CASE WHEN e.searched = 'unmeasured'
                THEN format('`%s` never searched for double counting', e.layer)
                ELSE format('the %s elimination at `%s` is %s', e.quantity, e.layer,
                            coalesce(e.e_absent::text,
                                     format('filed as `%s`, and no computation of it is wired in',
                                            e.e_derivation))) END
    FROM elimination e
    WHERE e.searched = 'unmeasured' OR e.e_absent IS NOT NULL OR e.e_derivation IS NOT NULL
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('a part of `%s` resolves to no filing here', p.layer)
    FROM passed p
    JOIN unresolved u ON u.composition = p.filing AND u.composed_layer = p.layer
),
level AS (
    SELECT r.filing, r.layer, r.quantity, r.derivation,
           coalesce(st.x_low, 0)  - coalesce(pb.e_low, 0)  AS s_low,
           coalesce(st.x_mode, 0) - coalesce(pb.e_mode, 0) AS s_mode,
           coalesce(st.x_high, 0) - coalesce(pb.e_high, 0) AS s_high,
           coalesce(er.e_low, 0) AS e_low, coalesce(er.e_mode, 0) AS e_mode,
           coalesce(er.e_high, 0) AS e_high,
           st.unit
    FROM root r
    LEFT JOIN (
        SELECT n.root_filing, n.root_layer, n.quantity,
               sum(least(   n.low  * n.factor_low, n.low  * n.factor_high)) AS x_low,
               sum(n.mode * n.factor_mode)                                  AS x_mode,
               sum(greatest(n.high * n.factor_low, n.high * n.factor_high)) AS x_high,
               CASE WHEN count(DISTINCT n.unit) = 1
                         AND bool_and(n.factor_low = 1 AND n.factor_high = 1)
                    THEN min(n.unit) END AS unit
        FROM node n
        WHERE n.low IS NOT NULL
        GROUP BY n.root_filing, n.root_layer, n.quantity
    ) st ON st.root_filing = r.filing AND st.root_layer = r.layer AND st.quantity = r.quantity
    LEFT JOIN (
        SELECT e.root_filing, e.root_layer, e.quantity,
               sum(e.e_low) AS e_low, sum(e.e_mode) AS e_mode, sum(e.e_high) AS e_high
        FROM elimination e
        WHERE e.below
        GROUP BY e.root_filing, e.root_layer, e.quantity
    ) pb ON pb.root_filing = r.filing AND pb.root_layer = r.layer AND pb.quantity = r.quantity
    LEFT JOIN elimination er
           ON er.root_filing = r.filing AND er.root_layer = r.layer AND er.quantity = r.quantity
          AND NOT er.below
),
inverts AS (
    SELECT l.filing, l.layer, l.quantity,
           (l.s_low <= l.s_mode AND l.s_mode <= l.s_high) AS own
    FROM level l
    WHERE NOT (l.s_low - l.e_low <= l.s_mode - l.e_mode AND l.s_mode - l.e_mode <= l.s_high - l.e_high)
),
blocked AS (
    SELECT root_filing, root_layer, quantity, why FROM reason
    UNION ALL
    SELECT i.filing, i.layer, i.quantity,
           CASE WHEN i.own
                THEN format('the %s elimination at `%s` is wider than its sum and inverts it',
                            i.quantity, i.layer)
                ELSE format('an elimination below `%s` inverts the %s sum', i.layer, i.quantity) END
    FROM inverts i
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('the %s elimination at `%s` is wider than its sum and inverts it', p.quantity, p.layer)
    FROM passed p
    JOIN inverts i ON i.filing = p.filing AND i.layer = p.layer AND i.quantity = p.quantity
    WHERE p.below
)
SELECT l.filing, l.layer, l.quantity, l.derivation,
       CASE WHEN b.why IS NULL THEN l.s_low  - l.e_low  END AS low,
       CASE WHEN b.why IS NULL THEN l.s_mode - l.e_mode END AS mode,
       CASE WHEN b.why IS NULL THEN l.s_high - l.e_high END AS high,
       CASE WHEN b.why IS NULL THEN l.unit END AS unit,
       b.why AS blocked_because
FROM level l
LEFT JOIN (
    SELECT root_filing, root_layer, quantity, string_agg(DISTINCT why, '; ' ORDER BY why) AS why
    FROM blocked
    GROUP BY root_filing, root_layer, quantity
) b ON b.root_filing = l.filing AND b.root_layer = l.layer AND b.quantity = l.quantity
),
composition_resolved_quantities AS (
-- layers/summed_quantities.sqlc where no derivation is filed, beside composition/derived_quantities.sqlc where one is.
SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent,
       false                  AS derived,
       s.derivation,
       NULL::text             AS blocked_because
FROM (
    SELECT * FROM layers_summed_quantities
) s
WHERE s.derivation IS NULL
UNION ALL
SELECT d.filing, d.layer, d.quantity, d.low, d.mode, d.high, d.unit,
       NULL::pm.absence_reason,
       d.low IS NOT NULL,
       d.derivation,
       d.blocked_because
FROM (
    SELECT * FROM composition_derived_quantities
) d
),
composition_converted AS (
-- asrt:Part/asrt:factor applied to each quantity the part layer states.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, s.quantity,
       least(   s.low  * coalesce(p.factor_low, 1), s.low  * coalesce(p.factor_high, 1)) AS low,
       s.mode * coalesce(p.factor_mode, 1)                                               AS mode,
       greatest(s.high * coalesce(p.factor_low, 1), s.high * coalesce(p.factor_high, 1)) AS high
FROM      (
    SELECT * FROM composition_parts
) p
JOIN      (
    SELECT * FROM composition_resolved_quantities
) s
       ON s.filing = p.part_filing AND s.layer = p.part_layer
  AND s.low IS NOT NULL
  AND p.factor_state IN ('omitted', 'stated')
),
folds_part_sums AS (
-- composition/converted.sqlc folded to one row per composed layer and quantity.
SELECT c.composition, c.composed_layer, c.quantity,
       sum(c.low)  AS sum_low,
       sum(c.mode) AS sum_mode,
       sum(c.high) AS sum_high,
       count(*)    AS parts
FROM (
    SELECT * FROM composition_converted
) c
GROUP BY c.composition, c.composed_layer, c.quantity
),
eliminations_unsearched AS (
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    SELECT * FROM eliminations_searched
) es
WHERE es.answer = 'unmeasured'
),
eliminations_unsized AS (
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       CASE WHEN e.derivation IS NOT NULL
            THEN format('the elimination is filed as `%s`, and no computation of it is wired into '
                        'the sum', e.derivation)
            ELSE 'the overlap was found and could not be sized' END AS suspended_because,
       e.reason AS note
FROM (
    SELECT * FROM eliminations_filed
) e
WHERE e.absent IS NOT NULL OR e.derivation IS NOT NULL
),
composition_unsized_conversions AS (
-- asrt:Part/asrt:factor taking its pm:absent or pm:derivation branch, as a suspension of the composed sum.
SELECT p.composition, p.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       CASE WHEN p.factor_state = 'derivation'
            THEN format('the conversion is filed as `%s`, and no computation of it is wired into '
                        'the sum', p.factor_derivation)
            ELSE 'the conversion was filed and could not be sized' END AS suspended_because,
       coalesce(p.factor_absent::text, p.factor_derivation::text) AS note
FROM (
    SELECT * FROM composition_parts
) p
WHERE p.factor_state IN ('absent', 'derivation')
),
composition_fusion_quantities AS (
-- composition/fusions.sqlc joined to layers/summed_quantities.sqlc on the composed layer.
SELECT f.filing, f.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation
FROM      (
    SELECT * FROM composition_fusions
) f
JOIN      (
    SELECT * FROM layers_summed_quantities
) s ON s.filing = f.filing AND s.layer = f.layer
),
composition_unstated_quantities AS (
-- layers/summed_quantities.sqlc without a figure on a part or on the composed layer, and not a derivation, per fusion.
SELECT u.composition, u.composed_layer, u.quantity,
       'the quantity is not stated on every layer the sum reads' AS suspended_because,
       string_agg(u.layer || ' ' || coalesce(u.absent::text, 'unstated'), ', ' ORDER BY u.layer)
           AS note
FROM (
    SELECT p.composition, p.composed_layer, s.quantity,
           p.part_filing || '/' || p.part_layer AS layer, s.absent
    FROM      (
        SELECT * FROM composition_parts
    ) p
    JOIN      (
        SELECT * FROM layers_summed_quantities
    ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
    WHERE s.low IS NULL
      AND s.derivation IS NULL
    UNION ALL
    SELECT q.filing, q.layer, q.quantity, 'the composed layer', q.absent
    FROM (
        SELECT * FROM composition_fusion_quantities
    ) q
    WHERE q.low IS NULL
      AND q.derivation IS NULL
) u
GROUP BY u.composition, u.composed_layer, u.quantity
),
composition_filed_grounds AS (
-- the five grounds decided by what is filed, one row per ground, carrying the quantity it lifts.
SELECT * FROM eliminations_unsearched
UNION ALL
SELECT * FROM eliminations_unsized
UNION ALL
SELECT * FROM composition_unsized_conversions
UNION ALL
SELECT * FROM composition_unstated_quantities
UNION ALL
SELECT * FROM composition_unresolved_parts
),
composition_underived_parts AS (
-- composition/parts.sqlc whose figure composition/derived_quantities.sqlc cannot compute, per fusion.
SELECT p.composition, p.composed_layer, d.quantity,
       'a part files the quantity derived and it cannot be computed' AS suspended_because,
       string_agg(p.part_filing || '/' || p.part_layer || ': ' || d.blocked_because, ', '
                  ORDER BY p.part_filing, p.part_layer) AS note
FROM      (
    SELECT * FROM composition_parts
) p
JOIN      (
    SELECT * FROM composition_derived_quantities
) d ON d.filing = p.part_filing AND d.layer = p.part_layer
WHERE d.low IS NULL
GROUP BY p.composition, p.composed_layer, d.quantity
),
composition_suspension_grounds AS (
-- the grounds that lift the sum rule: those read off the filing, and a derived part that cannot be computed.
SELECT * FROM composition_filed_grounds
UNION ALL
SELECT * FROM composition_underived_parts
),
composition_suspended_fusions AS (
-- composition/suspension_grounds.sqlc projected onto the fusion it suspends.
SELECT DISTINCT g.composition, g.composed_layer, g.quantity
FROM (
    SELECT * FROM composition_suspension_grounds
) g
),
composition_suspended_quantities AS (
-- composition/suspended_fusions.sqlc expanded onto pm.summed_quantity.
SELECT DISTINCT s.composition, s.composed_layer, q.quantity
FROM      (
    SELECT * FROM composition_suspended_fusions
) s
JOIN      unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
       ON s.quantity IS NULL OR s.quantity = q.quantity
),
composition_derived_fusions AS (
-- composition/fusion_quantities.sqlc filed as a derivation.
SELECT q.filing, q.layer, q.quantity
FROM (
    SELECT * FROM composition_fusion_quantities
) q
WHERE q.derivation IS NOT NULL
),
composition_owed_equality AS (
-- composition/fusions.sqlc for every quantity, minus the suspensions that lift each sum and the
-- composed figures filed `derived`.
SELECT f.filing, f.layer, q.quantity
FROM      (
    SELECT * FROM composition_fusions
) f
CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
EXCEPT
(
    SELECT s.composition, s.composed_layer, s.quantity
    FROM (
        SELECT * FROM composition_suspended_quantities
    ) s
    UNION
    SELECT d.filing, d.layer, d.quantity
    FROM (
        SELECT * FROM composition_derived_fusions
    ) d
)
),
eliminations_paired AS (
-- eliminations/filed.sqlc against folds/part_sums.sqlc.
SELECT x.composition, x.composed_layer, x.quantity,
       x.low, x.mode, x.high, x.unit, x.absent, x.derivation, x.reason, x.claim_seq, x.crossed,
       CASE WHEN x.crossed THEN x.high ELSE x.low  END AS at_low,
       CASE WHEN x.crossed THEN x.low  ELSE x.high END AS at_high
FROM (
    SELECT e.composition, e.composed_layer, e.quantity,
           e.low, e.mode, e.high, e.unit, e.absent, e.derivation, e.reason, e.claim_seq,
           coalesce(NOT (s.sum_low  - e.low  <= s.sum_mode - e.mode
                     AND s.sum_mode - e.mode <= s.sum_high - e.high), false) AS crossed
    FROM      (
        SELECT * FROM eliminations_filed
    ) e
    LEFT JOIN (
        SELECT * FROM folds_part_sums
    ) s ON s.composition = e.composition AND s.composed_layer = e.composed_layer
       AND s.quantity = e.quantity
) x
),
composition_fused AS (
-- folds/part_sums.sqlc against the composed layer's own figure, less eliminations/paired.sqlc at its corners.
SELECT x.composition, x.composed_layer, x.quantity,
       x.sum_low, x.sum_mode, x.sum_high, x.crossed,
       x.sum_low  - x.e_at_low  AS computed_low,
       x.sum_mode - x.e_mode    AS computed_mode,
       x.sum_high - x.e_at_high AS computed_high,
       x.filed_low, x.filed_mode, x.filed_high,
       (x.sum_low  - x.e_at_low  = x.filed_low
    AND x.sum_mode - x.e_mode    = x.filed_mode
    AND x.sum_high - x.e_at_high = x.filed_high) AS agrees
FROM (
    SELECT s.composition, s.composed_layer, s.quantity,
           s.sum_low, s.sum_mode, s.sum_high,
           coalesce(e.crossed, false) AS crossed,
           coalesce(e.at_low,  0) AS e_at_low,
           coalesce(e.mode,    0) AS e_mode,
           coalesce(e.at_high, 0) AS e_at_high,
           d.low  AS filed_low,
           d.mode AS filed_mode,
           d.high AS filed_high
    FROM      (
        SELECT * FROM folds_part_sums
    ) s
    JOIN      (
        SELECT * FROM composition_owed_equality
    ) o
           ON o.filing = s.composition AND o.layer = s.composed_layer
          AND o.quantity = s.quantity
    JOIN      (
        SELECT * FROM layers_summed_quantities
    ) d
           ON d.filing = s.composition AND d.layer = s.composed_layer
          AND d.quantity = s.quantity
    LEFT JOIN (
        SELECT * FROM eliminations_paired
    ) e
           ON e.composition = s.composition
          AND e.composed_layer = s.composed_layer
          AND e.quantity = s.quantity
) x
)
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT f.composition AS filing, f.composed_layer AS layer,
           bool_or(NOT f.agrees) AS violates,
           string_agg(format('%s: parts less eliminations give [%s, %s, %s]; the filing states [%s, %s, %s]',
                             f.quantity, f.computed_low, f.computed_mode, f.computed_high,
                             f.filed_low, f.filed_mode, f.filed_high),
                      '; ' ORDER BY f.quantity) AS detail
    FROM (
        SELECT * FROM composition_fused
    ) f
    GROUP BY f.composition, f.composed_layer
) p ON true
WHERE r.slug = 'fusion_sum_disagrees'
