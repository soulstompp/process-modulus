-- checks/roster.sqlc's declared subject against checks/all.sqlc's multiplicity and its key.
WITH
checks_roster AS MATERIALIZED (
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
fusions AS MATERIALIZED (
    -- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f

),
notations AS MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS MATERIALIZED (
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
parts AS MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
unresolved_parts AS MATERIALIZED (
    -- composition/part_references.sqlc less composition/parts.sqlc, per fusion and reference.
SELECT r.composition, r.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'a part resolves to no filing here' AS suspended_because,
       r.part_filing || '/' || r.part_layer AS note
FROM      (
    SELECT * FROM part_references
) r
LEFT JOIN (
    SELECT * FROM parts
) p ON  p.composition    = r.composition
    AND p.composed_layer = r.composed_layer
    AND p.part_notation  = r.part_filing
    AND p.part_layer     = r.part_layer
WHERE p.composition IS NULL

),
filed AS MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e

),
searched AS MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

),
fusion_parts AS MATERIALIZED (
    -- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM part_references
) r
GROUP BY r.composition, r.composed_layer

),
summed_quantities AS MATERIALIZED (
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
derived_quantities AS MATERIALIZED (
    -- composition/derived_frontier.sqlc summed at the nodes stating the figure, less eliminations/filed.sqlc at the root and each derived node passed.
WITH
root AS (
    SELECT s.filing, s.layer, s.quantity, s.derivation, coalesce(b.parts, 0) AS parts
    FROM      ( SELECT * FROM summed_quantities ) s
    LEFT JOIN (
        SELECT * FROM fusion_parts
    ) b ON b.composition = s.filing AND b.composed_layer = s.layer
    WHERE s.derivation IS NOT NULL
),
node AS (
    SELECT w.root_filing, w.root_layer, w.quantity, w.filing, w.layer, w.depth,
           w.factor_low, w.factor_mode, w.factor_high, w.part_of, w.conversion_absent,
           w.conversion_derivation, w.is_cycle,
           w.low, w.mode, w.high, w.unit, w.absent, w.derivation, w.is_fusion
    FROM ( -- layers/summed_quantities.sqlc filed as a derivation, walked through composition/parts.sqlc while the node's figure is derived too.
WITH RECURSIVE
resolved AS (
    SELECT * FROM parts
),
figure AS (
    SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation,
           (f.filing IS NOT NULL) AS is_fusion
    FROM      (
        SELECT * FROM summed_quantities
    ) s
    LEFT JOIN (
        SELECT * FROM fusions
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
 ) w
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
    LEFT JOIN ( SELECT * FROM filed ) e
           ON e.composition = p.filing AND e.composed_layer = p.layer AND e.quantity = p.quantity
    LEFT JOIN ( SELECT * FROM searched ) es
           ON es.composition = p.filing AND es.composed_layer = p.layer
),
unresolved AS MATERIALIZED (
    SELECT DISTINCT u.composition, u.composed_layer
    FROM ( SELECT * FROM unresolved_parts ) u
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
resolved_quantities AS MATERIALIZED (
    -- layers/summed_quantities.sqlc where no derivation is filed, beside composition/derived_quantities.sqlc where one is.
SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent,
       false                  AS derived,
       s.derivation,
       NULL::text             AS blocked_because
FROM (
    SELECT * FROM summed_quantities
) s
WHERE s.derivation IS NULL
UNION ALL
SELECT d.filing, d.layer, d.quantity, d.low, d.mode, d.high, d.unit,
       NULL::pm.absence_reason,
       d.low IS NOT NULL,
       d.derivation,
       d.blocked_because
FROM (
    SELECT * FROM derived_quantities
) d

),
slacks AS MATERIALIZED (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s

),
demand AS MATERIALIZED (
    -- composition/resolved_quantities.sqlc's pm:Layer/pm:Demand, where it has a figure.
SELECT q.filing, q.layer,
       q.low  AS d_low,
       q.mode AS d_mode,
       q.high AS d_high,
       q.unit AS d_unit,
       q.low = q.high AS is_a_point,
       q.derived AS d_derived
FROM (
    SELECT * FROM resolved_quantities
) q
WHERE q.quantity = 'demand'
  AND q.low IS NOT NULL

),
layers_nameplate AS MATERIALIZED (
    -- pm:Layer/pm:Nameplate, its Divisibility and its window, with the amount from
-- composition/derived_quantities.sqlc where it is filed `derived`.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       false AS n_derived,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL
UNION ALL
SELECT n.filing, n.layer, q.low, q.mode, q.high, q.unit, true,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM pm.nameplate n
JOIN (
    SELECT * FROM derived_quantities
) q ON q.filing = n.filing AND q.layer = n.layer AND q.quantity = 'nameplate'
WHERE q.low IS NOT NULL

),
quantities AS MATERIALIZED (
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand'::public.layer_quantity AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    SELECT * FROM demand
) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::public.layer_quantity,
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    SELECT * FROM layers_nameplate
) n
UNION ALL
SELECT s.filing, s.layer, (s.buffer || 'Slack')::public.layer_quantity,
       s.low, s.mode, s.high, s.unit
FROM (
    SELECT * FROM slacks
) s
WHERE s.low IS NOT NULL

),
part_quantities AS MATERIALIZED (
    -- composition/parts.sqlc with layers/quantities.sqlc at the part's layer and at the composed layer.
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       p.factor_state, p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       part.quantity,
       part.low  AS part_low,  part.mode AS part_mode,  part.high AS part_high,  part.unit AS part_unit,
       comp.low  AS composed_low, comp.mode AS composed_mode, comp.high AS composed_high,
       comp.unit AS composed_unit
FROM      (
    SELECT * FROM parts
) p
JOIN      (
    SELECT * FROM quantities
) part ON part.filing = p.part_filing AND part.layer = p.part_layer
JOIN      (
    SELECT * FROM quantities
) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = part.quantity

),
carriable AS MATERIALIZED (
    -- composition/part_quantities.sqlc for a fusion that files one part, where the factor has a figure.
SELECT q.composition AS filing, q.composed_layer AS layer, q.quantity,
       least(   q.part_low  * coalesce(q.factor_low, 1),
                q.part_low  * coalesce(q.factor_high, 1)) AS part_low,
       q.part_mode * coalesce(q.factor_mode, 1)           AS part_mode,
       greatest(q.part_high * coalesce(q.factor_low, 1),
                q.part_high * coalesce(q.factor_high, 1)) AS part_high,
       q.part_unit,
       q.composed_low AS filed_low, q.composed_mode AS filed_mode, q.composed_high AS filed_high,
       q.composed_unit AS filed_unit
FROM      (
    SELECT * FROM part_quantities
) q
JOIN      (
    SELECT * FROM fusion_parts
) f ON f.composition = q.composition AND f.composed_layer = q.composed_layer
WHERE q.factor_state IN ('omitted', 'stated')
  AND f.parts = 1

),
fusion_quantities AS MATERIALIZED (
    -- composition/fusions.sqlc joined to layers/summed_quantities.sqlc on the composed layer.
SELECT f.filing, f.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation
FROM      (
    SELECT * FROM fusions
) f
JOIN      (
    SELECT * FROM summed_quantities
) s ON s.filing = f.filing AND s.layer = f.layer

),
unsized_conversions AS MATERIALIZED (
    -- asrt:Part/asrt:factor taking its pm:absent or pm:derivation branch, as a suspension of the composed sum.
SELECT p.composition, p.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       CASE WHEN p.factor_state = 'derivation'
            THEN format('the conversion is filed as `%s`, and no computation of it is wired into '
                        'the sum', p.factor_derivation)
            ELSE 'the conversion was filed and could not be sized' END AS suspended_because,
       coalesce(p.factor_absent::text, p.factor_derivation::text) AS note
FROM (
    SELECT * FROM parts
) p
WHERE p.factor_state IN ('absent', 'derivation')

),
filed_grounds AS MATERIALIZED (
    -- the five grounds decided by what is filed, one row per ground, carrying the quantity it lifts.
-- eliminations/searched.sqlc, kept where asrt:absent/pm:reason is "unmeasured".
SELECT es.composition, es.composed_layer,
       NULL::pm.summed_quantity AS quantity,
       'the search was never made' AS suspended_because,
       es.note
FROM (
    SELECT * FROM searched
) es
WHERE es.answer = 'unmeasured'
UNION ALL
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       CASE WHEN e.derivation IS NOT NULL
            THEN format('the elimination is filed as `%s`, and no computation of it is wired into '
                        'the sum', e.derivation)
            ELSE 'the overlap was found and could not be sized' END AS suspended_because,
       e.reason AS note
FROM (
    SELECT * FROM filed
) e
WHERE e.absent IS NOT NULL OR e.derivation IS NOT NULL
UNION ALL
SELECT * FROM unsized_conversions
UNION ALL
-- layers/summed_quantities.sqlc without a figure on a part or on the composed layer, and not a derivation, per fusion.
SELECT u.composition, u.composed_layer, u.quantity,
       'the quantity is not stated on every layer the sum reads' AS suspended_because,
       string_agg(u.layer || ' ' || coalesce(u.absent::text, 'unstated'), ', ' ORDER BY u.layer)
           AS note
FROM (
    SELECT p.composition, p.composed_layer, s.quantity,
           p.part_filing || '/' || p.part_layer AS layer, s.absent
    FROM      (
        SELECT * FROM parts
    ) p
    JOIN      (
        SELECT * FROM summed_quantities
    ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
    WHERE s.low IS NULL
      AND s.derivation IS NULL
    UNION ALL
    SELECT q.filing, q.layer, q.quantity, 'the composed layer', q.absent
    FROM (
        SELECT * FROM fusion_quantities
    ) q
    WHERE q.low IS NULL
      AND q.derivation IS NULL
) u
GROUP BY u.composition, u.composed_layer, u.quantity
UNION ALL
SELECT * FROM unresolved_parts

),
suspension_grounds AS MATERIALIZED (
    -- the grounds that lift the sum rule: those read off the filing, and a derived part that cannot be computed.
SELECT * FROM filed_grounds
UNION ALL
-- composition/parts.sqlc whose figure composition/derived_quantities.sqlc cannot compute, per fusion.
SELECT p.composition, p.composed_layer, d.quantity,
       'a part files the quantity derived and it cannot be computed' AS suspended_because,
       string_agg(p.part_filing || '/' || p.part_layer || ': ' || d.blocked_because, ', '
                  ORDER BY p.part_filing, p.part_layer) AS note
FROM      (
    SELECT * FROM parts
) p
JOIN      (
    SELECT * FROM derived_quantities
) d ON d.filing = p.part_filing AND d.layer = p.part_layer
WHERE d.low IS NULL
GROUP BY p.composition, p.composed_layer, d.quantity


),
suspended_fusions AS MATERIALIZED (
    -- composition/suspension_grounds.sqlc projected onto the fusion it suspends.
SELECT DISTINCT g.composition, g.composed_layer, g.quantity
FROM (
    SELECT * FROM suspension_grounds
) g

),
suspended_quantities AS MATERIALIZED (
    -- composition/suspended_fusions.sqlc expanded onto pm.summed_quantity.
SELECT DISTINCT s.composition, s.composed_layer, q.quantity
FROM      (
    SELECT * FROM suspended_fusions
) s
JOIN      unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
       ON s.quantity IS NULL OR s.quantity = q.quantity

),
carried AS MATERIALIZED (
    -- composition/carriable.sqlc less the fusions that eliminate or owe no sum.
SELECT c.*
FROM      (
    SELECT * FROM carriable
) c
WHERE NOT EXISTS (
        SELECT 1 FROM ( SELECT * FROM filed ) e
        WHERE e.composition = c.filing AND e.composed_layer = c.layer)
  AND NOT EXISTS (
        SELECT 1 FROM ( SELECT * FROM suspended_quantities ) s
        WHERE s.composition = c.filing AND s.composed_layer = c.layer
          AND s.quantity::text = c.quantity::text)

),
citations AS MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

),
composer_regimes AS MATERIALIZED (
    -- asrt:regime at the root of an asrt:composition, one row per declaration in document order.
SELECT r.composition, r.seq, r.id, r.jurisdiction,
       r.framework_taxonomy, r.framework_value, r.framework_absent,
       r.chart_taxonomy, r.chart_value, r.chart_absent
FROM pm.composition_regime r

),
converted AS MATERIALIZED (
    -- asrt:Part/asrt:factor applied to each quantity the part layer states.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, s.quantity,
       least(   s.low  * coalesce(p.factor_low, 1), s.low  * coalesce(p.factor_high, 1)) AS low,
       s.mode * coalesce(p.factor_mode, 1)                                               AS mode,
       greatest(s.high * coalesce(p.factor_low, 1), s.high * coalesce(p.factor_high, 1)) AS high
FROM      (
    SELECT * FROM parts
) p
JOIN      (
    SELECT * FROM resolved_quantities
) s
       ON s.filing = p.part_filing AND s.layer = p.part_layer
  AND s.low IS NOT NULL
  AND p.factor_state IN ('omitted', 'stated')

),
derived_fusions AS MATERIALIZED (
    -- composition/fusion_quantities.sqlc filed as a derivation.
SELECT q.filing, q.layer, q.quantity
FROM (
    SELECT * FROM fusion_quantities
) q
WHERE q.derivation IS NOT NULL

),
descent AS MATERIALIZED (
    -- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    SELECT * FROM parts
),
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation')
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation')
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT root_filing, root_layer, filing, layer, depth, path,
       factor_low, factor_mode, factor_high, factor_absent, is_cycle
FROM walk

),
unsettled AS MATERIALIZED (
    -- composition/parts.sqlc restricted to the parts whose factor has width or no figure.
SELECT DISTINCT p.composition AS filing, p.composed_layer AS layer
FROM (
    SELECT * FROM parts
) p
WHERE p.factor_state IN ('absent', 'derivation')
   OR (p.factor_state = 'stated' AND p.factor_low <> p.factor_high)

),
remainder_frontier AS MATERIALIZED (
    -- composition/parts.sqlc walked while composition/unsettled.sqlc holds, carrying the product.
WITH RECURSIVE
resolved AS (
    SELECT * FROM parts
),
open_node AS (
    SELECT * FROM unsettled
),
frontier(root_filing, root_layer, filing, layer, depth,
         factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation')
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation')
        FROM frontier w
        JOIN open_node o ON o.filing = w.filing AND o.layer = w.layer
        JOIN resolved p  ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT f.root_filing, f.root_layer, f.filing, f.layer, f.depth,
       f.factor_low, f.factor_mode, f.factor_high, f.factor_absent, f.is_cycle,
       (NOT f.factor_absent AND NOT f.is_cycle) AS usable
FROM frontier f

),
passed_nodes AS MATERIALIZED (
    -- composition/remainder_frontier.sqlc restricted to the nodes composition/unsettled.sqlc names.
SELECT w.*
FROM      (
    SELECT * FROM remainder_frontier
) w
JOIN      (
    SELECT * FROM unsettled
) u ON u.filing = w.filing AND u.layer = w.layer

),
suspended_remainders AS MATERIALIZED (
    -- composition/filed_grounds.sqlc restricted to the two quantities r is built from, at the layer or a node its walk passes;
-- composition/resolved_quantities.sqlc without a demand or nameplate figure at the layer or a node the walk reaches.
SELECT DISTINCT t.root_filing AS composition, t.root_layer AS composed_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM fusions
    ) f
    UNION ALL
    SELECT w.root_filing, w.root_layer, w.filing, w.layer
    FROM (
        SELECT * FROM passed_nodes
    ) w
) t
JOIN      (
    SELECT * FROM filed_grounds
) s ON s.composition = t.filing AND s.composed_layer = t.layer
WHERE s.quantity IS NULL
   OR s.quantity IN ('demand', 'nameplate')
UNION
SELECT w.root_filing, w.root_layer
FROM      (
    SELECT f.filing AS root_filing, f.layer AS root_layer, f.filing, f.layer
    FROM (
        SELECT * FROM fusions
    ) f
    UNION ALL
    SELECT r.root_filing, r.root_layer, r.filing, r.layer
    FROM (
        SELECT * FROM remainder_frontier
    ) r
) w
JOIN      (
    SELECT * FROM resolved_quantities
) q ON q.filing = w.filing AND q.layer = w.layer
WHERE q.quantity IN ('demand', 'nameplate')
  AND q.low IS NULL

),
figureless_remainders AS MATERIALIZED (
    -- composition/unsettled.sqlc within composition/suspended_remainders.sqlc.
SELECT o.filing, o.layer
FROM      (
    SELECT * FROM unsettled
) o
JOIN      (
    SELECT * FROM suspended_remainders
) l ON l.composition = o.filing AND l.composed_layer = o.layer

),
owed_equality AS MATERIALIZED (
    -- composition/fusions.sqlc for every quantity, minus the suspensions that lift each sum and the
-- composed figures filed `derived`.
SELECT f.filing, f.layer, q.quantity
FROM      (
    SELECT * FROM fusions
) f
CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
EXCEPT
(
    SELECT s.composition, s.composed_layer, s.quantity
    FROM (
        SELECT * FROM suspended_quantities
    ) s
    UNION
    SELECT d.filing, d.layer, d.quantity
    FROM (
        SELECT * FROM derived_fusions
    ) d
)

),
part_sums AS MATERIALIZED (
    -- composition/converted.sqlc folded to one row per composed layer and quantity.
SELECT c.composition, c.composed_layer, c.quantity,
       sum(c.low)  AS sum_low,
       sum(c.mode) AS sum_mode,
       sum(c.high) AS sum_high,
       count(*)    AS parts
FROM (
    SELECT * FROM converted
) c
GROUP BY c.composition, c.composed_layer, c.quantity

),
paired AS MATERIALIZED (
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
        SELECT * FROM filed
    ) e
    LEFT JOIN (
        SELECT * FROM part_sums
    ) s ON s.composition = e.composition AND s.composed_layer = e.composed_layer
       AND s.quantity = e.quantity
) x

),
fused AS MATERIALIZED (
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
        SELECT * FROM part_sums
    ) s
    JOIN      (
        SELECT * FROM owed_equality
    ) o
           ON o.filing = s.composition AND o.layer = s.composed_layer
          AND o.quantity = s.quantity
    JOIN      (
        SELECT * FROM summed_quantities
    ) d
           ON d.filing = s.composition AND d.layer = s.composed_layer
          AND d.quantity = s.quantity
    LEFT JOIN (
        SELECT * FROM paired
    ) e
           ON e.composition = s.composition
          AND e.composed_layer = s.composed_layer
          AND e.quantity = s.quantity
) x

),
owed_remainder AS MATERIALIZED (
    -- composition/fusions.sqlc less composition/suspended_remainders.sqlc.
SELECT f.filing, f.layer
FROM      (
    SELECT * FROM fusions
) f
LEFT JOIN (
    SELECT * FROM suspended_remainders
) s ON s.composition = f.filing AND s.composed_layer = f.layer
WHERE s.composition IS NULL

),
figures AS MATERIALIZED (
    -- layers/demand.sqlc and layers/nameplate.sqlc on the layer, each side where it has a figure.
SELECT filing, layer,
       d.d_low, d.d_mode, d.d_high, d.d_unit, d.is_a_point, d.d_derived,
       n.n_low, n.n_mode, n.n_high, n.n_unit, n.n_derived,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent
FROM      (
    SELECT * FROM demand
) d
FULL JOIN (
    SELECT * FROM layers_nameplate
) n USING (filing, layer)

),
filed_remainders AS MATERIALIZED (
    -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value, l.absorber_absent,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       l.sign_derivation, l.qty_derivation
FROM pm.layer l
WHERE l.remainder_absent IS NULL

),
differenced_remainder AS MATERIALIZED (
    -- layers/figures.sqlc where both figures are present, beside the sign and absorber of
-- layers/filed_remainders.sqlc.
SELECT x.filing, x.layer,
       f.sign, f.sign_absent,
       f.absorber_taxonomy, f.absorber_value, f.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.d_unit AS unit,
       x.n_low, x.n_mode, x.n_high, x.n_unit AS amount_unit,
       x.n_low  - x.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.high
       x.n_mode - x.d_mode AS r_mode,
       x.n_high - x.d_low  AS r_high,
       CASE WHEN x.n_low  - x.d_high >= 0 THEN 'clearance'::pm.fit
            WHEN x.n_high - x.d_low  <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(x.d_high - x.n_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit
FROM      (
    SELECT * FROM figures
) x
LEFT JOIN (
    SELECT * FROM filed_remainders
) f USING (filing, layer)
WHERE x.d_low IS NOT NULL
  AND x.n_low IS NOT NULL

),
settled_remainders AS MATERIALIZED (
    -- composition/remainder_frontier.sqlc less the nodes composition/unsettled.sqlc names,
-- against layers/differenced_remainder.sqlc at the node the walk stops on.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer,
       w.filing AS node_filing, w.layer AS node_layer, w.depth,
       w.factor_low, w.factor_mode, w.factor_high,
       least(   r.r_low  * w.factor_low, r.r_low  * w.factor_high) AS r_low,
       r.r_mode * w.factor_mode                                    AS r_mode,
       greatest(r.r_high * w.factor_low, r.r_high * w.factor_high) AS r_high,
       (w.factor_low IS DISTINCT FROM w.factor_high)               AS spread_factor
FROM      (
    SELECT * FROM remainder_frontier
) w
JOIN      (
    SELECT * FROM differenced_remainder
) r ON r.filing = w.filing AND r.layer = w.layer
LEFT JOIN (
    SELECT * FROM unsettled
) o ON o.filing = w.filing AND o.layer = w.layer
WHERE w.usable
  AND o.filing IS NULL

),
fused_remainders AS MATERIALIZED (
    -- composition/settled_remainders.sqlc summed over the settled frontier, less eliminations/paired.sqlc at their own corners.
SELECT y.composition, y.composed_layer,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_low  ELSE y.r_low  - y.n_high + y.d_low  END AS pivoted_low,
       y.pivoted_mode,
       CASE WHEN y.paired_low <= y.pivoted_mode AND y.pivoted_mode <= y.paired_high
            THEN y.paired_high ELSE y.r_high - y.n_low  + y.d_high END AS pivoted_high,
       y.derived_low, y.derived_mode, y.derived_high, y.derived_fit, y.unit, y.parts, y.spread
FROM (
    SELECT x.*,
           x.r_low  - x.n_at_low
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_low  ELSE x.d_at_high END AS paired_low,
           x.r_mode - x.n_mode + x.d_mode                                            AS pivoted_mode,
           x.r_high - x.n_at_high
             + CASE WHEN x.spread AND x.r_low >= 0 THEN x.d_at_high ELSE x.d_at_low  END AS paired_high,
           least(x.n_at_low, x.n_at_high)    AS n_low,
           greatest(x.n_at_low, x.n_at_high) AS n_high,
           least(x.d_at_low, x.d_at_high)    AS d_low,
           greatest(x.d_at_low, x.d_at_high) AS d_high
    FROM (
        SELECT c.composition, c.composed_layer,
               sum(c.r_low)  AS r_low,
               sum(c.r_mode) AS r_mode,
               sum(c.r_high) AS r_high,
               bool_or(c.spread_factor) AS spread,
               coalesce(max(e.n_at_low),  0) + coalesce(max(k.n_low),  0) AS n_at_low,
               coalesce(max(e.n_mode),    0) + coalesce(max(k.n_mode), 0) AS n_mode,
               coalesce(max(e.n_at_high), 0) + coalesce(max(k.n_high), 0) AS n_at_high,
               coalesce(max(e.d_at_low),  0) + coalesce(max(k.d_low),  0) AS d_at_low,
               coalesce(max(e.d_mode),    0) + coalesce(max(k.d_mode), 0) AS d_mode,
               coalesce(max(e.d_at_high), 0) + coalesce(max(k.d_high), 0) AS d_at_high,
               max(d.r_low)  AS derived_low,
               max(d.r_mode) AS derived_mode,
               max(d.r_high) AS derived_high,
               max(d.derived_fit) AS derived_fit,
               max(d.unit)   AS unit,
               count(*)      AS parts
        FROM      (
            SELECT * FROM settled_remainders
        ) c
        JOIN      (
            SELECT * FROM owed_remainder
        ) o  ON o.filing = c.composition AND o.layer = c.composed_layer
        JOIN      (
            SELECT * FROM differenced_remainder
        ) d  ON d.filing = c.composition AND d.layer = c.composed_layer
        LEFT JOIN (
            SELECT p.composition, p.composed_layer,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'nameplate') AS n_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'nameplate') AS n_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'nameplate') AS n_at_high,
                   max(p.at_low)  FILTER (WHERE p.quantity = 'demand')    AS d_at_low,
                   max(p.mode)    FILTER (WHERE p.quantity = 'demand')    AS d_mode,
                   max(p.at_high) FILTER (WHERE p.quantity = 'demand')    AS d_at_high
            FROM (
                SELECT * FROM paired
            ) p
            GROUP BY p.composition, p.composed_layer
        ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
        LEFT JOIN (
            SELECT w.composition, w.composed_layer,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'nameplate') AS n_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'nameplate') AS n_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'nameplate') AS n_high,
                   max(w.e_low)  FILTER (WHERE w.quantity = 'demand')    AS d_low,
                   max(w.e_mode) FILTER (WHERE w.quantity = 'demand')    AS d_mode,
                   max(w.e_high) FILTER (WHERE w.quantity = 'demand')    AS d_high
            FROM (
                -- eliminations/paired.sqlc at the nodes composition/passed_nodes.sqlc names, along a usable path.
SELECT w.root_filing AS composition, w.root_layer AS composed_layer, e.quantity,
       count(*)                                                        AS through_layers,
       sum(least(   e.at_low  * w.factor_low, e.at_low  * w.factor_high)) AS e_low,
       sum(e.mode * w.factor_mode)                                     AS e_mode,
       sum(greatest(e.at_high * w.factor_low, e.at_high * w.factor_high)) AS e_high,
       bool_or(e.absent IS NOT NULL OR e.derivation IS NOT NULL)       AS unsized
FROM      (
    SELECT * FROM passed_nodes
) w
JOIN      (
    SELECT * FROM paired
) e ON e.composition = w.filing AND e.composed_layer = w.layer
WHERE w.usable
GROUP BY w.root_filing, w.root_layer, e.quantity

            ) w
            GROUP BY w.composition, w.composed_layer
        ) k ON k.composition = c.composition AND k.composed_layer = c.composed_layer
        GROUP BY c.composition, c.composed_layer
    ) x
) y

),
jagged_layers AS MATERIALIZED (
    -- composition/parts.sqlc self-joined on the fusion, against the reflexive closure of
-- composition/descent.sqlc, for the layer two sibling parts both reach.
SELECT DISTINCT
       a.composition    AS filing,
       a.composed_layer AS layer,
       r1.filing        AS doubled_filing,
       r1.layer         AS doubled_layer,
       a.part_filing    AS via_filing,
       a.part_layer     AS via_layer,
       b.part_filing    AS also_via_filing,
       b.part_layer     AS also_via_layer
FROM      (
    SELECT * FROM parts
) a
JOIN      (
    SELECT * FROM parts
) b ON  b.composition    = a.composition
    AND b.composed_layer = a.composed_layer
    AND (a.part_filing, a.part_layer) < (b.part_filing, b.part_layer)
JOIN      (
    -- composition/descent.sqlc unioned with the identity on composition/parts.sqlc: F* = F+ ∪ I.
SELECT DISTINCT root_filing, root_layer, filing, layer
FROM (
    SELECT * FROM descent
) w
  UNION
SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
FROM (
    SELECT * FROM parts
) p

) r1 ON r1.root_filing = a.part_filing AND r1.root_layer = a.part_layer
JOIN      (
    -- composition/descent.sqlc unioned with the identity on composition/parts.sqlc: F* = F+ ∪ I.
SELECT DISTINCT root_filing, root_layer, filing, layer
FROM (
    SELECT * FROM descent
) w
  UNION
SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
FROM (
    SELECT * FROM parts
) p

) r2 ON  r2.root_filing = b.part_filing AND r2.root_layer = b.part_layer
     AND r2.filing = r1.filing AND r2.layer = r1.layer

),
regimes AS MATERIALIZED (
    -- pm:Regime, one row per declaration in document order.
SELECT r.filing, r.seq, r.id, r.jurisdiction,
       r.framework_taxonomy, r.framework_value, r.framework_absent,
       r.chart_taxonomy, r.chart_value, r.chart_absent
FROM pm.regime r

),
part_regimes AS MATERIALIZED (
    -- composition/parts.sqlc's regime handle resolved into composition/composer_regimes.sqlc, against
-- the part filing's own composition/regimes.sqlc.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_value IS NOT NULL AND EXISTS (
            SELECT 1
            FROM (
                SELECT * FROM regimes
            ) r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*)
        FROM (
            SELECT * FROM regimes
        ) r
        WHERE r.filing = p.part_filing AND r.framework_value IS NOT NULL) AS frameworks_the_filing_states
FROM      (
    SELECT * FROM parts
) p
JOIN      (
    SELECT * FROM composer_regimes
) cr ON cr.composition = p.composition AND cr.id = p.part_regime

),
absorber AS MATERIALIZED (
    -- pm:Remainder/absorber, resolved through pm.buffer_term.
SELECT l.filing, l.layer,
       l.absorber_taxonomy AS taxonomy,
       l.absorber_value    AS term,
       bt.buffer,
       bt.note AS the_readers_warrant
FROM pm.layer l
JOIN pm.buffer_term bt ON bt.taxonomy = l.absorber_taxonomy AND bt.value = l.absorber_value

),
absorbing_slack AS MATERIALIZED (
    -- layers/absorber.sqlc joined to entries/slacks.sqlc on the buffer the layer actually names.
SELECT a.filing, a.layer, a.buffer,
       a.taxonomy, a.term, a.the_readers_warrant,
       s.low, s.mode, s.high, s.unit, s.absent, s.sized
FROM      (
    SELECT * FROM absorber
) a
JOIN      (
    SELECT * FROM slacks
) s USING (filing, layer, buffer)

),
couplings AS MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
windows AS MATERIALIZED (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n

),
derived_time_slacks AS MATERIALIZED (
    -- pm:Layer/pm:timeSlack filed as a clearance derivation, beside pm:Divisibility/pm:window.
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    SELECT * FROM windows
) w
JOIN      (
    SELECT * FROM slacks
) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.derivation = 'clearance'

),
holders AS MATERIALIZED (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h

),
holder_totals AS MATERIALIZED (
    -- entries/holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                     AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)  AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                              AS shares_low,
       sum(h.share_mode)                             AS shares_mode,
       sum(h.share_high)                             AS shares_high,
       array_agg(DISTINCT h.share_unit)              AS share_units
FROM (
    SELECT * FROM holders
) h
GROUP BY h.filing, h.layer

),
served_holders AS MATERIALIZED (
    -- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    SELECT * FROM holders
) h
WHERE h.kind IN ('booked', 'counterparty', 'people')

),
unserved_holders AS MATERIALIZED (
    -- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    SELECT * FROM holders
) h
WHERE h.kind IN ('customer', 'unrealised')

),
unserved_totals AS MATERIALIZED (
    -- entries/unserved_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_high IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_high)                                AS unserved_high,
       sum(h.share_mode)                                AS unserved_mode,
       array_agg(DISTINCT h.share_unit)                 AS share_units
FROM (
    SELECT * FROM unserved_holders
) h
GROUP BY h.filing, h.layer

),
claims AS MATERIALIZED (
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
claim_derivations AS MATERIALIZED (
    -- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking their pm:derivation branch, at the claim's own position.
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:boundOrigin' AS element,
       c.origin_derivation AS identity
FROM (
    SELECT * FROM claims
) c
WHERE c.origin_derivation IS NOT NULL
UNION ALL
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:narrowsWhen', c.narrows_derivation
FROM (
    SELECT * FROM claims
) c
WHERE c.narrows_derivation IS NOT NULL

),
point_claims AS MATERIALIZED (
    -- pm:Claim where low = high, at every element that carries one.
SELECT c.*
FROM (
    SELECT * FROM claims
) c
WHERE c.is_a_point

),
served_totals AS MATERIALIZED (
    -- entries/served_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                                 AS served_low,
       sum(h.share_mode)                                AS served_mode,
       sum(h.share_high)                                AS served_high,
       array_agg(DISTINCT h.share_unit)                 AS share_units,
       string_agg(DISTINCT h.kind::text, ' and ')       AS kinds
FROM (
    SELECT * FROM served_holders
) h
GROUP BY h.filing, h.layer

),
identities_roster AS MATERIALIZED (
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

),
denied_remainders AS MATERIALIZED (
    -- pm:Layer/pm:remainder taking the pm:absent branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.remainder_absent      AS reason,
       l.remainder_absent_note AS argument
FROM pm.layer l
WHERE l.remainder_absent IS NOT NULL

),
drawn AS MATERIALIZED (
    -- pm:Jagged/pm:draw from composition/resolved_quantities.sqlc, against layers/nameplate.sqlc and entries/slacks.sqlc's capacity slack.
SELECT dr.filing, dr.layer,
       dr.low  AS draw_low,
       dr.mode AS draw_mode,
       dr.high AS draw_high,
       dr.unit AS draw_unit,
       n.low   AS n_low,
       n.mode  AS n_mode,
       n.high  AS n_high,
       n.unit  AS n_unit,
       s.low    AS capacity_low,
       s.mode   AS capacity_slack,
       s.high   AS capacity_high,
       s.unit   AS capacity_unit,
       s.absent AS capacity_absent
FROM      (
    SELECT q.filing, q.layer, q.low, q.mode, q.high, q.unit
    FROM ( SELECT * FROM resolved_quantities ) q
    WHERE q.quantity = 'draw'
      AND q.low IS NOT NULL
) dr
JOIN      (
    SELECT n.filing, n.layer, n.n_low AS low, n.n_mode AS mode, n.n_high AS high, n.n_unit AS unit
    FROM ( SELECT * FROM layers_nameplate ) n
) n ON n.filing = dr.filing AND n.layer = dr.layer
LEFT JOIN (
    SELECT * FROM slacks
) s ON s.filing = dr.filing AND s.layer = dr.layer AND s.buffer = 'capacity'

),
every_layer AS MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

),
remainder AS MATERIALIZED (
    
-- layers/differenced_remainder.sqlc, overridden by composition/fused_remainders.sqlc where a
-- composed layer owes an exact remainder, less composition/figureless_remainders.sqlc.
SELECT x.filing, x.layer,
       x.sign, x.sign_absent,
       x.absorber_taxonomy, x.absorber_value, x.absorber_absent,
       x.d_low, x.d_mode, x.d_high, x.unit,
       x.n_low, x.n_mode, x.n_high, x.amount_unit,
       x.r_low, x.r_mode, x.r_high,
       CASE WHEN x.r_low  >= 0 THEN 'clearance'::pm.fit
            WHEN x.r_high <= 0 THEN 'interference'::pm.fit
            ELSE 'transition'::pm.fit END AS derived_fit,
       greatest(-x.r_low, 0) AS exposure,
       x.lumpy, x.quantum_mode, x.quantum_unit,
       x.pivoted,
       CASE WHEN x.r_low <= 0 AND x.r_high >= 0 THEN 0
            ELSE least(abs(x.r_low), abs(x.r_high)) END AS m_low,
       abs(x.r_mode)                                    AS m_mode,
       greatest(abs(x.r_low), abs(x.r_high))            AS m_high
FROM (
    SELECT b.filing, b.layer,
           b.sign, b.sign_absent,
           b.absorber_taxonomy, b.absorber_value, b.absorber_absent,
           b.d_low, b.d_mode, b.d_high, b.unit,
           b.n_low, b.n_mode, b.n_high, b.amount_unit,
           coalesce(f.pivoted_low,  b.r_low)  AS r_low,
           coalesce(f.pivoted_mode, b.r_mode) AS r_mode,
           coalesce(f.pivoted_high, b.r_high) AS r_high,
           b.lumpy, b.quantum_mode, b.quantum_unit,
           (f.pivoted_low IS NOT NULL) AS pivoted
    FROM      (
        SELECT * FROM differenced_remainder
    ) b
    LEFT JOIN (
        SELECT * FROM fused_remainders
    ) f ON f.composition = b.filing AND f.composed_layer = b.layer
    WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM figureless_remainders ) g
                      WHERE g.filing = b.filing AND g.layer = b.layer)
) x

),
exposure_scope AS MATERIALIZED (
    -- layers/remainder.sqlc where exposure > 0, classified by layers/absorption.sqlc.
SELECT r.*, a.absorbable, a.unknown,
       CASE WHEN a.unknown    > 0 THEN 'a buffer nobody sized'::public.exposure_standing
            WHEN a.absorbable > 0 THEN 'a buffer with room in it'::public.exposure_standing
            ELSE                       'every buffer sized and empty'::public.exposure_standing END AS standing
FROM      (
    SELECT * FROM remainder
) r
JOIN      (
    -- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack, summed across the row in the demand's unit.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE (s.sized AND s.unit IS NOT DISTINCT FROM d.d_unit)
                    OR s.absent = 'notApplicable')                                 AS absorbable,
       count(*)
         FILTER (WHERE (NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable')
                    OR (s.sized AND s.unit IS DISTINCT FROM d.d_unit))        AS unknown
FROM      (
    SELECT * FROM slacks
) s
LEFT JOIN (
    SELECT * FROM demand
) d ON d.filing = s.filing AND d.layer = s.layer
GROUP BY s.filing, s.layer

) a USING (filing, layer)
WHERE r.exposure > 1e-9

),
filed_against_derived AS MATERIALIZED (
    -- layers/filed_remainders.sqlc against layers/remainder.sqlc, on the layer they share.
SELECT l.filing, l.layer,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       r.r_low, r.r_mode, r.r_high, r.unit,
       r.m_low, r.m_mode, r.m_high,
       r.d_low, r.d_mode, r.d_high,
       r.n_low, r.n_mode, r.n_high, r.amount_unit,
       r.sign, r.derived_fit
FROM      (
    SELECT * FROM filed_remainders
) l
JOIN      (
    SELECT * FROM remainder
) r USING (filing, layer)

),
lumpy AS MATERIALIZED (
    -- layers/figures.sqlc where the nameplate is lumpy, the demand beside it where stated.
SELECT f.filing, f.layer,
       f.n_low, f.n_mode, f.n_high, f.n_unit AS amount_unit,
       f.quantum_low, f.quantum_mode, f.quantum_high, f.quantum_unit, f.quantum_absent,
       f.d_low, f.d_mode, f.d_high, f.d_unit AS unit
FROM (
    SELECT * FROM figures
) f
WHERE f.lumpy

),
pressed AS MATERIALIZED (
    -- pm:Remainder/sign in {interference, transition}.
SELECT r.*
FROM (
    SELECT * FROM remainder
) r
WHERE r.sign IN ('interference', 'transition')

),
signed AS MATERIALIZED (
    -- pm:Remainder/sign, stated rather than absent.
SELECT r.*
FROM (
    SELECT * FROM remainder
) r
WHERE r.sign IS NOT NULL

),
unabsorbed_exposure AS MATERIALIZED (
    -- layers/exposure_scope.sqlc, restricted to the standing that licenses a conclusion.
SELECT s.*
FROM (
    SELECT * FROM exposure_scope
) s
WHERE s.standing = 'every buffer sized and empty'

),
conversions AS MATERIALIZED (
    -- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       p.part_unit     AS from_unit,
       p.composed_unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
FROM (
    SELECT * FROM part_quantities
) p
WHERE p.quantity = 'nameplate'
  AND p.factor_state = 'stated'

),
with_a_period AS MATERIALIZED (
    -- pm:Claim/pm:denominator/pm:period, at pm:Nameplate/amount.
SELECT c.filing, c.layer, c.unit, c.denominator AS period
FROM      (
    SELECT * FROM claims
) c
WHERE c.owns = 'pm:nameplate/pm:amount'
  AND c.denominator_kind = 'period'

),
jagged_layer AS MATERIALIZED (
    -- asrt:Fusion/asrt:Part against itself; conformance rule "a fusion's parts partition what they compose".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT f.filing, f.layer,
           j.filing IS NOT NULL AS violates,
           CASE WHEN j.filing IS NULL
                THEN format('`%s` draws each part once', f.layer)
                ELSE format('`%s/%s` arrives through `%s/%s` and through `%s/%s`',
                            j.doubled_filing, j.doubled_layer,
                            j.via_filing, j.via_layer, j.also_via_filing, j.also_via_layer)
           END AS detail
    FROM      (
        SELECT * FROM fusions
    ) f
    LEFT JOIN (
        SELECT * FROM jagged_layers
    ) j ON j.filing = f.filing AND j.layer = f.layer
) p ON true
WHERE r.slug = 'jagged_layer'

),
unresolved_part AS MATERIALIZED (
    -- asrt:Part/pm:ForeignId against pm.filing_identity and pm.layer.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT a.composition AS filing, a.composed_layer AS layer,
           r.composition IS NULL AS violates,
           format('%s / %s resolves to nothing', a.part_filing, a.part_layer) AS detail
    FROM      (
        SELECT * FROM part_references
    ) a
    LEFT JOIN (
        SELECT * FROM parts
    ) r
           ON r.composition    = a.composition
          AND r.composed_layer = a.composed_layer
          AND r.part_notation  = a.part_filing
          AND r.part_layer     = a.part_layer
) p ON true
WHERE r.slug = 'unresolved_part'

),
checks_all AS MATERIALIZED (
    -- the conformance rules XSD 1.0 cannot reach, one file each; checks/roster.sqlc is the list.
-- pm:Remainder/sign against pm:Demand and pm:Nameplate; conformance rule "sign agrees".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT s.filing, s.layer,
           s.sign IS DISTINCT FROM s.derived_fit::pm.fit AS violates,
           format('filed %s, ranges say %s', s.sign, s.derived_fit) AS detail
    FROM (
        SELECT * FROM signed
    ) s
) p ON true
WHERE r.slug = 'fit_disagrees'
UNION ALL
-- pm:Remainder/pm:holder summed against |r| from layers/remainder.sqlc, via entries/holder_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
            SELECT * FROM remainder
        ) r
        JOIN      (
            SELECT * FROM holder_totals
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
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           abs(l.qty_low  - l.m_low)  > 1e-9
           OR abs(l.qty_mode - l.m_mode) > 1e-9
           OR abs(l.qty_high - l.m_high) > 1e-9                           AS violates,
           format('stated [%s, %s, %s] against a magnitude of [%s, %s, %s]',
                  l.qty_low, l.qty_mode, l.qty_high, l.m_low, l.m_mode, l.m_high) AS detail
    FROM (
        SELECT * FROM filed_against_derived
    ) l
    WHERE l.qty_low IS NOT NULL
      AND l.qty_unit = l.unit
) p ON true
WHERE r.slug = 'stated_quantity_is_not_the_magnitude'
UNION ALL
-- every slack on the layer accounted for and empty, against pm:HolderKind of every holder.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
            SELECT * FROM unabsorbed_exposure
        ) e
        WHERE e.exposure > 1e-9
    ) c
    LEFT JOIN ( SELECT DISTINCT filing, layer
                FROM (
                    SELECT * FROM unserved_holders
                ) h ) u USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM served_totals
    ) s USING (filing, layer)
) p ON true
WHERE r.slug = 'nobody_named_as_unserved'
UNION ALL
-- every slack on the layer accounted for and empty, against entries/unserved_totals.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT e.filing, e.layer,
           e.exposure > e.unserved + 1e-9 AS violates,
           format('exposure %s, absorbable %s, unserved %s',
                  e.exposure, e.absorbable, e.unserved) AS detail
    FROM (
        SELECT x.filing, x.layer, x.exposure, x.absorbable, u.unserved_high AS unserved
        FROM      (
            SELECT * FROM unabsorbed_exposure
        ) x
        JOIN      (
            SELECT * FROM unserved_totals
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
    SELECT * FROM checks_roster
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
        SELECT * FROM pressed
    ) p
    JOIN      (
        SELECT * FROM absorber
    ) a USING (filing, layer)
    JOIN      (
        SELECT * FROM served_totals
    ) h USING (filing, layer)
    WHERE p.sign = 'interference'
) b
JOIN (
    SELECT * FROM slacks
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
    SELECT * FROM checks_roster
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
    SELECT * FROM absorbing_slack
) s
JOIN      (
    SELECT * FROM holders
) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL

    ) c
) p ON true
WHERE r.slug = 'slack_unit_mismatch'
UNION ALL
-- pm:LumpyQuantum/size unit against pm:Nameplate/amount unit.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           l.quantum_unit IS DISTINCT FROM l.amount_unit AS violates,
           format('quantum in %s, nameplate in %s', l.quantum_unit, l.amount_unit) AS detail
    FROM (
        SELECT * FROM lumpy
    ) l
    WHERE l.quantum_low IS NOT NULL
) p ON true
WHERE r.slug = 'quantum_unit_mismatch'
UNION ALL
-- pm:Nameplate/amount against pm:LumpyQuantum/size.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
    SELECT * FROM lumpy
) l
WHERE l.quantum_mode > 0

    ) d
) p ON true
WHERE r.slug = 'nameplate_not_a_multiple'
UNION ALL
-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount plus pm:Nameplate/pm:capacitySlack.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
        SELECT * FROM drawn
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
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT r.filing, r.layer,
           u.kind IS NOT NULL AS violates,
           format('%s holder under a clearance fit', h.kind) AS detail
    FROM      (
        SELECT * FROM remainder
    ) r
    JOIN      (
        SELECT * FROM holders
    ) h USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM unserved_holders
    ) u USING (filing, layer, kind)
    WHERE r.sign = 'clearance'
) p ON true
WHERE r.slug = 'clearance_with_unserved'
UNION ALL
SELECT * FROM unresolved_part
UNION ALL
SELECT * FROM jagged_layer
UNION ALL
-- composition/descent.sqlc intersected with its converse; conformance rule "layers that always move together are one layer".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
        SELECT * FROM fusions
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
        SELECT * FROM descent
    ) a
    JOIN      (
        SELECT * FROM descent
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
    SELECT * FROM checks_roster
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
        SELECT * FROM couplings
    ) up
    JOIN      (
        SELECT * FROM parts
    ) pf
           ON pf.composition = up.filing AND pf.composed_layer = up.from_layer
    JOIN      (
        SELECT * FROM couplings
    ) lo
           ON lo.filing = pf.part_filing AND lo.from_layer = pf.part_layer
    JOIN      (
        SELECT * FROM parts
    ) pt
           ON pt.composition = up.filing AND pt.composed_layer = up.to_layer
          AND pt.part_layer = lo.to_layer
    JOIN      (
        SELECT * FROM layers_nameplate
    ) pn
           ON pn.filing = pf.part_filing AND pn.layer = pf.part_layer
    JOIN      (
        SELECT * FROM layers_nameplate
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
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.narrows_absent IS DISTINCT FROM 'notApplicable' AS violates,
           format('%s claim %s: %s exactly, and it still answers %s', c.owns, c.seq, c.mode,
                  coalesce(c.narrows_kind::text, 'absent: ' || c.narrows_absent)) AS detail
    FROM (
        SELECT * FROM point_claims
    ) c
) p ON true
WHERE r.slug = 'narrows_a_point_value'
UNION ALL
-- pm:Claim/pm:narrowsWhen with pm:absent/reason = notApplicable on any claim where low <> high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
    SELECT * FROM claims
) c
WHERE NOT c.is_a_point

    ) c
) p ON true
WHERE r.slug = 'range_says_no_range'
UNION ALL
-- pm:Claim/pm:boundOrigin with pm:absent/reason = none on a claim where low = high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.origin_absent IS NOT DISTINCT FROM 'none' AS violates,
           format('%s claim %s: %s %s exactly, and nothing is said to set it',
                  c.owns, c.seq, c.mode, c.unit) AS detail
    FROM (
        SELECT * FROM point_claims
    ) c
) p ON true
WHERE r.slug = 'bound_fell_with_no_range'
UNION ALL
-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking pm:derivation, against the identity that computes the claim.
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
        SELECT * FROM claim_derivations
    ) c
    LEFT JOIN (
        SELECT * FROM identities_roster
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
    SELECT * FROM checks_roster
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
    SELECT * FROM parts
) p
JOIN      (
    SELECT * FROM windows
) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    SELECT * FROM windows
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
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           lic.filing IS NULL AS violates,
           format('timeSlack is the `clearance` and the window is %s',
                  coalesce(d.window_absent::text,
                           format('%s %s', d.window_low, d.window_unit))) AS detail
    FROM      (
        SELECT * FROM derived_time_slacks
    ) d
    LEFT JOIN (
        -- pm:Divisibility/window: absent notApplicable, or filed as one whole period.
SELECT w.filing, w.layer,
       CASE WHEN w.window_absent IS NOT NULL THEN 'the question has no denominator'
            ELSE 'it runs the whole period' END AS licensed_because
FROM (
    SELECT * FROM windows
) w
WHERE w.window_absent = 'notApplicable'
   OR (w.window_low = 1 AND w.window_low = w.window_high
       AND EXISTS (
           SELECT 1
           FROM (
               SELECT * FROM with_a_period
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
    SELECT * FROM checks_roster
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
        SELECT * FROM windows
    ) w
    LEFT JOIN (
        SELECT * FROM with_a_period
    ) r USING (filing, layer)
    WHERE w.window_absent = 'notApplicable'
      AND w.amount_unit IS NOT NULL
) p ON true
WHERE r.slug = 'window_not_applicable_on_a_rate'
UNION ALL
-- pm:Divisibility/pm:window/pm:quantum/pm:size with pm:absent/pm:reason = notApplicable.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT w.filing, w.layer,
           w.window_size_absent IS NOT DISTINCT FROM 'notApplicable' AS violates,
           CASE WHEN w.window_size_absent IS NOT NULL
                THEN format('the window is filed as a quantum and its size as %s', w.window_size_absent)
                ELSE format('the window is filed as %s %s', w.window_low, w.window_unit)
           END AS detail
    FROM (
        SELECT * FROM windows
    ) w
    WHERE w.window_low IS NOT NULL OR w.window_size_absent IS NOT NULL
) p ON true
WHERE r.slug = 'window_size_not_applicable'
UNION ALL
-- asrt:eliminations with pm:absent/reason = notApplicable, counted over asrt:Part.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT m.composition AS filing, m.composed_layer AS layer,
           m.parts > 1 AS violates,
           format('%s parts and the search is `notApplicable`', m.parts) AS detail
    FROM (
        -- eliminations/searched.sqlc answering "notApplicable", beside folds/fusion_parts.sqlc.
SELECT es.composition, es.composed_layer, f.parts
FROM (
    SELECT * FROM searched
) es
JOIN (
    SELECT * FROM fusion_parts
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
        SELECT * FROM fused
    ) f
    GROUP BY f.composition, f.composed_layer
) p ON true
WHERE r.slug = 'fusion_sum_disagrees'
UNION ALL
-- asrt:Part whose pm:ForeignId/notation is its own composition's, against pm.layer.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT p.composition AS filing, p.composed_layer AS layer,
           l.layer IS NULL AS violates,
           format('local part `%s` is not a layer of this filing', p.part_layer) AS detail
    FROM      (
        -- pm.part where pm:ForeignId/notation equals the composition's own pm:notation.
SELECT p.*
FROM      (
    SELECT * FROM part_references
) p
JOIN      (
    SELECT * FROM notations
) fi ON fi.filing = p.composition AND fi.notation = p.part_filing

    ) p
    LEFT JOIN (
        SELECT * FROM every_layer
    ) l ON l.filing = p.composition AND l.layer = p.part_layer
) p ON true
WHERE r.slug = 'local_part_dangles'
UNION ALL
-- pm:StatedRemainder's absent branch against the layer's own pm:Demand and pm:Nameplate, from layers/figures.sqlc.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
        SELECT * FROM denied_remainders
    ) d
    LEFT JOIN (
        SELECT * FROM figures
    ) f USING (filing, layer)
) p ON true
WHERE r.slug = 'denied_remainder_is_not_contradicted'
UNION ALL
-- composition/carried.sqlc: the part's figure against the composed layer's, per quantity.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
        SELECT * FROM carried
    ) c
) p ON true
WHERE r.slug = 'one_part_fusion_alters_its_part'
UNION ALL
-- units/conversions.sqlc walked until a unit repeats; the product against one.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    WITH RECURSIVE e AS (
        SELECT * FROM conversions
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
    SELECT * FROM checks_roster
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
            SELECT * FROM part_quantities
        ) p
        WHERE p.part_unit IS DISTINCT FROM p.composed_unit
    ) x
) p ON true
WHERE r.slug = 'unit_crossing_without_a_factor'
UNION ALL
-- composition/regime_crossings.sqlc; conformance rule "a part crossing a regime boundary files what reconciles it".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
    SELECT * FROM part_regimes
) x
LEFT JOIN (
    SELECT r.filing,
           count(*) FILTER (WHERE r.framework_value IS NOT NULL) AS states,
           min(r.framework_taxonomy) AS framework_taxonomy,
           min(r.framework_value)    AS framework_value
    FROM (
        SELECT * FROM regimes
    ) r
    GROUP BY r.filing
) own ON own.filing = x.composition
LEFT JOIN (
    SELECT * FROM citations
) c ON c.composition = x.composition

    ) x
    WHERE x.crossing_known
) p ON true
WHERE r.slug = 'regime_crossing_without_a_citation'
UNION ALL
-- composition/part_regimes.sqlc; conformance rule "a composer's regime for a part is one that part's own filing declares".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks_roster
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
        SELECT * FROM part_regimes
    ) x
    WHERE x.composer_absent IS NULL
      AND x.frameworks_the_filing_states > 0
) p ON true
WHERE r.slug = 'part_regime_disagrees'


)
SELECT r.slug,
       r.subject                                     AS declares,
       count(c.rule)                                 AS rows,
       count(DISTINCT (c.filing, c.layer))           AS layers,
       count(DISTINCT (c.filing, c.layer, c.detail)) AS sentences,
       r.subject = 'layer'
         AND count(c.rule) <> count(DISTINCT (c.filing, c.layer)) AS finer_than_declared,
       count(c.rule) FILTER (WHERE c.layer IS NOT NULL AND l.layer IS NULL) AS unresolvable
FROM      (
    SELECT * FROM checks_roster
) r
LEFT JOIN (
    SELECT * FROM checks_all
) c ON c.rule = r.rule
LEFT JOIN (
    SELECT * FROM every_layer
) l ON l.filing = c.filing AND l.layer = c.layer
GROUP BY r.slug, r.subject
