-- §1  Every law this tree claims, and whether it holds.
-- algebra/all.sqlc, as the example reads it.
WITH
algebra_roster AS MATERIALIZED (
    -- the set-algebraic laws this tree's relations claim to obey.
SELECT * FROM (VALUES
  ('decomposition',    '|E| = Σ_filing |E_filing|',  'rank/decomposition',               'partition',  'bag: one edge counted in both scopes'),
  ('compose_decomposition','|N| = Σ_dir |N_dir|, |E| = Σ_dir |E_dir| + crossing', 'rank/compose_decomposition', 'partition', 'set: a template is in exactly one directory'),
  ('cycle_space',      'dim ker B = 0 ⟺ |jagged| = 0','rank/cycle_space',                 'value',      'set: one row, the layer graph against its rule'),
  ('composition_kernel','dim ker F Φ = m − |fusions|','rank/composition_kernel',        'value',      'set: one row, the fusion fold against the layer graph'),
  ('composition_row_space','dim row ⊕ dim ker = parts, per fibre; Σ dim row = rank', 'rank/composition_row_space', 'value', 'set: one row per fusion, folded to two subjects'),
  ('composition_image', '|declared| = rank + dim ker (F Φ)ᵀ, and the left null is empty', 'rank/composition_image', 'value', 'set: one row per composition'),
  ('composition_closure','dim ker Ψ = Σ dim ker over the levels = |leaves| − 1, and Ψ''s own row is positive', 'rank/composition_closure', 'value', 'set: one row per fusion taken as a root'),
  ('dimension_use',    'parents(dimension) ⊆ declared', 'algebra/dimension_use',         'roster',     'set: one row per undeclared parent'),
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('jagged_layers',    '|A| = |A∖B| + |A⋉B|',        'queries/observations/14-jagged-layers','difference','bag: one row per doubled layer'),
  ('composed_quantities','|A| = |A∖B| + |A⋉B|',      'queries/matrices/3b-composed-quantities','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('carried',          '|A| = |A∖B| + |A⋉B|',        'composition/carried',              'difference', 'bag: anti-join preserves it'),
  ('owed_remainder',   '|A| = |A∖B| + |A⋉B|',        'composition/owed_remainder',       'difference', 'set'),
  ('settled_remainders','|A| = |A∖B| + |A⋉B|',       'composition/settled_remainders',   'difference', 'bag: one row per path'),
  ('unresolved_parts', '|A| = |A∖B| + |A⋉B|',        'composition/unresolved_parts',     'difference', 'set: pm.part''s key'),
  ('remainder_in_force','|A| = |A∖B| + |A⋉B|',       'layers/remainder',                 'difference', 'set: one row per layer'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('exposure_standing', 'each exposed layer in exactly one standing','layers/exposure_scope','partition','set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL'),
  ('part_regimes',     '|A| = |A∖B| + |A⋉B|',        'checks/part_regime_disagrees',     'difference', 'set: pm.part''s key'),
  ('crossed_remainder','r = [n_low − d_high, n_mode − d_mode, n_high − d_low]', 'layers/remainder', 'value', 'set: one row per remainder'),
  ('exposure',         'exposure = max(−r_low, 0)',  'layers/remainder',                 'value',      'set: one row per remainder'),
  ('remainder_decomposes','r = m·q − (d mod q)',     'layers/decomposed',                'value',      'set: one row per lumpy remainder'),
  ('sawtooth',         'one tooth ⇒ residues ordered', 'layers/decomposed',              'value',      'set: one row per demand inside one tooth'),
  ('composed_quantum', 'g divides the composed nameplate', 'composition/composed_quantum', 'value',     'set: one row per composed layer with a quantum'),
  ('fusion_sum',       'x_composed = F Φ x_parts − e, per quantity', 'composition/fused',   'value',      'set: one row per owed fusion quantity'),
  ('composed_remainder','r = F Φ r_parts − e_n + e_d, inside n − d', 'composition/fused_remainders', 'value', 'set: one row per owed composed remainder'),
  ('derived_quantities','x_derived = F Φ x_parts − e, one level at a time', 'composition/derived_quantities', 'value', 'set: one row per figure filed as its fusion''s sum'),
  ('conforms',         'no loaded document violates a rule', 'checks/all',               'conformance', 'set: one row per rule'),
  ('fit_domain',       'axis ⇔ closure reaches the fit; exercised ⇔ examined > 0', 'reports/fit_coverage', 'roster', 'set: one row per rule'),
  ('absences_filed',   'census(columns) = census(elements), per filing, group and reason', 'epistemics/absences', 'roster', 'set: one row per group of positions'),
  ('derivations_filed', 'census(columns) = census(elements), per filing, position and identity', 'epistemics/derivations', 'roster', 'set: one row per position'),
  ('fusions_have_parts', 'parts → fusions is onto: no fusion names no part; Σ parts = |references|', 'folds/fusion_parts', 'partition', 'set: one row per composition'),
  ('searches_answered', 'each search: entries filed ⇔ no reason typed', 'epistemics/searches', 'partition', 'set: one row per search'),
  ('subject_boxes',    'rows = Σ boxes per subject; Σ rows = |population|', 'folds/contract_subjects', 'partition', 'bag: a population counted into its subjects'),
  ('factor_state',     'each part in the factor state its columns file', 'composition/part_references', 'partition', 'set: pm.part''s key'),
  ('fusion_quantities', '|A| = |A∖B| + |A⋉B|',       'composition/fusion_quantities',    'difference', 'set: one row per layer and quantity'),
  ('part_sums',        'Σ over fusions of Σ parts = Σ parts', 'folds/part_sums',           'additive',   'bag: every part counted'),
  ('suspended_quantities', '|A| = |A∖B| + |A⋉B|',   'composition/suspended_quantities', 'difference', 'set: one row per fusion and quantity'),
  ('unsized_conversions_are_unsettled', 'π(A) ⊆ B: a conversion nobody could size cannot be differenced', 'composition/unsized_conversions', 'containment', 'set: one row per composed layer'),
  ('part_quantities',  '|A| = |A∖B| + |A⋉B|',        'composition/part_quantities',      'difference', 'set: one row per part and quantity'),
  ('figures',          '|D ∪ N| = |D| + |N| − |D ∩ N|', 'layers/figures',                  'union',      'set: one row per layer'),
  ('served_totals',    'Σheld = Σserved + Σunserved, per layer', 'folds/served_totals',     'additive',   'bag: γ over holders'),
  ('layer_units',      'a pin is the whole relation: the payload constant on the key, the pinned value reaching it', 'units/conversions', 'dependency', 'set: one row per condition')
) AS a(slug, law, governs, form, multiplicity)

),
arithmetic_roster AS MATERIALIZED (
    -- the arithmetic the schemas' prose owes, against the unit rules that exist to make it mean anything.
SELECT * FROM (VALUES
  ('remainder',          'r = n - d',                    'demand x nameplate',              NULL),
  ('shares_sum',         'sum of shares = |r|',          'holder shares x remainder',       NULL),
  ('shares_bounded',     'sum of shares <= S',           'holder shares x absorbing slack', 'slack_unit_mismatch'),
  ('whole_multiple',     'n mod q = 0',                  'nameplate x quantum',             'quantum_unit_mismatch'),
  ('draw_bounded',       'draw <= n + capacity slack',   'draw x nameplate x slack',        NULL),
  ('exposure_bounded',   'exposure <= unserved shares',  'remainder x unserved shares',     NULL),
  ('time_slack_derived', 'time slack = max(n - d, 0)',   'demand x nameplate',              NULL),
  ('filed_remainder',    'filed r = n - d',              'remainder quantity x remainder',  NULL),
  ('fusion_sum',         'x_composed = F.Phi.x - e',     'parts x factors x elimination',   '(forbidden)')
) AS a(slug, site, operands, guarded_by)

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
derived_fusions AS MATERIALIZED (
    -- composition/fusion_quantities.sqlc filed as a derivation.
SELECT q.filing, q.layer, q.quantity
FROM (
    SELECT * FROM fusion_quantities
) q
WHERE q.derivation IS NOT NULL

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
slacks AS MATERIALIZED (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s

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
unabsorbed_exposure AS MATERIALIZED (
    -- layers/exposure_scope.sqlc, restricted to the standing that licenses a conclusion.
SELECT s.*
FROM (
    SELECT * FROM exposure_scope
) s
WHERE s.standing = 'every buffer sized and empty'

),
arithmetic_all AS MATERIALIZED (
    -- arithmetic/roster.sqlc joined to each site's own population.
-- composition/resolved_quantities.sqlc's demand against its nameplate, before layers/remainder.sqlc drops either,
-- with composition/figureless_remainders.sqlc for a layer whose n - d is not its remainder.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.low IS NULL OR n.low IS NULL   THEN 'suspended'::public.arithmetic_verdict
                WHEN d.unit IS DISTINCT FROM n.unit   THEN 'not comparable'::public.arithmetic_verdict
                WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.low IS NULL AND n.low IS NULL
                     THEN format('demand %s and nameplate %s', d.why, n.why)
                WHEN d.low IS NULL THEN format('demand %s', d.why)
                WHEN n.low IS NULL THEN format('nameplate %s', n.why)
                WHEN d.unit IS DISTINCT FROM n.unit
                     THEN format('%s against %s', d.unit, n.unit)
                WHEN g.filing IS NOT NULL
                     THEN 'a conversion with width scales both totals, and the composed remainder is lifted'
                ELSE format('both in %s', d.unit) END AS detail
    FROM      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM resolved_quantities ) q
    ) d
    JOIN      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM resolved_quantities ) q
    ) n ON n.filing = d.filing AND n.layer = d.layer AND n.quantity = 'nameplate'
    LEFT JOIN (
        SELECT * FROM figureless_remainders
    ) g ON g.filing = d.filing AND g.layer = d.layer
    WHERE d.quantity = 'demand'
) p ON true
WHERE a.slug = 'remainder'
UNION ALL
-- pm:Remainder/pm:holder against the layer the magnitude belongs to.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT r.filing, r.layer,
           CASE WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[r.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('%s holders, %s unstated%s', h.holders, h.unstated,
                  CASE WHEN h.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', h.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM remainder
    ) r
    JOIN      (
        SELECT * FROM holder_totals
    ) h USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_sum'
UNION ALL
-- the slack named by pm:Remainder/pm:absorber, against the served pm:Remainder/pm:holder under interference.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT s.filing, s.layer,
           CASE WHEN s.mode IS NULL                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[s.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN s.mode IS NULL
                     THEN format('the %s buffer is %s', s.buffer, s.absent)
                WHEN h.unstated > 0
                     THEN format('%s of %s shares unstated%s, against a %s slack of %s',
                                 h.unstated, h.holders,
                                 CASE WHEN h.derived > 0
                                      THEN format(' (%s of them filed as `sharesSum`''s output, which nothing here computes)', h.derived)
                                      ELSE '' END,
                                 s.buffer, s.mode)
                ELSE format('%s shares bounded by a %s slack of %s',
                            h.holders, s.buffer, s.mode)
           END AS detail
    FROM      (
        SELECT * FROM absorbing_slack
    ) s
    JOIN      (
        SELECT * FROM served_totals
    ) h USING (filing, layer)
    JOIN      (
        SELECT DISTINCT r.filing, r.layer
        FROM (
            SELECT * FROM pressed
        ) r
        WHERE r.sign = 'interference'
    ) x USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_bounded'
UNION ALL
-- pm:Divisibility/pm:quantum against pm:Nameplate/pm:amount.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.quantum_mode IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN l.quantum_unit IS DISTINCT FROM l.amount_unit     THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.quantum_mode IS NULL THEN format('quantum %s', l.quantum_absent)
                ELSE format('%s of %s against a rating in %s',
                            l.quantum_mode, l.quantum_unit, l.amount_unit) END AS detail
    FROM (
        SELECT * FROM lumpy
    ) l
) p ON true
WHERE a.slug = 'whole_multiple'
UNION ALL
-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.capacity_slack IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit       THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.capacity_slack IS NULL
                     THEN format('the capacity buffer is %s', d.capacity_absent)
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit
                     THEN format('a draw in %s against a rating in %s and a slack in %s',
                                 d.draw_unit, d.n_unit, d.capacity_unit)
                ELSE format('draw, rating and slack all in %s', d.n_unit) END AS detail
    FROM (
        SELECT * FROM drawn
    ) d
) p ON true
WHERE a.slug = 'draw_bounded'
UNION ALL
-- every slack on the layer accounted for and empty, against pm:Remainder/pm:holder of kind customer and unrealised.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT x.filing, x.layer,
           CASE WHEN u.unstated > 0                        THEN 'suspended'::public.arithmetic_verdict
                WHEN u.share_units <> ARRAY[x.unit]        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('exposure %s in %s against %s unserved holder(s)%s',
                  round(x.exposure, 3), x.unit, u.holders,
                  CASE WHEN u.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', u.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM unabsorbed_exposure
    ) x
    JOIN      (
        SELECT * FROM unserved_totals
    ) u USING (filing, layer)
) p ON true
WHERE a.slug = 'exposure_bounded'
UNION ALL
-- pm:Layer/pm:timeSlack with pm:absent/reason = derived, against the clearance it stands for.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT t.filing, t.layer,
           CASE WHEN r.filing IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN r.unit IS DISTINCT FROM r.amount_unit        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN r.filing IS NULL THEN 'no demand and nameplate to take a clearance from'
                WHEN r.unit IS DISTINCT FROM r.amount_unit
                     THEN format('a demand in %s against a nameplate in %s', r.unit, r.amount_unit)
                ELSE format('the clearance [%s, %s, %s] %s is the slack',
                            greatest(r.r_low, 0), greatest(r.r_mode, 0), greatest(r.r_high, 0),
                            r.unit) END AS detail
    FROM      (
        SELECT * FROM derived_time_slacks
    ) t
    LEFT JOIN (
        SELECT * FROM remainder
    ) r USING (filing, layer)
) p ON true
WHERE a.slug = 'time_slack_derived'
UNION ALL
-- pm:Remainder/pm:quantity against the layer's own r = n - d.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.qty_low IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN l.qty_unit IS DISTINCT FROM l.unit      THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.qty_low IS NULL THEN format('the quantity is %s', l.qty_absent)
                ELSE format('filed %s %s against a derived magnitude %s %s',
                            l.qty_mode, l.qty_unit, round(l.m_mode, 3), l.unit) END AS detail
    FROM      (
        SELECT * FROM filed_against_derived
    ) l
) p ON true
WHERE a.slug = 'filed_remainder'
UNION ALL
-- asrt:Fusion/asrt:Part against asrt:eliminations, via composition/owed_equality.sqlc and composition/derived_quantities.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic_roster
) a
LEFT JOIN (
    SELECT f.filing, f.layer,
           CASE WHEN o.owed IS NULL AND d.computed IS NOT TRUE
                THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           concat_ws('; ',
                     CASE WHEN o.owed IS NOT NULL THEN format('owed exactly for %s', o.owed) END,
                     d.derived,
                     s.suspended) AS detail
    FROM      (
        SELECT * FROM fusions
    ) f
    LEFT JOIN (
        SELECT o.filing, o.layer, string_agg(o.quantity::text, ', ' ORDER BY o.quantity) AS owed
        FROM (
            SELECT * FROM owed_equality
        ) o
        GROUP BY o.filing, o.layer
    ) o USING (filing, layer)
    LEFT JOIN (
        SELECT g.composition, g.composed_layer,
               string_agg(DISTINCT format('suspended for %s: %s',
                                          coalesce(g.quantity::text, 'every quantity'),
                                          g.suspended_because), '; ') AS suspended
        FROM (
            SELECT * FROM suspension_grounds
        ) g
        GROUP BY g.composition, g.composed_layer
    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
    LEFT JOIN (
        SELECT d.filing, d.layer, bool_or(q.low IS NOT NULL) AS computed,
               string_agg(CASE WHEN q.low IS NOT NULL
                               THEN format('derived for %s: computed [%s, %s, %s]', d.quantity,
                                           q.low, q.mode, q.high)
                               ELSE format('derived for %s, not computable: %s', d.quantity,
                                           q.blocked_because) END,
                          '; ' ORDER BY d.quantity) AS derived
        FROM      (
            SELECT * FROM derived_fusions
        ) d
        JOIN      (
            SELECT * FROM derived_quantities
        ) q ON q.filing = d.filing AND q.layer = d.layer AND q.quantity = d.quantity
        GROUP BY d.filing, d.layer
    ) d ON d.filing = f.filing AND d.layer = f.layer
) p ON true
WHERE a.slug = 'fusion_sum'


),
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
composition_citations AS MATERIALIZED (
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
couplings AS MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

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
every_layer AS MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

),
signed AS MATERIALIZED (
    -- pm:Remainder/sign, stated rather than absent.
SELECT r.*
FROM (
    SELECT * FROM remainder
) r
WHERE r.sign IS NOT NULL

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
    SELECT * FROM composition_citations
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


),
fit_axes AS MATERIALIZED (
    -- the fit axis each rule on checks/roster.sqlc reads, declared.
SELECT * FROM (VALUES
  ('fit_disagrees',                        'filed against derived'::public.fit_axis),
  ('shares_do_not_sum',                    'derived fit'),
  ('stated_quantity_is_not_the_magnitude', 'derived fit'),
  ('nobody_named_as_unserved',             'derived fit'),
  ('exposure_unaccounted',                 'derived fit'),
  ('share_exceeds_slack',                  'filed sign'),
  ('slack_unit_mismatch',                  'not read'),
  ('quantum_unit_mismatch',                'not read'),
  ('nameplate_not_a_multiple',             'not read'),
  ('draw_exceeds_the_supply',              'not read'),
  ('clearance_with_unserved',              'filed sign'),
  ('unresolved_part',                      'not read'),
  ('jagged_layer',                         'not read'),
  ('layers_move_together',                 'not read'),
  ('coupling_does_not_attenuate',          'not read'),
  ('narrows_a_point_value',                'not read'),
  ('range_says_no_range',                  'not read'),
  ('bound_fell_with_no_range',             'not read'),
  ('identity_does_not_compute_the_claim',  'not read'),
  ('window_lost_or_summed',                'not read'),
  ('derived_slack_over_a_window',          'not read'),
  ('window_not_applicable_on_a_rate',      'not read'),
  ('window_size_not_applicable',           'not read'),
  ('elimination_not_applicable_with_parts','not read'),
  ('fusion_sum_disagrees',                 'not read'),
  ('local_part_dangles',                   'not read'),
  ('unit_crossing_without_a_factor',       'not read'),
  ('regime_crossing_without_a_citation',   'not read'),
  ('part_regime_disagrees',                'not read'),
  ('conversion_cycle_does_not_close',      'not read'),
  ('one_part_fusion_alters_its_part',      'not read'),
  ('denied_remainder_is_not_contradicted', 'not read')
) AS a(slug, axis)

),
fit_domain AS MATERIALIZED (
    -- the declared standing of each rule on checks/fit_axes.sqlc in each cell of its axis.
SELECT * FROM (VALUES
  ('fit_disagrees', 'clearance'::pm.fit, 'exercised'::public.fit_standing, NULL::text),
  ('fit_disagrees', 'transition',   'exercised', NULL),
  ('fit_disagrees', 'interference', 'exercised', NULL),
  ('fit_disagrees', NULL,           'outside',
   'layers/signed.sqlc reads layers/remainder.sqlc, which needs a demand and a nameplate to derive the fit a filed sign is compared with'),

  ('shares_do_not_sum', 'clearance',    'exercised', NULL),
  ('shares_do_not_sum', 'transition',   'open',
   'a transition whose shares sum to the magnitude of its larger side is a legitimate filing; nothing loaded states shares on a transition'),
  ('shares_do_not_sum', 'interference', 'exercised', NULL),
  ('shares_do_not_sum', NULL,           'outside',
   'the magnitude the shares sum to comes from layers/remainder.sqlc, which needs a demand and a nameplate'),

  ('stated_quantity_is_not_the_magnitude', 'clearance',    'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'transition',   'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'interference', 'open',
   'a remainder under interference may state its quantity; nothing loaded does'),
  ('stated_quantity_is_not_the_magnitude', NULL,           'outside',
   'layers/filed_against_derived.sqlc compares against the magnitude layers/remainder.sqlc derives from a demand and a nameplate'),

  ('nobody_named_as_unserved', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none: nothing went unserved'),
  ('nobody_named_as_unserved', 'transition',   'exercised', NULL),
  ('nobody_named_as_unserved', 'interference', 'exercised', NULL),
  ('nobody_named_as_unserved', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('exposure_unaccounted', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none'),
  ('exposure_unaccounted', 'transition',   'open',
   'refutation/compute reaches it with every buffer empty, and the rule suspends because its unserved share is unmeasured; a transition stating every unserved share would be examined'),
  ('exposure_unaccounted', 'interference', 'exercised', NULL),
  ('exposure_unaccounted', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('share_exceeds_slack', 'clearance',    'outside',
   'layers/pressed.sqlc keeps a filed interference or transition'),
  ('share_exceeds_slack', 'transition',   'outside',
   'entries/borne.sqlc keeps interference alone: under a transition the shares and the slack bound opposite edges of one buffer'),
  ('share_exceeds_slack', 'interference', 'open',
   'a served share under interference, every served share stated, whose absorbing buffer states its slack; every such layer loaded leaves that slack unsized'),
  ('share_exceeds_slack', NULL,           'outside',
   'layers/pressed.sqlc keeps a filed sign'),

  ('clearance_with_unserved', 'clearance',    'exercised', NULL),
  ('clearance_with_unserved', 'transition',   'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', 'interference', 'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', NULL,           'outside',
   'its population is a filed clearance')
) AS d(slug, fit, standing, reason)

),
composed_quantum AS MATERIALIZED (
    -- composition/parts.sqlc against layers/lumpy.sqlc, converted by asrt:factor and folded by gcd, over every part in composition/part_references.sqlc.
WITH RECURSIVE base AS (
    SELECT p.composition, p.composed_layer,
           CASE WHEN p.factor_state = 'stated' THEN c.n_unit ELSE l.quantum_unit END AS quantum_unit,
           CASE WHEN p.factor_state IN ('omitted', 'stated')
                THEN l.quantum_mode * coalesce(p.factor_mode, 1) END             AS quantum_mode,
           coalesce(p.factor_low <> p.factor_high, false)                         AS spread,
           p.factor_absent, p.factor_derivation
    FROM      (
        SELECT * FROM parts
    ) p
    JOIN      (
        SELECT * FROM lumpy
    ) l ON l.filing = p.part_filing AND l.layer = p.part_layer
    LEFT JOIN (
        SELECT * FROM layers_nameplate
    ) c ON c.filing = p.composition AND c.layer = p.composed_layer
    WHERE l.quantum_mode > 0
),
every_part AS (
    SELECT p.composition, p.composed_layer, p.parts
    FROM (
        SELECT * FROM fusion_parts
    ) p
),
shape AS (
    SELECT composition, composed_layer,
           count(*)                                         AS lumpy_parts,
           count(quantum_mode)                              AS sized,
           count(DISTINCT quantum_unit)                     AS units,
           min(quantum_unit)                                AS unit,
           bool_or(spread)                                  AS spread,
           min(factor_absent)                               AS unsized,
           min(factor_derivation)                           AS unsized_by
    FROM base GROUP BY composition, composed_layer
),
ordered AS (
    SELECT b.*, row_number() OVER (PARTITION BY b.composition, b.composed_layer
                                   ORDER BY b.quantum_unit, b.quantum_mode) AS i
    FROM base b
    WHERE b.quantum_mode IS NOT NULL
),
fold AS (
    SELECT composition, composed_layer, i, quantum_mode AS g FROM ordered WHERE i = 1
  UNION ALL
    SELECT o.composition, o.composed_layer, o.i, gcd(f.g, o.quantum_mode)
    FROM fold f
    JOIN ordered o ON o.composition    = f.composition
                  AND o.composed_layer = f.composed_layer
                  AND o.i              = f.i + 1
)
SELECT s.composition, s.composed_layer, e.parts, s.units, s.spread,
       CASE WHEN s.unsized IS NULL AND s.unsized_by IS NULL AND s.units = 1 THEN s.unit END
           AS unit,
       CASE WHEN s.unsized IS NULL AND s.unsized_by IS NULL AND s.units = 1 THEN f.g END
           AS composed_quantum,
       CASE WHEN s.unsized IS NOT NULL THEN s.unsized
            WHEN s.unsized_by IS NULL AND s.units > 1 THEN 'notApplicable'::pm.absence_reason END
           AS absent,
       s.unsized_by AS factor_derivation
FROM      shape      s
JOIN      every_part e ON e.composition = s.composition
                      AND e.composed_layer = s.composed_layer
                      AND e.parts = s.lumpy_parts
LEFT JOIN fold       f ON f.composition = s.composition
                      AND f.composed_layer = s.composed_layer
                      AND f.i = s.sized

),
calls AS MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
catalogue AS MATERIALIZED (
    -- information_schema.tables restricted to the schema this model owns.
SELECT t.table_name::text AS object
FROM information_schema.tables t
WHERE t.table_schema = 'pm' AND t.table_type = 'BASE TABLE'

),
inductions AS MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
diagrams_citations AS MATERIALIZED (
    -- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH
citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

)
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c

),
dependences AS MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
descents AS MATERIALIZED (
    -- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

)
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
domain_objects AS MATERIALIZED (
    -- the pm.* tables against BPMN 2.0's element vocabulary, as data an emitter reads.
SELECT * FROM (VALUES
  ('source', 'definitions', NULL, 'definitions', NULL, NULL, 'the document itself. A BPMN file is a definitions document'),
  ('filing', 'participant', NULL, 'pools', NULL, NULL, 'the participant that renders the document as a pool'),
  ('filing_identity', 'targetNamespace', NULL, 'namespaces', NULL, NULL, 'a notation resolved to a document, which is what import does'),
  ('layer', 'lane', NULL, 'lanes', NULL, NULL, 'a lane, and the region it delimits'),
  ('operation', 'task', NULL, 'tasks', 'demoted', 'The pointer is on the page and no tool can follow it, which is the state `pm:ForeignId` intends. A notation plus an id names a node in the process notation the filer was reading, which is a different document from this one, so it must not become this task''s own `id` (that would claim the two documents are one) and it cannot be a `relationship`, whose `source` and `target` are QNames needing an `import` that needs a location nobody filed. It rides the task''s `documentation`: a person reads the id, a tool resolves nothing. Unlike every other `demoted` row here, the tool could not do better even in principle, because no authority publishes the list it would resolve against', 'a flow node, reached by foreignId. And the column did not exist, so this row read `loses` nothing while losing the only thing it is about. `pm:Operation/foreignId` is the whole BPMN interface, the ingest read the label alone, and the crossing was filed by the corpus, discarded on every load and absent from every artifact. Third of the model''s three `pm:ForeignId` references and the last without a relation beside it: `entries/notation_references.sqlc`'),
  ('draw', 'laneSet', NULL, 'in_a_lane', NULL, NULL, 'D. The lane set a modeller actually files: the performer''s lane'),
  ('induction', 'group', NULL, 'induced_into', 'demoted', 'The pointer, and nothing else now. `tCategoryValue` adds one `xs:string` to a base element and no reference attribute, so the layer arrives as text beside a `lane` of the same name. That is the callActivity defect at one tenth the size: a call loses the layer, this keeps its name and loses the tie. `decider` is lost too, and for the ordinary reason: it is a performer and nothing here files a claimant edge', 'N, the cover. Emitted as categoryValueRef on each operation and drawn as a group, which adds no lane where a second laneSet would have added one per induced layer'),
  ('part', 'callActivity', NULL, 'calls', 'absent', 'What is left is the factor. With `calledElement` as the only reference the target layer went too: it names a process, so 17 layer-grain edges collapsed to 5 document pairs. `tRelationship` takes QNames at both ends and a required `type`, so `diagrams/descents.sqlc` now carries the same fact at the grain F has, read back and compared edge for edge. What no element carries is the factor, a three-point magnitude on a page with no unit, and that is `absent` for the reason every magnitude here is. And this row is at the wrong grain to say so: one table maps to two elements now, `callActivity` for the substitution and `relationship` for the grain, and the roster has one `element` and one `governed_by`', 'foreign; an embedded subProcess when the part is local'),
  ('composition_citation', 'documentation', NULL, 'citations', 'demoted', 'The structure, and not everything. The table settles it: `pm.composition_citation` is `(taxonomy, instrument, clause, version)`, four typed fields, not free prose. A `documentation` element carries all four as one string, so a reader can follow the citation and a tool cannot resolve it. Narrower than *everything* and worth being exact about, because the two states owe different repairs', 'the instrument a composition is filed under. The open question is the schema''s and not the diagram''s: `(composition, seq)` is a bare document ordinal where both sibling children carry a regime handle'),

  ('coupling', 'association', NULL, 'dependences', 'absent', 'The observation and the strength, which is all the evidence there is. `pm:observed` is required prose and it is the whole argument; an `association` carries none, and two of the five observations here contain a numeral, so routing them through `documentation` would put a magnitude on a page with no unit, which is `dataObject`''s refusal arriving through prose. The artifact says two layers are coupled and cannot say what was seen', 'C, the model''s own falsifier. `sourceRef` and `targetRef` are unconstrained QNames, so two lanes are a legal pair; withheld for years on a reason that ruled out `messageFlow` and was never asked of this'),
  ('coupling_search', 'documentation', NULL, 'documentation', NULL, NULL, 'the other half of the pair, on the laneSet, because the laneSet is the partition the search is about. 12 of 15 filings state no coupling, so a diagram drawing only the matrix is silent about them in a way a reader resolves as independence. An absent line is not independence'),
  ('elimination_search',   NULL, 'notApplicable', NULL, NULL, NULL, 'the same, for double counting'),
  ('stack_scope', 'documentation', NULL, 'scopes', 'demoted', 'The structure. `tLaneSet` has no extent attribute of any kind, so all three states render as one lane set and the answer survives only as untyped text. BPMN is the finer of the two on the basis and has nothing at all on the extent: `tLane` carries `partitionElement` and `partitionElementRef` for what a partition is by, per lane, where this model files one basis per stack. The grain axis, running backwards for once', 'This row said `notApplicable` while its own reason said *a lane set is implicitly complete*, and a tuple that contradicts itself is the sharpest finding shape there is. Both cannot hold: if the answer is implicitly complete then the question arose and the artifact answered it. It did, literally, in a hardcoded sentence in 15 of 15 documents where 1 filing claims complete. That is `invents` and not an absence, and the repair was to read the extent instead of asserting it'),
  ('elimination',          NULL, 'notApplicable', NULL, NULL, NULL, 'a call references and never redeclares, so BPMN cannot double declare and owes no correction'),
  ('elimination_between', 'relationship', NULL, 'attributions', 'absent', 'The size of the overlap, which is `pm.elimination`''s business and not this table''s, and the references that do not resolve: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at. 8 of 8 resolve here, so that arm is unexercised by luck', 'Filed `notApplicable` on a reason that was never about it: *presupposes the overlap BPMN cannot express*. That is about the magnitude, and this table has none. It is `asrt:FiledLayer`, whose filing is a `pm:ForeignId`, the same reference type a part uses, and the schema says it exists *so the attribution is queryable rather than narrated*. The reason it stayed invisible is structural: this tree grows by rules, and `between` is the one cross-document reference no rule may check, because the schema licenses an unresolvable one outright'),

  ('nameplate',            NULL, 'none', NULL, NULL, NULL,          'a committed, quantized magnitude. BPMN carries no quantity anywhere'),
  ('slack',                NULL, 'none', NULL, NULL, NULL,          'three buffers per layer, each a magnitude'),
  ('claim',                NULL, 'none', NULL, NULL, NULL,          'a value at a position, with its own width'),
  ('narrowing',            NULL, 'none', NULL, NULL, NULL,          'what would narrow a claim. BPMN has no epistemics'),
  ('bound_origin',         NULL, 'none', NULL, NULL, NULL,          'where a bound came from. The same'),
  ('absence',              NULL, 'none', NULL, NULL, NULL,          'a typed reason there is no value, with the note that argues for it. The same'),
  ('derivation',           NULL, 'none', NULL, NULL, NULL,          'the identity a value is computed by, with the note beside it. BPMN computes nothing it carries'),
  ('fusion',               NULL, 'none', NULL, NULL, NULL,          'what the composer observed that makes its parts one layer. The parts are drawn, as `part` says; the observation is prose no element here carries, for the reason `coupling` gives'),
  ('regime',               NULL, 'none', NULL, NULL, NULL,          'the jurisdiction and framework a document reports under'),
  ('composition_regime',   NULL, 'none', NULL, NULL, NULL,          'what a composer says another document''s regime is: a second claim with a second author, and no more drawable than the first'),
  ('buffer_term',          NULL, 'none', NULL, NULL, NULL,          'a taxonomy lookup a reader can delete'),

  ('holder',               NULL, 'misreads', NULL, NULL, NULL,      'resourceRole and performer have the right shape and the wrong claim: they say who acts, and a holder is who bears. Four of the five kinds name no party at all')
) AS d(object, element, absent, governed_by, loses_kind, loses, why)

),
foreign_calls AS MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
diagrams_searches AS MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
legends AS MATERIALIZED (
    -- the notes a correct reading requires; BPMN 2.0 tTextAnnotation, drawn and unattached.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
foreign_calls AS NOT MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS NOT MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT s.filing, 'scope' AS note, 'diagrams/scopes.sqlc' AS states
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT s.filing, 'search', 'diagrams/searches.sqlc'
FROM ( SELECT * FROM diagrams_searches ) s
UNION ALL
SELECT DISTINCT d.filing, 'dependence', 'diagrams/dependences.sqlc'
FROM ( SELECT * FROM dependences ) d
UNION ALL
SELECT DISTINCT c.filing, 'cover', 'diagrams/categories.sqlc'
FROM ( SELECT * FROM categories ) c
UNION ALL
SELECT DISTINCT e.filing, 'lane', 'diagrams/lane_grain.sqlc'
FROM ( -- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM every_layer
) l
LEFT JOIN (
    SELECT * FROM lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
 ) e
WHERE NOT e.occupied

),
every_filing AS MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

),
pools AS MATERIALIZED (
    -- epistemics/documents.sqlc projected to the filing alone; one pool per document.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

)
SELECT d.filing
FROM (
    SELECT * FROM documents
) d

),
eliminations_between AS MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

),
operations AS MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

),
notation_references AS MATERIALIZED (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL

),
expected AS MATERIALIZED (
    -- diagrams/roster.sqlc's model_side relations, each counted.
WITH
composition_citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

),
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
diagrams_citations AS NOT MATERIALIZED (
    -- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH
citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

)
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
descents AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

)
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
foreign_calls AS NOT MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS NOT MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

),
legends AS NOT MATERIALIZED (
    -- the notes a correct reading requires; BPMN 2.0 tTextAnnotation, drawn and unattached.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
foreign_calls AS NOT MATERIALIZED (
    -- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

),
lane_membership AS NOT MATERIALIZED (
    -- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    -- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM foreign_calls
) c

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT s.filing, 'scope' AS note, 'diagrams/scopes.sqlc' AS states
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT s.filing, 'search', 'diagrams/searches.sqlc'
FROM ( SELECT * FROM diagrams_searches ) s
UNION ALL
SELECT DISTINCT d.filing, 'dependence', 'diagrams/dependences.sqlc'
FROM ( SELECT * FROM dependences ) d
UNION ALL
SELECT DISTINCT c.filing, 'cover', 'diagrams/categories.sqlc'
FROM ( SELECT * FROM categories ) c
UNION ALL
SELECT DISTINCT e.filing, 'lane', 'diagrams/lane_grain.sqlc'
FROM ( -- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM every_layer
) l
LEFT JOIN (
    SELECT * FROM lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
 ) e
WHERE NOT e.occupied

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

),
pools AS NOT MATERIALIZED (
    -- epistemics/documents.sqlc projected to the filing alone; one pool per document.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

)
SELECT d.filing
FROM (
    SELECT * FROM documents
) d

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

),
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

),
notation_references AS NOT MATERIALIZED (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL

)
SELECT 'pools'   AS slug, count(*) AS expected FROM ( SELECT * FROM documents )  x
UNION ALL
SELECT 'lanes',   count(*) FROM ( SELECT * FROM every_layer )    x
UNION ALL
SELECT 'tasks',   count(*) FROM ( SELECT * FROM operations )    x
UNION ALL
SELECT 'calls',   count(*) FROM ( SELECT * FROM foreign_calls ) x
UNION ALL
SELECT 'nestings', count(*) FROM ( -- diagrams/calls.sqlc pinned to local parts, folded to the parent lane that will hold them.
SELECT DISTINCT c.composition, c.composed_layer
FROM (
    SELECT * FROM calls
) c
WHERE c.is_local
 )    x
UNION ALL
SELECT 'categories', count(DISTINCT x.filing) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'category_values', count(*) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'groups',     count(*) FROM ( SELECT * FROM categories ) x
UNION ALL
SELECT 'induced_into', count(*) FROM ( -- pm:Operation/pm:Induction as incidence; BPMN 2.0 tFlowElement/categoryValueRef.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT i.filing, i.operation, i.layer
FROM (
    SELECT * FROM inductions
) i
 ) x
UNION ALL
SELECT 'diagrams', count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'planes',   count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'shapes',   count(*) FROM ( -- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM dependences ) d
 ) x WHERE x.di = 'shape'
UNION ALL
SELECT 'edges',    count(*) FROM ( -- BPMN 2.0 DI: a bpmndi:BPMNShape per box and a bpmndi:BPMNEdge per route.
SELECT p.filing AS document, 'pool' AS shape_of, p.filing AS subject, 'shape' AS di
FROM ( SELECT * FROM pools ) p
UNION ALL
SELECT l.filing, 'lane', l.layer, 'shape'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT o.filing, 'task', o.label, 'shape'
FROM ( SELECT * FROM operations ) o
UNION ALL
SELECT c.composition, 'callActivity', c.composed_layer || '<-' || c.part_filing || '/' || c.part_layer, 'shape'
FROM ( SELECT * FROM foreign_calls ) c
UNION ALL
SELECT k.filing, 'group', k.layer, 'shape'
FROM ( SELECT * FROM categories ) k
UNION ALL
SELECT g.filing, 'textAnnotation', g.note, 'shape'
FROM ( SELECT * FROM legends ) g
UNION ALL
SELECT d.filing, 'association', d.from_layer || '->' || d.to_layer, 'edge'
FROM ( SELECT * FROM dependences ) d
 ) x WHERE x.di = 'edge'
UNION ALL
SELECT 'legends', count(*) FROM ( SELECT * FROM legends ) x
UNION ALL
SELECT 'descents', count(*) FROM ( SELECT * FROM descents ) x
UNION ALL
SELECT 'attributions', count(*) FROM ( SELECT * FROM resolved ) x
UNION ALL
SELECT 'citations', count(*) FROM ( SELECT * FROM diagrams_citations ) x
UNION ALL
SELECT 'scopes', count(*) FROM ( SELECT * FROM diagrams_scopes ) x
UNION ALL
SELECT 'dependences', count(*) FROM ( SELECT * FROM dependences ) x
UNION ALL
SELECT 'namespaces', count(*) FROM ( SELECT * FROM notations ) x
UNION ALL
SELECT 'imports', count(*) FROM ( -- diagrams/calls.sqlc's foreign parts, and the filed layers an elimination is stated between.
SELECT DISTINCT x.composition, x.part_notation
FROM (
    SELECT c.composition, c.part_notation
    FROM ( SELECT * FROM calls ) c
    WHERE NOT c.is_local
    UNION
    SELECT b.composition, b.notation
    FROM ( SELECT * FROM eliminations_references ) b
) x
 ) x
UNION ALL
SELECT 'in_a_lane', count(*) FROM ( SELECT * FROM lane_membership ) x
UNION ALL
SELECT 'definitions',   count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'collaboration', count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'process',       count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'lane_set',      count(*) FROM ( SELECT * FROM pools ) x
UNION ALL
SELECT 'documentation', count(*) FROM ( -- the pools, the lanes and the categories, which are the three places provenance is owed.
WITH
composition_citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

),
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

),
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

),
categories AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i

),
diagrams_citations AS NOT MATERIALIZED (
    -- asrt:Composition/asrt:citation, flattened to the one string a documentation element can hold.
WITH
citations AS NOT MATERIALIZED (
    -- asrt:composition/asrt:citation, one row each.
SELECT c.composition, c.seq, c.taxonomy, c.instrument, c.clause, c.version
FROM pm.composition_citation c

)
SELECT c.composition,
       c.instrument
         || coalesce(' clause ' || c.clause, '')
         || coalesce(' (' || c.version || ')', '')
         || ' under ' || c.taxonomy AS cited
FROM (
    SELECT * FROM composition_citations
) c

),
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

),
dependences AS NOT MATERIALIZED (
    -- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c

),
descents AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:Part crossing a document; BPMN 2.0 tRelationship source/target.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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
calls AS NOT MATERIALIZED (
    -- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
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

)
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM parts
) p

)
SELECT c.composition, c.composed_layer, c.part_filing, c.part_layer, c.part_notation
FROM (
    SELECT * FROM calls
) c
WHERE NOT c.is_local

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

),
pools AS NOT MATERIALIZED (
    -- epistemics/documents.sqlc projected to the filing alone; one pool per document.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
every_filing AS NOT MATERIALIZED (
    -- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f

),
documents AS NOT MATERIALIZED (
    -- The five top-level declarations: pm:processModulus and asrt:composition/dependence/coverage/run.
SELECT s.name AS filing,
       x.root, x.ns,
       fi.notation, fi.absent AS notation_absent,
       f.evidence, f.evidence_absent,
       x.witness, x.observed_at, x.ran_at
FROM      pm.source s
CROSS JOIN XMLTABLE(XMLNAMESPACES('https://example.invalid/assertion/1.0' AS asrt),
       '/*' PASSING s.body
       COLUMNS root        text PATH 'local-name(.)',
               ns          text PATH 'namespace-uri(.)',
               witness     text PATH 'asrt:witness',
               observed_at text PATH 'asrt:observedAt',
               ran_at      text PATH 'asrt:ranAt') x
LEFT JOIN (
    SELECT * FROM notations
) fi ON fi.filing = s.name
LEFT JOIN (
    SELECT * FROM every_filing
) f ON f.filing = s.name

)
SELECT d.filing
FROM (
    SELECT * FROM documents
) d

),
epistemics_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

),
diagrams_scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM epistemics_scopes
) s

),
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

),
searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

),
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

),
notation_references AS NOT MATERIALIZED (
    -- pm:Operation/pm:notationPosition, the stated arm: a notation plus an id.
WITH
operations AS NOT MATERIALIZED (
    -- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o

)
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_notation IS NOT NULL

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT 'document' AS annotated, d.filing AS subject,
       'diagrams/pools.sqlc' AS states
FROM ( SELECT * FROM pools ) d
UNION ALL
SELECT 'lane', l.filing || '/' || l.layer, 'rank/evaluation_order.sqlc'
FROM ( SELECT * FROM every_layer ) l
UNION ALL
SELECT 'category', c.filing, 'diagrams/categories.sqlc'
FROM ( SELECT DISTINCT k.filing FROM ( SELECT * FROM categories ) k ) c
UNION ALL
SELECT 'lane set, the coupling search', s.filing, 'diagrams/searches.sqlc'
FROM ( SELECT * FROM diagrams_searches ) s
UNION ALL
SELECT 'lane set, the scope', s.filing, 'diagrams/scopes.sqlc'
FROM ( SELECT * FROM diagrams_scopes ) s
UNION ALL
SELECT 'process, the citation', c.composition, 'diagrams/citations.sqlc'
FROM ( SELECT * FROM diagrams_citations ) c
UNION ALL
SELECT 'relationship', d.composition || '/' || d.composed_layer || '<-' || d.part_filing || '/' || d.part_layer,
       'diagrams/descents.sqlc'
FROM ( SELECT * FROM descents ) d
UNION ALL
SELECT 'relationship, an attribution',
       b.composition || '/' || b.composed_layer || '<>' || b.resolved_filing || '/' || b.layer,
       'diagrams/attributions.sqlc'
FROM ( -- eliminations/resolved.sqlc projected to the two ends of the relationship.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

)
SELECT b.composition, b.composed_layer, b.notation, b.resolved_filing, b.layer
FROM (
    SELECT * FROM resolved
) b
 ) b
UNION ALL
SELECT 'dependence', d.filing || '/' || d.from_layer || '->' || d.to_layer,
       'diagrams/dependences.sqlc'
FROM ( SELECT * FROM dependences ) d
UNION ALL
SELECT 'task, the notation position', n.filing || '/' || n.label,
       'entries/notation_references.sqlc'
FROM ( SELECT * FROM notation_references ) n
UNION ALL
SELECT 'task, no notation position', o.filing || '/' || o.label,
       'entries/operations.sqlc'
FROM ( SELECT * FROM operations ) o
WHERE o.foreign_absent IS NOT NULL
 ) x

),
diagrams_roster AS MATERIALIZED (
    -- the cardinality identities a BPMN emission owes, against the relation supplying each expected count.
SELECT * FROM (VALUES
  ('pools',   '|participant| = |filing|',      'epistemics/documents',     'participant',
              'a document rendered as two pools, or two rendered as one'),
  ('lanes',   '|lane| = |layer|',              'layers/every_layer',       'lane',
              'a partition rendered as an overlap: the falsifier, drawn'),
  ('tasks',   '|task| = |operation|',          'entries/operations',       'task',
              'an operation dropped, or a flow node invented to make the picture read'),
  ('calls',   '|callActivity| = |part crossing a document|', 'diagrams/foreign_calls', 'callActivity',
              'One law over two elements would let a local part be rendered as an activity. A local fusion is a partition of the composed layer, not a node inside it. Splitting the law is also what makes the flattening measurable: only these parts go through `calledElement`, so this is the population exposed to the invented-cycle defect'),
  ('nestings', '|childLaneSet| = |layer with a local part|', 'diagrams/nestings', 'childLaneSet',
              'The recursion equivalence, and BPMN already had the element. A fusion''s parts partition what they compose, and `Lane/childLaneSet` is a sub-partition. A nested lane is still keyed `(filing, layer)`, so unlike a call it collapses nothing and can invent nothing'),
  ('categories', '|category| = |filing with an induction|', 'diagrams/categories', 'category',
              'a classification scheme emitted into a document that has nothing to classify, or a document with inductions and no scheme to hang them on'),
  ('category_values', '|categoryValue| = |layer induced into|', 'diagrams/categories', 'categoryValue',
              'N getting a notation. The route that does not work is a second `laneSet`, which gives every layer two `lane` elements. BPMN''s other mechanism adds no lane at all: `tFlowElement/categoryValueRef` is `maxOccurs="unbounded"`, so the member declares the cover and no container grows'),
  ('groups',     '|group| = |categoryValue|',    'diagrams/categories', 'group',
              'The glyph against the fact, and the pair is the answer to what a group is. `group` is to `categoryValueRef` what `lane` is to `flowNodeRef`: the drawn shape of an incidence held elsewhere. A categoryValue with no group is a classification nobody drew; a group with no categoryValue is a dashed box that means nothing'),
  ('induced_into', '|categoryValueRef| = |induction|', 'diagrams/category_members', 'categoryValueRef',
              'An induction dropped, which `|lane| = |layer|` cannot see. One operation here draws from `labour` and induces into `capability`; a lane set holds it in one place, so holding it in the draw alone leaves the second incidence out of every emitted document while the layer count still agrees'),
  ('diagrams', '|BPMNDiagram| = |filing|', 'diagrams/pools', 'BPMNDiagram',
              'The SVG''s proper place in the document. `bpmndi:BPMNDiagram` is in `tDefinitions`''s own sequence, and a document without one leaves the SVG stage to invent its coordinates while any tool that opens the file lays it out differently: two pictures of one model with nothing tying them'),
  ('planes', '|BPMNPlane| = |filing|', 'diagrams/pools', 'BPMNPlane',
              'one surface per document, naming the collaboration it is a picture of. A second plane would be a second picture of one model with no way to say which is meant'),
  ('shapes', '|BPMNShape| = every element that owes a box', 'diagrams/shapes', 'BPMNShape',
              'The primitives are not all of it, and the tempting answer is that a `group`, an `association` and a `textAnnotation` are derived from these boxes, so filing a derived coordinate files a value that can disagree with whatever computes it. That argument holds and it is about the wrong column: `diagrams/shapes.sqlc` carries no coordinate for anything, so a row there says which elements owe a box and never where it is, and the derivation belongs in the emitter. An element drawn from geometry the document does not declare is an element every other reader of the file loses, without an error'),
  ('edges', '|BPMNEdge| = |association|', 'diagrams/shapes', 'BPMNEdge',
              'The one route in the notation, and it needs a different carrier from every box here: `bpmndi:BPMNEdge` with `di:waypoint`s, in a third namespace. Counting it with the shapes would make `|BPMNShape|` a number that matches nothing in the document, which is why `diagrams/shapes.sqlc` declares `di` per row'),
  ('legends', '|textAnnotation| = |note a document owes on its face|', 'diagrams/legends', 'textAnnotation',
              'A fact present and invisible, which is what this law catches. `documentation` is admitted on any base element and drawn in no rendering, so a scope, a coupling search, a dependence''s meaning and a cover''s meaning can all be in the artifact and on no page. `textAnnotation` is the only element in BPMN that puts words on the canvas, and *documentation is spent instead* is true and about the wrong property'),
  ('attributions', '|relationship type=elimination-between| = |between that resolves|', 'eliminations/resolved', 'relationship',
              'The second `pm:ForeignId`, and the element''s type earning its keep. `association` was refused for F because it has no type and a second use makes two facts indistinguishable; `tRelationship/@type` is required, so a second relation costs a different string and the laws filter on it. The population is the resolved references and not all of them: a QName needs a prefix and a prefix needs an import, so a `between` naming a document nobody filed cannot be pointed at, and the schema calls that filing ordinary'),
  ('descents', '|relationship| = |part crossing a document|', 'diagrams/descents', 'relationship',
              'The mapping''s widest demotion, promoted. `calledElement` names a process, so 17 layer-grain edges collapsed to 5 document pairs and the layer survived only inside `@name`. The count is the weak half: 17 relationships joining the wrong 17 pairs passes it, which is why the isomorphism law in examples/diagramming/main.rs reads the endpoints back and compares the edge set to F'),
  ('citations', '|citation rendered| = |citation filed|', 'diagrams/citations', 'documentation',
              'A table declared as mapping and rendered nowhere, which no count of elements can see. Element kinds are not one to one: the pools and the lanes spend `documentation` too, so a count of that element is exact while this table''s share of it is zero, and `diagrams/ungoverned.sqlc` is the law that checks attribution instead'),
  ('scopes', '|scope stated| = |filing|', 'diagrams/scopes', 'documentation',
              'The `invents` state, caught in the emitter''s own prose. A sentence about a filing, hardcoded in the emitter, says one thing about every document where the filings differ, and `diagrams/scopes.sqlc` is what each one claims. That is not something a reader infers: the artifact says it. A count is not the law that matters here, the attribution one below it is: this only checks that a scope reached every document, and a wrong scope in every document would pass it'),
  ('dependences', '|association| = |coupling|', 'diagrams/dependences', 'association',
              'The model''s own falsifier, which no emitted document could state. `pm:Coupling` exists so the model can be refuted in its own format, and the reason that rules out `messageFlow` says nothing about `association`, whose `sourceRef` and `targetRef` are unconstrained QNames. The law is worth as much for what it cannot check: an association carries no magnitude and no observation, so |association| = |coupling| passes while the evidence and the strength are both gone'),
  ('namespaces', '|targetNamespace| = |notation|', 'composition/notations', 'targetNamespace',
              'a document that does not declare the uri it is, so nothing can reference it'),
  ('imports', '|import| = |document a composition reaches by a part or an elimination|', 'diagrams/cross_document', 'import',
              'a reference invented by the emitter, or a document reached without being imported'),
  ('in_a_lane', '|flowNodeRef| = |draw| + |part crossing a document|', 'diagrams/lane_membership', 'flowNodeRef',
              'an orphan flow node: emitted, counted, and in no lane, so the incidence that put it there is gone from the rendering while every cardinality law still passes'),
  ('definitions',   '|definitions| = |filing|',   'diagrams/pools', 'definitions',
              'a filing emitted twice, or one skipped, which no leaf count would show'),
  ('collaboration', '|collaboration| = |filing|', 'diagrams/pools', 'collaboration',
              'one filing split across two collaborations, so its pool has no single home'),
  ('process',       '|process| = |filing|',       'diagrams/pools', 'process',
              'one filing split into two processes, which makes its layers two partitions'),
  ('lane_set',      '|laneSet| = |filing|',       'diagrams/pools', 'laneSet',
              'The one that governs the elimination: a second lane set is how D and N would both be rendered, and every layer then has two lane elements with nothing but a matching name to say they are one layer'),
  ('documentation', '|documentation| = |sentence a relation states|', 'diagrams/annotated', 'documentation',
              'Documentation is not a container, which is what separates this row from the other four. They frame a document and must appear once; this is an annotation and may sit on any base element, so one per document fires the moment a lane is annotated, which is a law right about a fact and wrong about a kind. And the identity beside it is prose where the model side is a relation, so `diagrams/annotated.sqlc` can grow an arm with this count staying exact and the sentence describing it going stale. A count is also the wrong instrument here and always was, which is what `states` is for: every document can carry the right number of sentences and each say something no relation states, with the count exact for any corpus size. examples/diagramming/main.rs reads every one back and asks what states it')
) AS l(slug, law, model_side, element, catches)

),
spillovers AS MATERIALIZED (
    -- pm:couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    SELECT * FROM couplings
) c
JOIN      (
    SELECT * FROM every_layer
) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    SELECT * FROM every_layer
) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    SELECT * FROM coupling_searches
) s  ON s.filing = b.filing
LEFT JOIN (
    SELECT * FROM epistemics_scopes
) sc ON sc.filing = b.filing

),
absence_columns AS MATERIALIZED (
    -- information_schema.columns, restricted to schema pm and type pm.absence_reason.
SELECT c.table_name::text  AS table_name,
       c.column_name::text AS column_name
FROM information_schema.columns c
WHERE c.table_schema = 'pm'
  AND c.udt_schema   = 'pm'
  AND c.udt_name     = 'absence_reason'
  AND (c.table_name, c.column_name) <> ('absence', 'reason')

),
absence_questions AS MATERIALIZED (
    -- epistemics/absences.sqlc's arms, each against the pm column of type absence_reason it reads.
SELECT * FROM (VALUES
  ('demand',                               'layer',              'demand_absent'),
  ('remainder',                            'layer',              'remainder_absent'),
  ('remainder sign',                       'layer',              'sign_absent'),
  ('remainder quantity',                   'layer',              'qty_absent'),
  ('remainder absorber',                   'layer',              'absorber_absent'),
  ('patience',                             'layer',              'patience_absent'),
  ('nameplate amount',                     'nameplate',          'amount_absent'),
  ('divisibility',                         'nameplate',          'divisibility_absent'),
  ('lump size',                            'nameplate',          'quantum_absent'),
  ('duty-cycle period',                    'nameplate',          'window_size_absent'),
  ('measurement basis',                    'nameplate',          'measurement_basis_absent'),
  ('who committed the amount',             'nameplate',          'amount_origin_absent'),
  ('duty-cycle window',                    'nameplate',          'window_absent'),
  ('draw',                                 'nameplate',          'draw_absent'),
  ('buffer slack',                         'slack',              'absent'),
  ('holder share',                         'holder',             'share_absent'),
  ('operation draw',                       'draw',               'absent'),
  ('operation induction',                  'induction',          'absent'),
  ('where the operation is in a notation', 'operation',          'foreign_absent'),
  ('narrowsWhen',                          'narrowing',          'absent'),
  ('boundOrigin',                          'bound_origin',       'absent'),
  ('denominator',                          'claim',              'denominator_absent'),
  ('provenance standing',                  'claim',              'prov_standing_absent'),
  ('provenance standing, on an absence',   'absence',            'prov_standing_absent'),
  ('provenance standing, on a derivation', 'derivation',         'prov_standing_absent'),
  ('how much of the system',               'stack_scope',        'absent'),
  ('did anybody look for couplings',       'coupling_search',    'absent'),
  ('coupling strength',                    'coupling',           'strength_absent'),
  ('its own notation',                     'filing_identity',    'absent'),
  ('what it is evidence for',              'filing',             'evidence_absent'),
  ('assertion standing',                   'filing',             'prov_standing_absent'),
  ('did anybody look for double counting', 'elimination_search', 'absent'),
  ('eliminated quantity',                  'elimination',        'absent'),
  ('part factor',                          'part',               'factor_absent'),
  ('regime framework',                     'regime',             'framework_absent'),
  ('regime chart',                         'regime',             'chart_absent'),
  ('part regime framework',                'composition_regime', 'framework_absent'),
  ('part regime chart',                    'composition_regime', 'chart_absent')
) AS q(question, table_name, column_name)

),
filed_absences AS MATERIALIZED (
    -- pm:Absence and pm:ClaimAbsence, every one, with pm:note, pm:asOf and pm:provenance.
SELECT a.filing, a.seq, a.owns, a.layer, a.reason, a.note, a.as_of,
       a.prov_party, a.prov_entered_by, a.prov_approved_by,
       a.prov_standing_taxonomy, a.prov_standing_value, a.prov_standing_absent, a.prov_note
FROM pm.absence a

),
filed_derivations AS MATERIALIZED (
    -- pm:Derivation and its restrictions, every one, with pm:note, pm:asOf and pm:provenance.
SELECT d.filing, d.seq, coalesce(d.claim_owns, d.owns) AS owns, d.owns AS element, d.layer,
       d.identity, d.note, d.as_of,
       d.prov_party, d.prov_entered_by, d.prov_approved_by,
       d.prov_standing_taxonomy, d.prov_standing_value, d.prov_standing_absent, d.prov_note
FROM pm.derivation d

),
patience AS MATERIALIZED (
    -- pm:Demand/pm:patience, beside the demand it qualifies.
SELECT l.filing, l.layer,
       l.patience_low, l.patience_mode, l.patience_high, l.patience_unit,
       l.patience_absent,
       l.demand_unit
FROM pm.layer l

),
absences AS MATERIALIZED (
    -- every pm:absent/reason in the schema, from every element that admits one.
SELECT filing, subject, question, reason FROM (
    SELECT filing, layer AS subject, 'demand'              AS question, absent                AS reason FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'remainder sign',      sign_absent           FROM (
        SELECT * FROM filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder quantity',  qty_absent            FROM (
        SELECT * FROM filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder absorber',  absorber_absent       FROM (
        SELECT * FROM filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'nameplate amount',    absent                FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'divisibility',        divisibility_absent   FROM (
        -- pm:Layer/pm:supply, pm:Facility with its pm:Nameplate and pm:Jagged, one row per layer.
SELECT n.filing, n.layer, n.facility_label,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.quantum_origin,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_origin, n.window_absent,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent,
       n.measurement_basis_contributed, n.measurement_basis_taxonomy, n.measurement_basis_value,
       n.measurement_basis_absent
FROM pm.nameplate n

    ) f
    UNION ALL SELECT filing, layer, 'who committed the amount', amount_origin_absent FROM (
        -- pm:Layer/pm:supply, pm:Facility with its pm:Nameplate and pm:Jagged, one row per layer.
SELECT n.filing, n.layer, n.facility_label,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.quantum_origin,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_origin, n.window_absent,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent,
       n.measurement_basis_contributed, n.measurement_basis_taxonomy, n.measurement_basis_value,
       n.measurement_basis_absent
FROM pm.nameplate n

    ) f
    UNION ALL SELECT filing, layer, 'lump size',           quantum_absent        FROM (
        -- pm:Layer/pm:supply, pm:Facility with its pm:Nameplate and pm:Jagged, one row per layer.
SELECT n.filing, n.layer, n.facility_label,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.quantum_origin,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_origin, n.window_absent,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent,
       n.measurement_basis_contributed, n.measurement_basis_taxonomy, n.measurement_basis_value,
       n.measurement_basis_absent
FROM pm.nameplate n

    ) f
    UNION ALL SELECT filing, layer, 'measurement basis',   measurement_basis_absent FROM (
        -- pm:Layer/pm:supply, pm:Facility with its pm:Nameplate and pm:Jagged, one row per layer.
SELECT n.filing, n.layer, n.facility_label,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.quantum_origin,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_origin, n.window_absent,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent,
       n.measurement_basis_contributed, n.measurement_basis_taxonomy, n.measurement_basis_value,
       n.measurement_basis_absent
FROM pm.nameplate n

    ) f
    UNION ALL SELECT filing, layer, 'duty-cycle window',   window_absent         FROM (
        SELECT * FROM windows
    ) w
    UNION ALL SELECT filing, layer, 'duty-cycle period',   window_size_absent    FROM (
        SELECT * FROM windows
    ) w
    UNION ALL SELECT filing, layer, 'draw',                absent                FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'buffer slack',      absent    FROM (
        SELECT * FROM slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text,   'holder share',      share_absent FROM (
        SELECT * FROM holders
    ) h
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation draw',       absent    FROM (
        SELECT * FROM draws
    ) d
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation induction',  absent    FROM (
        SELECT * FROM inductions
    ) i
    UNION ALL SELECT filing, label, 'where the operation is in a notation',
                     foreign_absent::pm.absence_reason FROM (
        SELECT * FROM operations
    ) o
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'narrowsWhen',      narrows_absent FROM (
        SELECT * FROM claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'boundOrigin',      origin_absent  FROM (
        SELECT * FROM claims
    ) c
    UNION ALL SELECT filing, '(the stack)',   'how much of the system',           absent    FROM (
        SELECT * FROM epistemics_scopes
    ) sc
    UNION ALL SELECT filing, '(the stack)',   'did anybody look for couplings',   answer    FROM (
        SELECT * FROM coupling_searches
    ) cs
    UNION ALL SELECT filing, '(the document)', 'its own notation',                absent    FROM (
        SELECT * FROM notations
    ) n
    UNION ALL SELECT composition, composed_layer, 'did anybody look for double counting', answer FROM (
        SELECT * FROM searched
    ) es
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'eliminated quantity', absent FROM (
        SELECT * FROM filed
    ) e
    UNION ALL SELECT filing, layer, 'remainder',                        reason           FROM (
        SELECT * FROM denied_remainders
    ) dr
    UNION ALL SELECT filing, layer, 'patience',                         patience_absent  FROM (
        SELECT * FROM patience
    ) pa
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'denominator',         denominator_absent   FROM (
        SELECT * FROM claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'provenance standing', prov_standing_absent FROM (
        SELECT * FROM claims
    ) c
    UNION ALL SELECT filing, owns || ' absence ' || seq::text, 'provenance standing, on an absence',
                     prov_standing_absent FROM (
        SELECT * FROM filed_absences
    ) fa
    UNION ALL SELECT filing, owns || ' derivation ' || seq::text,
                     'provenance standing, on a derivation', prov_standing_absent FROM (
        SELECT * FROM filed_derivations
    ) fd
    UNION ALL SELECT filing, from_layer || ' -> ' || to_layer, 'coupling strength', strength_absent FROM (
        SELECT * FROM couplings
    ) cp
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'part factor', factor_absent FROM (
        SELECT * FROM part_references
    ) pr
    UNION ALL SELECT filing,      'regime ' || id,      'regime framework',      framework_absent FROM (
        SELECT * FROM regimes
    ) r
    UNION ALL SELECT filing,      'regime ' || id,      'regime chart',          chart_absent     FROM (
        SELECT * FROM regimes
    ) r
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime framework', framework_absent FROM (
        SELECT * FROM composer_regimes
    ) cr
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime chart',     chart_absent     FROM (
        SELECT * FROM composer_regimes
    ) cr
    UNION ALL SELECT filing,      '(the document)',     'what it is evidence for', evidence_absent FROM (
        SELECT * FROM every_filing
    ) f
    UNION ALL SELECT filing,      '(the document)',     'assertion standing',    prov_standing_absent FROM (
        SELECT * FROM every_filing
    ) f
) a
WHERE reason IS NOT NULL

),
derivation_columns AS MATERIALIZED (
    -- information_schema.columns, restricted to schema pm and type pm.identity.
SELECT c.table_name::text  AS table_name,
       c.column_name::text AS column_name
FROM information_schema.columns c
WHERE c.table_schema = 'pm'
  AND c.udt_schema   = 'pm'
  AND c.udt_name     = 'identity'
  AND (c.table_name, c.column_name) <> ('derivation', 'identity')

),
epistemics_searches AS MATERIALIZED (
    -- pm:Stack/pm:couplings and asrt:Fusion/asrt:eliminations, each with its pm:absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.answer, cs.note
FROM (
    SELECT * FROM coupling_searches
) cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.answer, es.note
FROM (
    SELECT * FROM searched
) es

),
absence_subjects AS MATERIALIZED (
    -- epistemics/absence_questions.sqlc against epistemics/absence_columns.sqlc, one row per column.
SELECT coalesce(q.table_name, k.table_name) || '.' || coalesce(q.column_name, k.column_name)
                                            AS subject,
       q.column_name IS NOT NULL            AS declared,
       count(k.column_name)                 AS rows
FROM      (
    SELECT * FROM absence_questions
) q
FULL JOIN (
    SELECT * FROM absence_columns
) k ON k.table_name = q.table_name AND k.column_name = q.column_name
GROUP BY q.table_name, q.column_name, k.table_name, k.column_name

),
derivation_subjects AS MATERIALIZED (
    -- identities/roster.sqlc's columns against epistemics/derivation_columns.sqlc, one row per column.
SELECT coalesce(r.table_name, k.table_name) || '.' || coalesce(r.column_name, k.column_name)
                                            AS subject,
       r.column_name IS NOT NULL            AS declared,
       count(k.column_name)                 AS rows
FROM      (
    SELECT DISTINCT i.table_name, i.column_name
    FROM (
        SELECT * FROM identities_roster
    ) i
) r
FULL JOIN (
    SELECT * FROM derivation_columns
) k ON k.table_name = r.table_name AND k.column_name = r.column_name
GROUP BY r.table_name, r.column_name, k.table_name, k.column_name

),
diagram_law_subjects AS MATERIALIZED (
    -- diagrams/roster.sqlc against diagrams/expected.sqlc, one row per diagram law.
SELECT coalesce(l.slug, e.slug)     AS subject,
       l.slug IS NOT NULL           AS declared,
       count(e.slug)                AS rows
FROM      (
    SELECT * FROM diagrams_roster
) l
FULL JOIN (
    SELECT * FROM expected
) e ON e.slug = l.slug
GROUP BY l.slug, e.slug

),
object_subjects AS MATERIALIZED (
    -- diagrams/domain_objects.sqlc against diagrams/catalogue.sqlc, one row per table.
SELECT coalesce(d.object, k.object) AS subject,
       d.object IS NOT NULL         AS declared,
       count(k.object)              AS rows
FROM      (
    SELECT * FROM domain_objects
) d
FULL JOIN (
    SELECT * FROM catalogue
) k ON k.object = d.object
GROUP BY d.object, k.object

),
rule_subjects AS MATERIALIZED (
    -- checks/roster.sqlc against checks/all.sqlc, one row per rule.
SELECT coalesce(r.rule, c.rule)                                                 AS subject,
       r.rule IS NOT NULL                                                       AS declared,
       count(c.rule)                                                            AS rows,
       count(c.rule) FILTER (WHERE c.violates IS NOT NULL)                      AS answered,
       count(c.rule) FILTER (WHERE c.violates)                                  AS violated,
       count(c.rule) FILTER (WHERE NOT c.violates)                              AS passed,
       count(c.rule) FILTER (WHERE c.violates IS NULL AND c.filing IS NOT NULL) AS silent,
       count(c.rule) FILTER (WHERE c.violates IS NULL AND c.filing IS NULL)     AS vacuous
FROM      (
    SELECT * FROM checks_roster
) r
FULL JOIN (
    SELECT * FROM checks_all
) c ON c.rule = r.rule
GROUP BY r.rule, c.rule

),
site_subjects AS MATERIALIZED (
    -- arithmetic/roster.sqlc against arithmetic/all.sqlc, one row per site.
SELECT coalesce(a.site, z.site)                                                AS subject,
       a.site IS NOT NULL                                                      AS declared,
       count(z.site)                                                           AS rows,
       count(z.site) FILTER (WHERE z.verdict IS NOT NULL)                      AS answered,
       count(z.site) FILTER (WHERE z.verdict = 'computable')                   AS computable,
       count(z.site) FILTER (WHERE z.verdict = 'suspended')                    AS suspended,
       count(z.site) FILTER (WHERE z.verdict = 'not comparable')               AS not_comparable,
       count(z.site) FILTER (WHERE z.verdict IS NULL AND z.filing IS NOT NULL) AS silent,
       count(z.site) FILTER (WHERE z.verdict IS NULL AND z.filing IS NULL)     AS vacuous
FROM      (
    SELECT * FROM arithmetic_roster
) a
FULL JOIN (
    SELECT * FROM arithmetic_all
) z ON z.site = a.site
GROUP BY a.site, z.site

),
decomposed AS MATERIALIZED (
    -- layers/lumpy.sqlc, split as r = m*q - (demand mod q) at the crossed pairs.
SELECT l.filing, l.layer, l.unit,
       l.quantum_mode AS q,
       l.n_low, l.n_mode, l.n_high,
       l.d_low, l.d_mode, l.d_high,
       floor(l.d_low  / l.quantum_mode) AS d_low_tooth,
       floor(l.d_mode / l.quantum_mode) AS d_mode_tooth,
       floor(l.d_high / l.quantum_mode) AS d_high_tooth,
       mod(l.d_low,  l.quantum_mode)    AS d_low_residue,
       mod(l.d_mode, l.quantum_mode)    AS d_mode_residue,
       mod(l.d_high, l.quantum_mode)    AS d_high_residue,
       l.n_low  / l.quantum_mode - floor(l.d_high / l.quantum_mode) AS m_low,
       l.n_mode / l.quantum_mode - floor(l.d_mode / l.quantum_mode) AS m_mode,
       l.n_high / l.quantum_mode - floor(l.d_low  / l.quantum_mode) AS m_high,
       floor(l.d_low / l.quantum_mode) <> floor(l.d_high / l.quantum_mode) AS crosses_tooth
FROM (
    SELECT * FROM lumpy
) l
WHERE l.d_low IS NOT NULL
  AND l.quantum_mode > 0
  AND l.quantum_low = l.quantum_high
  AND l.unit = l.amount_unit
  AND l.quantum_unit = l.amount_unit

),
remainder_scope AS MATERIALIZED (
    -- layers/remainder.sqlc against pm:Stack/pm:scope, pm:couplings/pm:absent and entries/spillovers.sqlc.
SELECT r.filing, r.layer,
       sc.extent,
       cs.answer AS search,
       sp.observed_in AS spilled_from,
       CASE WHEN sp.observed_in IS NOT NULL THEN 'takes a spillover'::public.remainder_standing
            WHEN sc.extent = 'unbounded'    THEN 'nobody bounded the set'::public.remainder_standing
            WHEN cs.answer  = 'unmeasured'  THEN 'set bounded, pairs untested'::public.remainder_standing
            ELSE 'bounded and the pairs answered'::public.remainder_standing END AS standing
FROM      (
    SELECT * FROM remainder
) r
LEFT JOIN (
    SELECT * FROM epistemics_scopes
) sc ON sc.filing = r.filing
LEFT JOIN (
    SELECT * FROM coupling_searches
) cs ON cs.filing = r.filing
LEFT JOIN ( SELECT DISTINCT borne_by, from_layer, observed_in FROM (
    SELECT * FROM spillovers
) x ) sp ON sp.borne_by = r.filing AND sp.from_layer = r.layer

),
compose_edges AS MATERIALIZED (
    -- public.compose_edge, generated by examples/compositions/main.rs from assets/sqlc/.
SELECT e.parent, e.child, e.splices, e.inner_joins
FROM public.compose_edge e

),
compose_measures AS MATERIALIZED (
    -- rank/compose_edges.sqlc, symmetrised and walked for components, counted whole and by directory.
WITH RECURSIVE
edge AS (
    SELECT DISTINCT e.parent AS a, e.child AS b
    FROM ( SELECT * FROM compose_edges ) e
),
node AS (
    SELECT a AS name FROM edge UNION SELECT b FROM edge
),
placed AS (
    SELECT n.name,
           CASE WHEN position('/' IN n.name) > 0 THEN split_part(n.name, '/', 1) ELSE '(root)' END
             AS directory
    FROM node n
),
scoped_node AS (
    SELECT NULL::text AS scope, p.name FROM placed p
  UNION ALL
    SELECT p.directory, p.name FROM placed p
),
scoped_edge AS (
    SELECT NULL::text AS scope, e.a, e.b FROM edge e
  UNION ALL
    SELECT pa.directory, e.a, e.b
    FROM edge e
    JOIN placed pa ON pa.name = e.a
    JOIN placed pb ON pb.name = e.b AND pb.directory = pa.directory
),
sym AS (
    SELECT scope, a, b FROM scoped_edge
  UNION
    SELECT scope, b, a FROM scoped_edge
),
reach(scope, root, at) AS (
      SELECT s.scope, s.name, s.name FROM scoped_node s
    UNION
      SELECT r.scope, r.root, y.b
      FROM reach r JOIN sym y ON y.scope IS NOT DISTINCT FROM r.scope AND y.a = r.at
),
comp AS (SELECT scope, root, min(at) AS component FROM reach GROUP BY scope, root)
SELECT n.scope,
       count(DISTINCT n.name)                                              AS n_nodes,
       (SELECT count(*) FROM scoped_edge w
         WHERE w.scope IS NOT DISTINCT FROM n.scope)                       AS m_edges,
       count(DISTINCT c.component)                                         AS c_components,
       count(DISTINCT n.name) - count(DISTINCT c.component)                AS rank_of_incidence,
       (SELECT count(*) FROM scoped_edge w
         WHERE w.scope IS NOT DISTINCT FROM n.scope)
         - count(DISTINCT n.name) + count(DISTINCT c.component)            AS cycle_space_dim
FROM      scoped_node n
JOIN      comp c ON c.scope IS NOT DISTINCT FROM n.scope AND c.root = n.name
GROUP BY  n.scope

),
graph_edges AS MATERIALIZED (
    -- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
FROM (
    SELECT * FROM parts
) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    SELECT * FROM conversions
) c

),
fit_coverage AS MATERIALIZED (
    -- checks/fit_domain.sqlc against checks/fit_cells.sqlc.
SELECT d.slug, a.axis, d.fit, d.standing, d.reason, count(o.layer) AS examined
FROM      (
    SELECT * FROM fit_domain
) d
JOIN      (
    SELECT * FROM fit_axes
) a ON a.slug = d.slug
LEFT JOIN (
    -- checks/all.sqlc per checks/fit_axes.sqlc against layers/filed_remainders.sqlc and layers/remainder.sqlc.
SELECT a.slug, a.axis, c.filing, c.layer,
       CASE WHEN a.axis = 'filed sign' THEN f.sign ELSE x.derived_fit END AS fit
FROM      (
    SELECT * FROM checks_all
) c
JOIN      (
    SELECT * FROM checks_roster
) r ON r.rule = c.rule
JOIN      (
    SELECT * FROM fit_axes
) a ON a.slug = r.slug
LEFT JOIN (
    SELECT * FROM filed_remainders
) f ON f.filing = c.filing AND f.layer = c.layer
LEFT JOIN (
    SELECT * FROM remainder
) x ON x.filing = c.filing AND x.layer = c.layer
WHERE c.violates IS NOT NULL
  AND a.axis <> 'not read'

) o ON o.slug = d.slug AND o.fit IS NOT DISTINCT FROM d.fit
GROUP BY d.slug, a.axis, d.fit, d.standing, d.reason

),
graph_measures AS MATERIALIZED (
    -- rank/graph_edges.sqlc, symmetrised and walked for components, counted at both scopes.
WITH RECURSIVE
edges AS (
    SELECT DISTINCT g.graph, g.filing, g.from_node AS a, g.to_node AS b
    FROM ( SELECT * FROM graph_edges ) g
),
scoped AS (
    SELECT DISTINCT graph, NULL::text AS filing, a, b FROM edges
  UNION ALL
    SELECT graph, filing, a, b FROM edges
),
nodes AS (SELECT graph, filing, a AS u FROM scoped UNION SELECT graph, filing, b FROM scoped),
sym   AS (SELECT graph, filing, a, b FROM scoped UNION SELECT graph, filing, b, a FROM scoped),
reach(graph, filing, root, at) AS (
      SELECT graph, filing, u, u FROM nodes
    UNION
      SELECT r.graph, r.filing, r.root, s.b
      FROM reach r JOIN sym s ON s.graph = r.graph AND s.filing IS NOT DISTINCT FROM r.filing
                              AND s.a = r.at
),
comp AS (SELECT graph, filing, root, min(at) AS component FROM reach GROUP BY graph, filing, root)
SELECT n.graph, n.filing,
       count(DISTINCT n.u)                                         AS n_nodes,
       (SELECT count(*) FROM scoped w
         WHERE w.graph = n.graph AND w.filing IS NOT DISTINCT FROM n.filing) AS m_edges,
       count(DISTINCT c.component)                                 AS c_components,
       (SELECT count(*) FROM scoped w
         WHERE w.graph = n.graph AND w.filing IS NOT DISTINCT FROM n.filing)
         - count(DISTINCT n.u) + count(DISTINCT c.component)       AS cycle_space_dim,
       count(DISTINCT n.u) - count(DISTINCT c.component)           AS rank_of_incidence
FROM nodes n
JOIN comp c ON c.graph = n.graph AND c.filing IS NOT DISTINCT FROM n.filing AND c.root = n.u
GROUP BY n.graph, n.filing

),
composition_kernel AS MATERIALIZED (
    -- asrt:Fusion/asrt:Part folded onto its fusion: the fibre size, and the block dimension it fixes.
SELECT p.composition,
       p.composed_layer,
       count(*)     AS parts,
       count(*) - 1 AS kernel_dim
FROM (
    SELECT * FROM parts
) p
GROUP BY p.composition, p.composed_layer

),
composition_image AS MATERIALIZED (
    -- composition/fusions.sqlc against the fusions that are a row of F Phi.
SELECT f.filing                                         AS composition,
       count(*)                                         AS declared,
       count(k.composition)                             AS rank,
       count(*) - count(k.composition)                  AS left_null
FROM      (
    SELECT * FROM fusions
) f
LEFT JOIN (
    SELECT * FROM composition_kernel
) k ON k.composition = f.filing AND k.composed_layer = f.layer
GROUP BY f.filing

),
algebra_all AS MATERIALIZED (
    -- algebra/roster.sqlc joined to each law's own subjects.
-- algebra/roster.sqlc against public.compose_edge: who composes the layer dimension.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/every_layer.sqlc' AS subject,
           count(*) = 0              AS holds,
           format('%s undeclared parent(s) compose the layer dimension: %s',
                  count(*), coalesce(string_agg(u.parent, ', ' ORDER BY u.parent), '(none)'))
                                     AS detail
    FROM (
        SELECT e.parent
        FROM ( SELECT * FROM compose_edges ) e
        WHERE e.child = 'layers/every_layer.sqlc'
          AND e.inner_joins > 0
          AND e.parent NOT IN ('entries/spillovers.sqlc')
    ) u
) p ON true
WHERE a.slug = 'dimension_use'
UNION ALL
-- algebra/roster.sqlc against rank/compose_measures.sqlc: the directory cut is a partition.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/compose_decomposition' AS subject,
           x.whole_nodes = x.cut_nodes
             AND x.whole_edges = x.cut_edges + x.crossing                            AS holds,
           format('%s templates whole = %s summed over %s directories; %s edges = %s kept + %s crossing',
                  x.whole_nodes, x.cut_nodes, x.directories,
                  x.whole_edges, x.cut_edges, x.crossing)                            AS detail
    FROM ( SELECT
             (SELECT m.n_nodes FROM ( SELECT * FROM compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_nodes,
             (SELECT coalesce(sum(m.n_nodes), 0) FROM ( SELECT * FROM compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_nodes,
             (SELECT m.m_edges FROM ( SELECT * FROM compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_edges,
             (SELECT coalesce(sum(m.m_edges), 0) FROM ( SELECT * FROM compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_edges,
             (SELECT count(*) FROM ( SELECT * FROM compose_edges ) e
               WHERE (CASE WHEN position('/' IN e.parent) > 0
                           THEN split_part(e.parent, '/', 1) ELSE '(root)' END)
                  <> (CASE WHEN position('/' IN e.child) > 0
                           THEN split_part(e.child, '/', 1) ELSE '(root)' END))       AS crossing,
             (SELECT count(*) FROM ( SELECT * FROM compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS directories
         ) x
) p ON true
WHERE a.slug = 'compose_decomposition'
UNION ALL
-- rank/decomposition.sqlc's two scopes, counted: the whole against the sum of the parts.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/decomposition' AS subject,
           x.whole = x.per_filing AS holds,
           format('%s edges corpus-wide = %s summed over %s filings, across %s graphs',
                  x.whole, x.per_filing, x.filings, x.graphs) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.from_node, g.to_node
                 FROM ( SELECT * FROM graph_edges ) g) e)                      AS whole,
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.filing, g.from_node, g.to_node
                 FROM ( SELECT * FROM graph_edges ) g) e)                      AS per_filing,
             (SELECT count(DISTINCT g.filing)
              FROM ( SELECT * FROM graph_edges ) g)                            AS filings,
             (SELECT count(DISTINCT g.graph)
              FROM ( SELECT * FROM graph_edges ) g)                            AS graphs
         ) x
) p ON true
WHERE a.slug = 'decomposition'
UNION ALL
-- rank/graph_measures.sqlc's layer row at the corpus scope against checks/jagged_layer.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/cycle_space' AS subject,
           x.nodes > 0 AND x.edges > 0 AND x.examined > 0
           AND (x.dim = 0) = (x.violations = 0)                                      AS holds,
           format('dim %s over %s node(s), %s edge(s), %s component(s); %s of %s fusion(s) '
                  'examined violate the partition',
                  x.dim, x.nodes, x.edges, x.components, x.violations, x.examined)   AS detail
    FROM (
        SELECT m.cycle_space_dim AS dim, m.n_nodes AS nodes, m.m_edges AS edges,
               m.c_components AS components, j.violations, j.examined
        FROM      (
            SELECT * FROM graph_measures
        ) m
        CROSS JOIN (
            SELECT count(*) FILTER (WHERE k.violates)             AS violations,
                   count(*) FILTER (WHERE k.violates IS NOT NULL) AS examined
            FROM ( SELECT * FROM jagged_layer ) k
        ) j
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'cycle_space'
UNION ALL
-- rank/composition_kernel.sqlc folded, against rank/graph_measures.sqlc's layer row.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/composition_kernel' AS subject,
           x.parts > 0 AND x.fusions > 0 AND x.edges > 0
           AND x.parts = x.edges
           AND x.kernel = x.edges - x.fusions                                        AS holds,
           format('dim ker %s over %s part(s) in %s fusion(s); the layer graph has %s edge(s), '
                  '%s node(s), %s component(s) and cycle space %s',
                  x.kernel, x.parts, x.fusions, x.edges,
                  x.nodes, x.components, x.dim)                                      AS detail
    FROM (
        SELECT k.parts, k.fusions, k.kernel,
               m.m_edges AS edges, m.n_nodes AS nodes,
               m.c_components AS components, m.cycle_space_dim AS dim
        FROM      (
            SELECT coalesce(sum(c.parts), 0)      AS parts,
                   count(*)                       AS fusions,
                   coalesce(sum(c.kernel_dim), 0) AS kernel
            FROM ( SELECT * FROM composition_kernel ) c
        ) k
        CROSS JOIN (
            SELECT * FROM graph_measures
        ) m
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'composition_kernel'
UNION ALL
-- rank/composition_row_space.sqlc against rank/composition_kernel.sqlc, then against rank/composition_image.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/composition_row_space' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE x.kernel_dim > 0) > 0
           AND count(*) FILTER (WHERE x.row_dim <> 1) = 0
           AND count(*) FILTER (WHERE x.row_dim + x.kernel_dim <> x.parts) = 0
           AND count(*) FILTER (WHERE x.kernel_dim IS DISTINCT FROM x.kernel_by_fold) = 0
           AND count(*) FILTER (WHERE x.parts IS DISTINCT FROM x.parts_by_fold) = 0     AS holds,
           format('%s fusion(s), %s with a null space; %s report a row space other than one '
                  'dimension, %s do not sum to their own part count, %s disagree with the fold%s',
                  count(*), count(*) FILTER (WHERE x.kernel_dim > 0),
                  count(*) FILTER (WHERE x.row_dim <> 1),
                  count(*) FILTER (WHERE x.row_dim + x.kernel_dim <> x.parts),
                  count(*) FILTER (WHERE x.kernel_dim IS DISTINCT FROM x.kernel_by_fold
                                         OR x.parts IS DISTINCT FROM x.parts_by_fold),
                  coalesce(': ' || string_agg(x.composition || '/' || x.composed_layer, ', '
                                              ORDER BY x.composition, x.composed_layer)
                                   FILTER (WHERE x.row_dim <> 1
                                                 OR x.row_dim + x.kernel_dim <> x.parts
                                                 OR x.kernel_dim IS DISTINCT FROM x.kernel_by_fold
                                                 OR x.parts IS DISTINCT FROM x.parts_by_fold), ''))
                                                                                     AS detail
    FROM (
        SELECT r.composition, r.composed_layer, r.parts, r.row_dim, r.kernel_dim,
               k.parts      AS parts_by_fold,
               k.kernel_dim AS kernel_by_fold
        FROM      (
            -- asrt:Fusion/asrt:Part folded onto its fusion: the fibre's generator, and what it is known to.
SELECT p.composition,
       p.composed_layer,
       count(*)                                                             AS parts,
       1::bigint                                                            AS row_dim,
       count(*) - 1                                                         AS kernel_dim,
       count(*) FILTER (WHERE p.factor_state = 'stated')                    AS factors_stated,
       count(*) FILTER (WHERE p.factor_state = 'omitted')                   AS factors_one,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation'))   AS factors_unknown,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation')) = 0
                                                                            AS direction_known
FROM (
    SELECT * FROM parts
) p
GROUP BY p.composition, p.composed_layer

        ) r
        LEFT JOIN (
            SELECT * FROM composition_kernel
        ) k ON k.composition = r.composition AND k.composed_layer = r.composed_layer
    ) x
    UNION ALL
    SELECT 'rank/composition_row_space / the rank',
           y.blocks > 0 AND z.matrix_rows > 0 AND y.blocks = z.matrix_rows
           AND y.parts = y.blocks + y.kernel                                         AS holds,
           format('rank %s summed over the part-side blocks and %s counted as fusion rows; '
                  '%s part(s) over %s block(s) leaves %s dimension(s) of null space',
                  y.blocks, z.matrix_rows, y.parts, y.blocks, y.kernel)
    FROM       (
        SELECT coalesce(sum(s.row_dim),    0) AS blocks,
               coalesce(sum(s.parts),      0) AS parts,
               coalesce(sum(s.kernel_dim), 0) AS kernel
        FROM (
            -- asrt:Fusion/asrt:Part folded onto its fusion: the fibre's generator, and what it is known to.
SELECT p.composition,
       p.composed_layer,
       count(*)                                                             AS parts,
       1::bigint                                                            AS row_dim,
       count(*) - 1                                                         AS kernel_dim,
       count(*) FILTER (WHERE p.factor_state = 'stated')                    AS factors_stated,
       count(*) FILTER (WHERE p.factor_state = 'omitted')                   AS factors_one,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation'))   AS factors_unknown,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation')) = 0
                                                                            AS direction_known
FROM (
    SELECT * FROM parts
) p
GROUP BY p.composition, p.composed_layer

        ) s
    ) y
    CROSS JOIN (
        SELECT coalesce(sum(i.rank), 0) AS matrix_rows
        FROM (
            SELECT * FROM composition_image
        ) i
    ) z
) p ON true
WHERE a.slug = 'composition_row_space'
UNION ALL
-- rank/composition_image.sqlc, then the compositions carrying a dimension against checks/unresolved_part.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/composition_image' AS subject,
           count(*) > 0 AND sum(i.declared) > 0
           AND count(*) FILTER (WHERE i.declared <> i.rank + i.left_null) = 0
           AND sum(i.left_null) = 0                                                  AS holds,
           format('%s composition(s), %s declared fusion(s), rank %s, left null %s%s',
                  count(*), sum(i.declared), sum(i.rank), sum(i.left_null),
                  coalesce(': ' || string_agg(i.composition, ', ' ORDER BY i.composition)
                                   FILTER (WHERE i.left_null > 0), ''))              AS detail
    FROM (
        SELECT * FROM composition_image
    ) i
    UNION ALL
    SELECT 'rank/composition_image / the rule',
           count(*) FILTER (WHERE x.examined > 0) > 0
           AND count(*) FILTER (WHERE x.left_null > 0 AND x.accused = 0) = 0         AS holds,
           format('%s composition(s) carry a dimension, %s of those have no part accused; '
                  '%s part reference(s) examined, %s accused%s',
                  count(*) FILTER (WHERE x.left_null > 0),
                  count(*) FILTER (WHERE x.left_null > 0 AND x.accused = 0),
                  sum(x.examined), sum(x.accused),
                  coalesce(': ' || string_agg(x.composition, ', ' ORDER BY x.composition)
                                   FILTER (WHERE x.left_null > 0 AND x.accused = 0), ''))
    FROM (
        SELECT i.composition, i.left_null,
               count(u.filing) FILTER (WHERE u.violates)             AS accused,
               count(u.filing) FILTER (WHERE u.violates IS NOT NULL) AS examined
        FROM      (
            SELECT * FROM composition_image
        ) i
        LEFT JOIN (
            SELECT * FROM unresolved_part
        ) u ON u.filing = i.composition
        GROUP BY i.composition, i.left_null
    ) x
) p ON true
WHERE a.slug = 'composition_image'
UNION ALL
-- rank/composition_closure.sqlc: the composite's dimension against the sum of its levels'.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/composition_closure' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE c.deepest >= 2) > 0
           AND count(*) FILTER (WHERE c.closure_kernel <> c.sum_kernel) = 0
           AND count(*) FILTER (WHERE c.row_dim <> 1) = 0
           AND count(*) FILTER (WHERE c.leaves_positive + c.leaves_unknown <> c.leaves) = 0
                                                                                     AS holds,
           format('%s root(s), %s reaching two levels or more; %s disagree between the '
                  'composite dimension and the sum of its blocks, %s have a leaf whose path '
                  'product is neither positive nor unstated, %s leaf arrival(s) unstated%s',
                  count(*), count(*) FILTER (WHERE c.deepest >= 2),
                  count(*) FILTER (WHERE c.closure_kernel <> c.sum_kernel),
                  count(*) FILTER (WHERE c.leaves_positive + c.leaves_unknown <> c.leaves),
                  coalesce(sum(c.leaves_unknown), 0),
                  coalesce(': ' || string_agg(format('%s/%s wants %s and sums to %s',
                                                     c.composition, c.composed_layer,
                                                     c.closure_kernel, c.sum_kernel),
                                              ', ' ORDER BY c.composition, c.composed_layer)
                                   FILTER (WHERE c.closure_kernel <> c.sum_kernel), ''))
                                                                                     AS detail
    FROM (
        -- composition/descent.sqlc reduced to one row per reached layer, against rank/composition_kernel.sqlc.
SELECT r.composition,
       r.composed_layer,
       coalesce(b.deepest, 0)                             AS deepest,
       1 + coalesce(b.fusions, 0)                         AS fusions_below,
       coalesce(b.leaves, 0)                              AS leaves,
       1::bigint                                          AS row_dim,
       coalesce(b.leaves, 0) - 1                          AS closure_kernel,
       r.kernel_dim + coalesce(b.kernel, 0)               AS sum_kernel,
       coalesce(b.leaves_positive, 0)                     AS leaves_positive,
       coalesce(b.leaves_unknown, 0)                      AS leaves_unknown
FROM      (
    SELECT * FROM composition_kernel
) r
LEFT JOIN (
    SELECT w.root_filing,
           w.root_layer,
           max(w.depth)::bigint                                  AS deepest,
           count(*) FILTER (WHERE k.composition IS NOT NULL)      AS fusions,
           count(*) FILTER (WHERE k.composition IS NULL)          AS leaves,
           count(*) FILTER (WHERE k.composition IS NULL
                                  AND NOT w.factor_absent
                                  AND w.factor_mode > 0)          AS leaves_positive,
           count(*) FILTER (WHERE k.composition IS NULL
                                  AND w.factor_absent)            AS leaves_unknown,
           coalesce(sum(k.kernel_dim), 0)::bigint                 AS kernel
    FROM      (
        SELECT d.root_filing, d.root_layer, d.filing, d.layer,
               max(d.depth)             AS depth,
               bool_or(d.factor_absent) AS factor_absent,
               min(d.factor_mode)       AS factor_mode
        FROM (
            SELECT * FROM descent
        ) d
        GROUP BY d.root_filing, d.root_layer, d.filing, d.layer
    ) w
    LEFT JOIN (
        SELECT * FROM composition_kernel
    ) k ON k.composition = w.filing AND k.composed_layer = w.layer
    GROUP BY w.root_filing, w.root_layer
) b ON b.root_filing = r.composition AND b.root_layer = r.composed_layer

    ) c
) p ON true
WHERE a.slug = 'composition_closure'
UNION ALL
-- layers/quantities.sqlc folded to one row per layer: how many units its quantities name.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/quantities' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE x.units > 0) > 0
           AND count(*) FILTER (WHERE x.units > 1) = 0                               AS holds,
           format('%s layer(s) file a quantity, %s state a unit, %s state more than one%s',
                  count(*), count(*) FILTER (WHERE x.units > 0),
                  count(*) FILTER (WHERE x.units > 1),
                  coalesce(': ' || string_agg(x.filing || '/' || x.layer, ', '
                                              ORDER BY x.filing, x.layer)
                                   FILTER (WHERE x.units > 1), ''))                  AS detail
    FROM (
        SELECT q.filing, q.layer, count(DISTINCT q.unit) AS units
        FROM      (
            SELECT * FROM quantities
        ) q
        GROUP BY q.filing, q.layer
    ) x
    UNION ALL
    SELECT 'composition/part_quantities',
           count(*) > 0
           AND count(*) FILTER (WHERE y.stated) > 0
           AND count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin) = 0            AS holds,
           format('%s part(s), %s with a stated factor, %s of those file no nameplate%s',
                  count(*), count(*) FILTER (WHERE y.stated),
                  count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin),
                  coalesce(': ' || string_agg(y.composition || '/' || y.part_layer, ', '
                                              ORDER BY y.composition, y.part_layer)
                                   FILTER (WHERE y.stated AND NOT y.at_the_pin), ''))
    FROM (
        SELECT r.composition, r.composed_layer, r.part_filing, r.part_layer,
               bool_or(r.factor_state = 'stated')  AS stated,
               bool_or(r.quantity = 'nameplate')   AS at_the_pin
        FROM      (
            SELECT * FROM part_quantities
        ) r
        GROUP BY r.composition, r.composed_layer, r.part_filing, r.part_layer
    ) y
) p ON true
WHERE a.slug = 'layer_units'
UNION ALL
-- composition/fusions.sqlc for every quantity, partitioned by composition/suspended_quantities.sqlc and composition/derived_fusions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/owed_equality' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s fusion quantities = %s owing + %s suspended or derived', x.total, x.kept,
                  x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM owed_equality ) o)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE EXISTS (SELECT 1
                             FROM ( SELECT s.composition AS filing, s.composed_layer AS layer,
                                           s.quantity
                                    FROM ( SELECT * FROM suspended_quantities ) s
                                    UNION ALL
                                    SELECT d.filing, d.layer, d.quantity
                                    FROM ( SELECT * FROM derived_fusions ) d ) b
                             WHERE b.filing = f.filing AND b.layer = f.layer
                               AND b.quantity = q.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'owed_equality'
UNION ALL
-- composition/descent.sqlc partitioned by composition/fusions.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/leaves' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s descent rows = %s leaves + %s that name parts (over %s distinct keys)',
                  x.total, x.kept, x.removed, x.keys) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM descent ) d)  AS total,
             (SELECT count(DISTINCT (d.filing, d.layer)) FROM ( SELECT * FROM descent ) d) AS keys,
             (SELECT count(*) FROM ( -- asrt:Part followed to a layer that names no parts of its own.
SELECT d.*
FROM      (
    SELECT * FROM descent
) d
LEFT JOIN (
    SELECT * FROM fusions
) f
       ON f.filing = d.filing AND f.layer = d.layer
WHERE f.filing IS NULL
 ) l)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM descent ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM fusions ) f
                              WHERE f.filing = d.filing AND f.layer = d.layer)) AS removed
         ) x
) p ON true
WHERE a.slug = 'leaves'
UNION ALL
-- composition/jagged_layers.sqlc partitioned by eliminations/filed.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/jagged_layers' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s jagged rows = %s nobody admitted + %s on a fusion that filed one', 
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM jagged_layers ) j) AS total,
             (SELECT count(*) FROM ( SELECT * FROM jagged_layers ) j
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM filed ) e
                                  WHERE e.composition = j.filing
                                    AND e.composed_layer = j.layer))            AS kept,
             (SELECT count(*) FROM ( SELECT * FROM jagged_layers ) j
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM filed ) e
                              WHERE e.composition = j.filing
                                AND e.composed_layer = j.layer))                AS removed
         ) x
) p ON true
WHERE a.slug = 'jagged_layers'
UNION ALL
-- layers/summed_quantities.sqlc partitioned by the query the roster names as this law's subject.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'queries/matrices/3b-composed-quantities' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s stated figures = %s carried + %s suspended', x.total, x.kept, x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM summed_quantities ) d
               WHERE d.low IS NOT NULL)                                              AS total,
             (SELECT count(*) FROM ( -- §3  What each layer actually filed, per quantity, and the elimination to subtract from it.
-- layers/summed_quantities.sqlc minus composition/suspended_quantities.sqlc, with eliminations/filed.sqlc.
SELECT d.filing                     AS "filing!",
       d.layer                      AS "layer!",
       d.quantity::text             AS "quantity!",
       d.low::float8                AS "x_low!",
       d.mode::float8               AS "x_mode!",
       d.high::float8               AS "x_high!",
       coalesce(e.low, 0)::float8   AS "e_low!",
       coalesce(e.mode, 0)::float8  AS "e_mode!",
       coalesce(e.high, 0)::float8  AS "e_high!"
FROM      (
    SELECT * FROM summed_quantities
) d
LEFT JOIN (
    SELECT * FROM suspended_quantities
) s
       ON s.composition = d.filing AND s.composed_layer = d.layer
      AND s.quantity = d.quantity
LEFT JOIN (
    SELECT * FROM filed
) e
       ON e.composition = d.filing AND e.composed_layer = d.layer
      AND e.quantity = d.quantity
WHERE s.composition IS NULL
  AND d.low IS NOT NULL
 ) k)
                                                                                     AS kept,
             (SELECT count(*) FROM ( SELECT * FROM summed_quantities ) d
               WHERE d.low IS NOT NULL
                 AND EXISTS (SELECT 1 FROM ( SELECT * FROM suspended_quantities ) s
                              WHERE s.composition = d.filing AND s.composed_layer = d.layer
                                AND s.quantity = d.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'composed_quantities'
UNION ALL
-- every fold in folds/ whose population does not reach algebra/all.sqlc, against its roster and its population by EXCEPT.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.roster = x.missing + x.produced
             AND x.declared = x.roster
             AND x.unproduced = x.missing
             AND x.undeclared = x.stray AS holds,
           format('%s declared = %s unproduced + %s produced, %s undeclared; by EXCEPT, %s on the roster, %s unproduced, %s undeclared',
                  x.declared, x.unproduced, x.produced, x.undeclared, x.roster, x.missing, x.stray) AS detail
    FROM (
        SELECT 'rules' AS contract,
               (SELECT count(DISTINCT r.rule) FROM ( SELECT * FROM checks_roster ) r) AS roster,
               (SELECT count(*) FROM ( SELECT r.rule FROM ( SELECT * FROM checks_roster ) r
                                       EXCEPT
                                       SELECT c.rule FROM ( SELECT * FROM checks_all ) c ) x) AS missing,
               (SELECT count(*) FROM ( SELECT c.rule FROM ( SELECT * FROM checks_all ) c
                                       EXCEPT
                                       SELECT r.rule FROM ( SELECT * FROM checks_roster ) r ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic',
               (SELECT count(DISTINCT a.site) FROM ( SELECT * FROM arithmetic_roster ) a) AS roster,
               (SELECT count(*) FROM ( SELECT a.site FROM ( SELECT * FROM arithmetic_roster ) a
                                       EXCEPT
                                       SELECT z.site FROM ( SELECT * FROM arithmetic_all ) z ) x) AS missing,
               (SELECT count(*) FROM ( SELECT z.site FROM ( SELECT * FROM arithmetic_all ) z
                                       EXCEPT
                                       SELECT a.site FROM ( SELECT * FROM arithmetic_roster ) a ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams',
               (SELECT count(DISTINCT d.object) FROM ( SELECT * FROM domain_objects ) d) AS roster,
               (SELECT count(*) FROM ( SELECT d.object FROM ( SELECT * FROM domain_objects ) d
                                       EXCEPT
                                       SELECT k.object FROM ( SELECT * FROM catalogue ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.object FROM ( SELECT * FROM catalogue ) k
                                       EXCEPT
                                       SELECT d.object FROM ( SELECT * FROM domain_objects ) d ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws',
               (SELECT count(DISTINCT l.slug) FROM ( SELECT * FROM diagrams_roster ) l) AS roster,
               (SELECT count(*) FROM ( SELECT l.slug FROM ( SELECT * FROM diagrams_roster ) l
                                       EXCEPT
                                       SELECT e.slug FROM ( SELECT * FROM expected ) e ) x) AS missing,
               (SELECT count(*) FROM ( SELECT e.slug FROM ( SELECT * FROM expected ) e
                                       EXCEPT
                                       SELECT l.slug FROM ( SELECT * FROM diagrams_roster ) l ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences',
               (SELECT count(DISTINCT q.table_name || '.' || q.column_name) FROM ( SELECT * FROM absence_questions ) q) AS roster,
               (SELECT count(*) FROM ( SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM absence_questions ) q
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM absence_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM absence_columns ) k
                                       EXCEPT
                                       SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM absence_questions ) q ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations',
               (SELECT count(DISTINCT i.table_name || '.' || i.column_name) FROM ( SELECT * FROM identities_roster ) i) AS roster,
               (SELECT count(*) FROM ( SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities_roster ) i
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM derivation_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM derivation_columns ) k
                                       EXCEPT
                                       SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities_roster ) i ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'integrity'
UNION ALL
-- composition/carriable.sqlc partitioned by eliminations/filed.sqlc and composition/suspended_quantities.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/carried' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s carriable = %s carried + %s eliminated or suspended',
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM carriable ) c) AS total,
             (SELECT count(*) FROM ( SELECT * FROM carried ) k)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM carriable ) c
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM filed ) e
                              WHERE e.composition = c.filing AND e.composed_layer = c.layer)
                  OR EXISTS (SELECT 1 FROM ( SELECT * FROM suspended_quantities ) s
                              WHERE s.composition = c.filing AND s.composed_layer = c.layer
                                AND s.quantity::text = c.quantity::text)) AS removed
         ) x
) p ON true
WHERE a.slug = 'carried'
UNION ALL
-- composition/fusions.sqlc partitioned by composition/suspended_remainders.sqlc, bounded by
-- composition/owed_equality.sqlc and composition/derived_fusions.sqlc on the demand.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/owed_remainder' AS subject,
           x.total = x.kept + x.removed AND x.kept <= x.demand_owed + x.demand_derived AS holds,
           format('%s fusions = %s owing a remainder + %s suspended; %s owe a demand sum and %s file it derived',
                  x.total, x.kept, x.removed, x.demand_owed, x.demand_derived) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f)        AS total,
             (SELECT count(*) FROM ( SELECT * FROM owed_remainder ) o) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM suspended_remainders ) s
                              WHERE s.composition = f.filing AND s.composed_layer = f.layer)) AS removed,
             (SELECT count(*) FROM ( SELECT * FROM owed_equality ) o
               WHERE o.quantity = 'demand')                                          AS demand_owed,
             (SELECT count(*) FROM ( SELECT * FROM derived_fusions ) d
               WHERE d.quantity = 'demand')                                          AS demand_derived
         ) x
) p ON true
WHERE a.slug = 'owed_remainder'
UNION ALL
-- composition/remainder_frontier.sqlc partitioned into composition/settled_remainders.sqlc, composition/passed_nodes.sqlc and the stops layers/differenced_remainder.sqlc has no row for,
-- the figureless stops held to composition/suspended_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    WITH stops AS (
        SELECT w.root_filing, w.root_layer
        FROM ( SELECT * FROM remainder_frontier ) w
        WHERE w.usable
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM unsettled ) o
                          WHERE o.filing = w.filing AND o.layer = w.layer)
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM differenced_remainder ) r
                          WHERE r.filing = w.filing AND r.layer = w.layer)
    ),
    x AS (
        SELECT
          (SELECT count(*) FROM ( SELECT * FROM remainder_frontier ) w
            WHERE w.usable)                                                          AS total,
          (SELECT count(*) FROM ( SELECT * FROM settled_remainders ) s) AS kept,
          (SELECT count(*) FROM ( SELECT * FROM passed_nodes ) w
            WHERE w.usable)                                                          AS removed,
          (SELECT count(*) FROM stops)                                               AS figureless,
          (SELECT string_agg(DISTINCT s.root_filing || ' / ' || s.root_layer, ', ')
           FROM stops s
           WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM suspended_remainders ) l
                             WHERE l.composition = s.root_filing
                               AND l.composed_layer = s.root_layer))                 AS unlifted
    )
    SELECT 'composition/settled_remainders' AS subject,
           x.total = x.kept + x.removed + x.figureless AND x.unlifted IS NULL AS holds,
           format('%s frontier rows = %s settled + %s walked through + %s stopped with no figure%s',
                  x.total, x.kept, x.removed, x.figureless,
                  CASE WHEN x.unlifted IS NOT NULL
                       THEN format('; owed although a node it reaches has none: %s', x.unlifted) END)
               AS detail
    FROM x
) p ON true
WHERE a.slug = 'settled_remainders'
UNION ALL
-- entries/served_holders.sqlc and entries/unserved_holders.sqlc against pm:Remainder/pm:holder.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.held - x.served - x.unserved) < 1e-9 AS holds,
           format('%s held = %s absorbed + %s unserved', x.held, x.served, x.unserved) AS detail
    FROM (
        SELECT h.filing, h.layer,
               sum(h.share_mode)                                            AS held,
               coalesce((SELECT sum(v.share_mode) FROM (
                   SELECT * FROM served_holders
               ) v WHERE v.filing = h.filing AND v.layer = h.layer), 0)      AS served,
               coalesce((SELECT sum(u.share_mode) FROM (
                   SELECT * FROM unserved_holders
               ) u WHERE u.filing = h.filing AND u.layer = h.layer), 0)      AS unserved
        FROM (
            SELECT * FROM holders
        ) h
        WHERE h.share_mode IS NOT NULL
        GROUP BY h.filing, h.layer
    ) x
) p ON true
WHERE a.slug = 'borne'
UNION ALL
-- arithmetic/all.sqlc, one candidate to exactly one verdict.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT z.site AS subject,
           count(*) FILTER (WHERE z.classes <> 1) = 0 AS holds,
           format('%s candidates, %s in exactly one class', count(*),
                  count(*) FILTER (WHERE z.classes = 1)) AS detail
    FROM ( SELECT site, filing, layer,
                  count(*) FILTER (WHERE w.verdict IS NOT NULL) AS classes
           FROM ( SELECT * FROM arithmetic_all ) w
           GROUP BY site, filing, layer ) z
    GROUP BY z.site
) p ON true
WHERE a.slug = 'arithmetic_class'
UNION ALL
-- layers/remainder.sqlc against layers/remainder_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/remainder_scope' AS subject,
           x.computable = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s computable remainders, %s classified, %s classified twice, %s with no standing',
                  x.computable, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM remainder ) r)       AS computable,
             (SELECT count(*) FROM ( SELECT * FROM remainder_scope ) z) AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer FROM ( SELECT * FROM remainder_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM remainder_scope ) z
               WHERE z.standing IS NULL)                                             AS unclassified
         ) x
) p ON true
WHERE a.slug = 'remainder_standing'
UNION ALL
-- layers/remainder.sqlc where exposure > 0, against layers/exposure_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/exposure_scope' AS subject,
           x.exposed = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s exposed layers, %s classified, %s classified twice, %s with no standing',
                  x.exposed, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM remainder ) r
               WHERE r.exposure > 1e-9)                                          AS exposed,
             (SELECT count(*) FROM ( SELECT * FROM exposure_scope ) z)   AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer
                                     FROM ( SELECT * FROM exposure_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM exposure_scope ) z
               WHERE z.standing IS NULL)                                         AS unclassified
         ) x
) p ON true
WHERE a.slug = 'exposure_standing'
UNION ALL
-- epistemics/searches.sqlc against the two relations it unions.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'epistemics/searches' AS subject,
           x.whole = x.couplings + x.eliminations AS holds,
           format('%s searches = %s coupling + %s double-counting',
                  x.whole, x.couplings, x.eliminations) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM epistemics_searches ) s)              AS whole,
             (SELECT count(*) FROM ( SELECT * FROM coupling_searches ) c)     AS couplings,
             (SELECT count(*) FROM ( SELECT * FROM searched ) e)  AS eliminations
         ) x
) p ON true
WHERE a.slug = 'searches'
UNION ALL
-- composition/part_regimes.sqlc partitioned by whether both sides state a framework.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/part_regimes' AS subject,
           x.total = x.askable + x.unaskable AS holds,
           format('%s parts with a regime handle = %s askable + %s where a typed absence or an unstated filing makes the question not arise',
                  x.total, x.askable, x.unaskable) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM part_regimes ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM part_regimes ) r
               WHERE r.composer_absent IS NULL AND r.frameworks_the_filing_states > 0) AS askable,
             (SELECT count(*) FROM ( SELECT * FROM part_regimes ) r
               WHERE r.composer_absent IS NOT NULL OR r.frameworks_the_filing_states = 0) AS unaskable
         ) x
) p ON true
WHERE a.slug = 'part_regimes'
UNION ALL
-- layers/remainder.sqlc against layers/demand.sqlc and layers/nameplate.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           (r.pivoted OR (r.r_low  = n.n_low  - d.d_high
                      AND r.r_mode = n.n_mode - d.d_mode
                      AND r.r_high = n.n_high - d.d_low))
           AND r.r_low <= r.r_mode AND r.r_mode <= r.r_high
           AND (r.derived_fit = 'clearance')    = (r.r_low >= 0)
           AND (r.derived_fit = 'interference') = (r.r_high <= 0 AND r.r_low < 0)
           AND (r.derived_fit = 'transition')   = (r.r_low < 0 AND r.r_high > 0)
           AND r.m_low  = greatest(r.r_low, -r.r_high, 0)
           AND r.m_mode = abs(r.r_mode)
           AND r.m_high = greatest(r.r_high, -r.r_low) AS holds,
           format('%s [%s, %s, %s] from n [%s, %s, %s] and d [%s, %s, %s]; %s; |r| [%s, %s, %s]',
                  CASE WHEN r.pivoted THEN 'pivoted r' ELSE 'r' END,
                  r.r_low, r.r_mode, r.r_high, n.n_low, n.n_mode, n.n_high,
                  d.d_low, d.d_mode, d.d_high, r.derived_fit, r.m_low, r.m_mode, r.m_high) AS detail
    FROM      (
        SELECT * FROM remainder
    ) r
    JOIN      (
        SELECT * FROM demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers_nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
) p ON true
WHERE a.slug = 'crossed_remainder'
UNION ALL
-- layers/remainder.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/fused_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           r.exposure = CASE WHEN r.pivoted THEN greatest(-f.pivoted_low, 0)
                             ELSE greatest(d.d_high - n.n_low, 0) END
           AND (r.exposure = 0) = (r.derived_fit = 'clearance')
           AND r.exposure <= r.m_high AS holds,
           format('exposure %s from %s; %s; |r| at most %s',
                  r.exposure,
                  CASE WHEN r.pivoted THEN format('the pivoted low %s', f.pivoted_low)
                       ELSE format('d_high %s against n_low %s', d.d_high, n.n_low) END,
                  r.derived_fit, r.m_high) AS detail
    FROM      (
        SELECT * FROM remainder
    ) r
    JOIN      (
        SELECT * FROM demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers_nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
    LEFT JOIN (
        SELECT * FROM fused_remainders
    ) f ON f.composition = r.filing AND f.composed_layer = r.layer
) p ON true
WHERE a.slug = 'exposure'
UNION ALL
-- layers/decomposed.sqlc against layers/differenced_remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.m_low  * x.q - x.d_high_residue - r.r_low)  < 1e-9
           AND abs(x.m_mode * x.q - x.d_mode_residue - r.r_mode) < 1e-9
           AND abs(x.m_high * x.q - x.d_low_residue  - r.r_high) < 1e-9
           AND x.d_low_residue  >= 0 AND x.d_low_residue  < x.q
           AND x.d_mode_residue >= 0 AND x.d_mode_residue < x.q
           AND x.d_high_residue >= 0 AND x.d_high_residue < x.q AS holds,
           format('m [%s, %s, %s] quanta of %s, residues [%s, %s, %s], against r [%s, %s, %s]',
                  round(x.m_low, 6), round(x.m_mode, 6), round(x.m_high, 6), x.q,
                  x.d_high_residue, x.d_mode_residue, x.d_low_residue,
                  r.r_low, r.r_mode, r.r_high) AS detail
    FROM      (
        SELECT * FROM decomposed
    ) x
    JOIN      (
        SELECT * FROM differenced_remainder
    ) r ON r.filing = x.filing AND r.layer = x.layer
) p ON true
WHERE a.slug = 'remainder_decomposes'
UNION ALL
-- layers/decomposed.sqlc, restricted to demands inside one tooth.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           x.d_low_residue <= x.d_mode_residue AND x.d_mode_residue <= x.d_high_residue AS holds,
           format('demand [%s, %s, %s] inside tooth %s of %s, residues [%s, %s, %s]',
                  x.d_low, x.d_mode, x.d_high, x.d_low_tooth, x.q,
                  x.d_low_residue, x.d_mode_residue, x.d_high_residue) AS detail
    FROM (
        SELECT * FROM decomposed
    ) x
    WHERE NOT x.crosses_tooth
) p ON true
WHERE a.slug = 'sawtooth'
UNION ALL
-- composition/composed_quantum.sqlc against layers/nameplate.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT c.composition || ' / ' || c.composed_layer AS subject,
           abs(n.n_mode - c.composed_quantum * round(n.n_mode / c.composed_quantum)) < 1e-9
           AND (e.mode IS NULL
                OR abs(e.mode - c.composed_quantum * round(e.mode / c.composed_quantum)) < 1e-9)
           AS holds,
           format('quantum %s %s%s against a nameplate of %s%s',
                  c.composed_quantum, c.unit,
                  CASE WHEN c.spread THEN ', read at a factor''s mode' ELSE '' END,
                  n.n_mode,
                  CASE WHEN e.mode IS NULL THEN ''
                       ELSE format(' and an elimination of %s', e.mode) END) AS detail
    FROM      (
        SELECT * FROM composed_quantum
    ) c
    JOIN      (
        SELECT * FROM layers_nameplate
    ) n ON n.filing = c.composition AND n.layer = c.composed_layer
    LEFT JOIN (
        SELECT * FROM filed
    ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
       AND e.quantity = 'nameplate'
    WHERE c.composed_quantum IS NOT NULL
) p ON true
WHERE a.slug = 'composed_quantum'
UNION ALL
-- composition/fused.sqlc against composition/resolved_quantities.sqlc, composition/parts.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT o.filing || ' / ' || o.layer || ' / ' || o.quantity AS subject,
           f.composition IS NOT NULL
           AND abs(f.sum_low  - r.sum_low)  < 1e-9
           AND abs(f.sum_mode - r.sum_mode) < 1e-9
           AND abs(f.sum_high - r.sum_high) < 1e-9
           AND f.computed_low <= f.computed_mode AND f.computed_mode <= f.computed_high
           AND abs(f.computed_mode - (r.sum_mode - coalesce(e.mode, 0))) < 1e-9
           AND CASE WHEN r.sum_low  - coalesce(e.low,  0) <= r.sum_mode - coalesce(e.mode, 0)
                     AND r.sum_mode - coalesce(e.mode, 0) <= r.sum_high - coalesce(e.high, 0)
                    THEN abs(f.computed_low  - (r.sum_low  - coalesce(e.low,  0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.high, 0))) < 1e-9
                    ELSE abs(f.computed_low  - (r.sum_low  - coalesce(e.high, 0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.low,  0))) < 1e-9 END
           AND f.agrees = (abs(f.computed_low  - d.low)  < 1e-9
                       AND abs(f.computed_mode - d.mode) < 1e-9
                       AND abs(f.computed_high - d.high) < 1e-9) AS holds,
           format('Σ [%s, %s, %s] less [%s, %s, %s] gives [%s, %s, %s] against a filed [%s, %s, %s]',
                  r.sum_low, r.sum_mode, r.sum_high,
                  coalesce(e.low, 0), coalesce(e.mode, 0), coalesce(e.high, 0),
                  f.computed_low, f.computed_mode, f.computed_high,
                  d.low, d.mode, d.high) AS detail
    FROM      (
        SELECT * FROM owed_equality
    ) o
    JOIN      (
        SELECT p.composition, p.composed_layer, s.quantity,
               sum(least(   s.low  * coalesce(p.factor_low, 1),
                            s.low  * coalesce(p.factor_high, 1))) AS sum_low,
               sum(s.mode * coalesce(p.factor_mode, 1))           AS sum_mode,
               sum(greatest(s.high * coalesce(p.factor_low, 1),
                            s.high * coalesce(p.factor_high, 1))) AS sum_high
        FROM      (
            SELECT * FROM parts
        ) p
        JOIN      (
            SELECT * FROM resolved_quantities
        ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
        GROUP BY p.composition, p.composed_layer, s.quantity
    ) r ON r.composition = o.filing AND r.composed_layer = o.layer AND r.quantity = o.quantity
    JOIN      (
        SELECT * FROM summed_quantities
    ) d ON d.filing = o.filing AND d.layer = o.layer AND d.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM filed
    ) e ON e.composition = o.filing AND e.composed_layer = o.layer AND e.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM fused
    ) f ON f.composition = o.filing AND f.composed_layer = o.layer AND f.quantity = o.quantity
) p ON true
WHERE a.slug = 'fusion_sum'
UNION ALL
-- composition/fused_remainders.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/remainder_frontier.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.subject,
           x.pivoted_low <= x.pivoted_mode AND x.pivoted_mode <= x.pivoted_high
           AND x.pivoted_low >= x.cross_low - 1e-9 AND x.pivoted_high <= x.cross_high + 1e-9
           AND (NOT x.sums_agree OR abs(x.pivoted_mode - x.cross_mode) < 1e-9)
           AND (NOT x.sums_agree OR x.spread
                OR (abs(x.pivoted_low - x.cross_low) < 1e-9
                    AND abs(x.pivoted_high - x.cross_high) < 1e-9)) AS holds,
           format('pivot [%s, %s, %s] against n - d [%s, %s, %s]; %s',
                  x.pivoted_low, x.pivoted_mode, x.pivoted_high,
                  x.cross_low, x.cross_mode, x.cross_high,
                  CASE WHEN NOT x.sums_agree THEN 'a composed sum disagrees with its filing'
                       WHEN x.spread THEN 'a factor on the walk has width'
                       ELSE 'no factor on the walk has width' END) AS detail
    FROM (
        SELECT r.composition || ' / ' || r.composed_layer AS subject,
               r.pivoted_low, r.pivoted_mode, r.pivoted_high,
               n.n_low  - d.d_high AS cross_low,
               n.n_mode - d.d_mode AS cross_mode,
               n.n_high - d.d_low  AS cross_high,
               EXISTS (SELECT 1 FROM ( SELECT * FROM remainder_frontier ) w
                        WHERE w.root_filing = r.composition AND w.root_layer = r.composed_layer
                          AND w.factor_low IS DISTINCT FROM w.factor_high) AS spread,
               NOT EXISTS (SELECT 1 FROM ( SELECT * FROM fused ) f
                            WHERE f.composition = r.composition
                              AND f.composed_layer = r.composed_layer
                              AND f.quantity IN ('demand', 'nameplate')
                              AND NOT f.agrees) AS sums_agree
        FROM      (
            SELECT * FROM fused_remainders
        ) r
        JOIN      (
            SELECT * FROM demand
        ) d ON d.filing = r.composition AND d.layer = r.composed_layer
        JOIN      (
            SELECT * FROM layers_nameplate
        ) n ON n.filing = r.composition AND n.layer = r.composed_layer
    ) x
) p ON true
WHERE a.slug = 'composed_remainder'
UNION ALL
-- folds/rule_subjects.sqlc for every rule checks/roster.sqlc declares, one verdict per rule.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT r.slug AS subject,
           f.violated = 0 AS holds,
           format('%s examined, %s violating', f.answered, f.violated) AS detail
    FROM (
        SELECT * FROM checks_roster
    ) r
    JOIN (
        SELECT * FROM rule_subjects
    ) f ON f.subject = r.rule
) p ON true
WHERE a.slug = 'conforms'
UNION ALL
-- checks/fit_axes.sqlc and checks/fit_domain.sqlc against rank/rule_closure.sqlc and reports/fit_coverage.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT s.slug AS subject,
           r.slug IS NOT NULL
           AND coalesce(x.axes, 0) = 1
           AND (x.axis = 'not read') = NOT coalesce(h.reaches, false)
           AND CASE WHEN x.axis = 'not read' THEN coalesce(k.cells, 0) = 0
                    ELSE coalesce(k.cells, 0) = 4 AND k.distinct_cells = 4 END
           AND coalesce(k.disagreeing, 0) = 0                             AS holds,
           format('%s; its closure %s the fit; %s cells, %s disagreeing with what it examined%s',
                  coalesce(x.axis::text, 'no axis declared'),
                  CASE WHEN coalesce(h.reaches, false) THEN 'reaches' ELSE 'does not reach' END,
                  coalesce(k.cells, 0), coalesce(k.disagreeing, 0),
                  coalesce(': ' || k.cells_read, ''))                     AS detail
    FROM (
        SELECT slug FROM ( SELECT * FROM checks_roster ) r0
        UNION
        SELECT slug FROM ( SELECT * FROM fit_axes ) a0
        UNION
        SELECT slug FROM ( SELECT * FROM fit_domain ) d0
    ) s
    LEFT JOIN (
        SELECT * FROM checks_roster
    ) r ON r.slug = s.slug
    LEFT JOIN (
        SELECT f.slug, count(*) AS axes, min(f.axis) AS axis
        FROM ( SELECT * FROM fit_axes ) f
        GROUP BY f.slug
    ) x ON x.slug = s.slug
    LEFT JOIN (
        SELECT c.slug, true AS reaches
        FROM ( -- rank/compose_edges.sqlc walked from each rule on checks/roster.sqlc.
WITH RECURSIVE closure(slug, template) AS (
    SELECT r.slug, 'checks/' || r.slug || '.sqlc'
    FROM (
        SELECT * FROM checks_roster
    ) r
    UNION
    SELECT c.slug, e.child
    FROM closure c
    JOIN (
        SELECT * FROM compose_edges
    ) e ON e.parent = c.template
)
SELECT slug, template FROM closure
 ) c
        WHERE c.template IN ('layers/remainder.sqlc', 'layers/filed_remainders.sqlc')
        GROUP BY c.slug
    ) h ON h.slug = s.slug
    LEFT JOIN (
        SELECT v.slug,
               count(*)                                                        AS cells,
               count(DISTINCT coalesce(v.fit::text, 'no fit'))                 AS distinct_cells,
               count(*) FILTER (WHERE (v.standing = 'exercised') <> (v.examined > 0)) AS disagreeing,
               string_agg(coalesce(v.fit::text, 'no fit') || ' ' || v.standing || ' ' || v.examined,
                          ', ' ORDER BY v.fit NULLS LAST)                      AS cells_read
        FROM ( SELECT * FROM fit_coverage ) v
        GROUP BY v.slug
    ) k ON k.slug = s.slug
) p ON true
WHERE a.slug = 'fit_domain'
UNION ALL
-- epistemics/absences.sqlc against epistemics/filed_absences.sqlc, through epistemics/absence_positions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    WITH positions AS (
        SELECT * FROM (
            -- The XSD's Stated* wrapper positions in the documents ingest loads, against epistemics/absences.sqlc's questions.
SELECT * FROM (VALUES
  ('pm:processModulus/pm:notation',     'its own notation',                       NULL::text),
  ('pm:processModulus/pm:evidence',     'what it is evidence for',                NULL),
  ('pm:stack/pm:scope',                 'how much of the system',                 NULL),
  ('pm:stack/pm:couplings',             'did anybody look for couplings',         NULL),
  ('pm:regime/pm:framework',            'regime framework',                       NULL),
  ('pm:regime/pm:chart',                'regime chart',                           NULL),
  ('asrt:regime/pm:framework',          'part regime framework',                  NULL),
  ('asrt:regime/pm:chart',              'part regime chart',                      NULL),
  ('asrt:provenance/pm:standing',       'assertion standing',                     NULL),
  ('pm:provenance/pm:standing',         'provenance standing',                    NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on an absence',     NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on a derivation',   NULL),
  ('pm:claim/pm:narrowsWhen',           'narrowsWhen',                            NULL),
  ('pm:claim/pm:boundOrigin',           'boundOrigin',                            NULL),
  ('pm:claim/pm:denominator',           'denominator',                            NULL),
  ('pm:coupling/pm:strength',           'coupling strength',                      NULL),
  ('pm:operation/pm:notationPosition',  'where the operation is in a notation',   NULL),
  ('pm:draw/pm:quantity',               'operation draw',                         NULL),
  ('pm:induces/pm:commitment',          'operation induction',                    NULL),
  ('pm:demand/pm:amount',               'demand',                                 NULL),
  ('pm:demand/pm:patience',             'patience',                               NULL),
  ('pm:layer/pm:timeSlack',             'buffer slack',                           NULL),
  ('pm:nameplate/pm:capacitySlack',     'buffer slack',                           NULL),
  ('pm:nameplate/pm:inventorySlack',    'buffer slack',                           NULL),
  ('pm:layer/pm:remainder',             'remainder',                              NULL),
  ('pm:remainder/pm:sign',              'remainder sign',                         NULL),
  ('pm:remainder/pm:absorber',          'remainder absorber',                     NULL),
  ('pm:remainder/pm:quantity',          'remainder quantity',                     NULL),
  ('pm:holder/pm:share',                'holder share',                           NULL),
  ('pm:nameplate/pm:amount',            'nameplate amount',                       NULL),
  ('pm:nameplate/pm:amountOrigin',      'who committed the amount',               NULL),
  ('pm:nameplate/pm:divisibility',      'divisibility',                           NULL),
  ('pm:divisibility/pm:window',         'duty-cycle window',                      NULL),
  ('pm:lumpy/pm:size',                  'lump size',                              NULL),
  ('pm:quantum/pm:size',                'duty-cycle period',                      NULL),
  ('pm:jagged/pm:draw',                 'draw',                                   NULL),
  ('pm:jagged/pm:measurementBasis',     'measurement basis',                      NULL),
  ('asrt:fusion/asrt:eliminations',     'did anybody look for double counting',   NULL),
  ('asrt:elimination/asrt:quantity',    'eliminated quantity',                    NULL),
  ('asrt:part/asrt:factor',             'part factor',                            NULL),
  ('pm:continuous/pm:premium',          NULL,
   'a premium is a claim nothing reads, so it has no columns of its own: its value is in claim and its absence here alone'),
  ('pm:remainder/pm:holder',            NULL,
   'a holder that is typed absent has no row in holder, whose rows are the holders that bear a share')
) AS p(owns, question, why_no_column)

        ) r
    ),
    by_owns AS (
        SELECT owns, min(question) AS g FROM positions WHERE question IS NOT NULL GROUP BY owns
    ),
    by_question AS (
        SELECT p.question, min(o.g) AS g
        FROM positions p JOIN by_owns o USING (owns)
        WHERE p.question IS NOT NULL
        GROUP BY p.question
    ),
    owns_group AS (
        SELECT p.owns, min(q.g) AS g
        FROM positions p JOIN by_question q USING (question)
        GROUP BY p.owns
    ),
    counted AS (
        SELECT q.g, c.filing, c.reason, count(*) AS n
        FROM (
            SELECT * FROM absences
        ) c
        JOIN by_question q USING (question)
        GROUP BY q.g, c.filing, c.reason
    ),
    filed AS (
        SELECT o.g, f.filing, f.reason, count(*) AS n
        FROM (
            SELECT * FROM filed_absences
        ) f
        JOIN owns_group o USING (owns)
        GROUP BY o.g, f.filing, f.reason
    ),
    cells AS (
        SELECT coalesce(c.g, f.g) AS g, coalesce(c.filing, f.filing) AS filing,
               coalesce(c.reason, f.reason) AS reason,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.g = c.g AND f.filing = c.filing AND f.reason = c.reason
    )
    SELECT q.g AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing, x.reason,
                                                     x.filed, x.counted), '; ' ORDER BY x.filing, x.reason)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM (SELECT DISTINCT g FROM by_question) q
    LEFT JOIN cells x ON x.g = q.g
    GROUP BY q.g
    UNION ALL
    SELECT 'positions the roster does not name',
           count(*) FILTER (WHERE p.owns IS NULL) = 0,
           format('%s absences at %s undeclared position(s)%s; %s at positions no column answers',
                  count(*) FILTER (WHERE p.owns IS NULL),
                  count(DISTINCT f.owns) FILTER (WHERE p.owns IS NULL),
                  coalesce(': ' || string_agg(DISTINCT f.owns, ', ') FILTER (WHERE p.owns IS NULL), ''),
                  count(*) FILTER (WHERE p.owns IS NOT NULL AND p.question IS NULL))
    FROM (
        SELECT * FROM filed_absences
    ) f
    LEFT JOIN (SELECT owns, min(question) AS question FROM positions GROUP BY owns) p USING (owns)
    UNION ALL
    SELECT 'questions no position holds',
           count(*) = 0,
           format('%s question(s) on the census with no position%s', count(*),
                  coalesce(': ' || string_agg(q.question, ', '), ''))
    FROM (
        SELECT * FROM absence_questions
    ) q
    WHERE q.question NOT IN (SELECT question FROM positions WHERE question IS NOT NULL)
) p ON true
WHERE a.slug = 'absences_filed'
UNION ALL
-- epistemics/derivations.sqlc against epistemics/filed_derivations.sqlc, through identities/roster.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    WITH counted AS (
        SELECT c.owns, c.element, c.filing, c.identity, count(*) AS n
        FROM (
            -- every pm:derivation/identity in the schema, from every column that keeps one.
SELECT filing, subject, owns, coalesce(element, owns) AS element, identity FROM (
    SELECT filing, layer AS subject, 'pm:demand/pm:amount' AS owns, NULL::text AS element,
           derivation AS identity FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'pm:nameplate/pm:amount', NULL, derivation FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'pm:jagged/pm:draw', NULL, derivation FROM (
        SELECT * FROM summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:sign', NULL, sign_derivation FROM (
        SELECT * FROM filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation FROM (
        SELECT * FROM filed_remainders
    ) fr
    UNION ALL SELECT filing, layer || ' / ' || buffer::text,
                     CASE s.buffer WHEN 'time'     THEN 'pm:layer/pm:timeSlack'
                                   WHEN 'capacity' THEN 'pm:nameplate/pm:capacitySlack'
                                   ELSE 'pm:nameplate/pm:inventorySlack' END,
                     NULL, derivation FROM (
        SELECT * FROM slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text, 'pm:holder/pm:share', NULL, share_derivation FROM (
        SELECT * FROM holders
    ) h
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, owns, element, identity FROM (
        SELECT * FROM claim_derivations
    ) c
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'asrt:elimination/asrt:quantity', NULL, derivation FROM (
        SELECT * FROM filed
    ) e
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'asrt:part/asrt:factor', NULL, factor_derivation FROM (
        SELECT * FROM part_references
    ) pr
) d
WHERE identity IS NOT NULL

        ) c
        GROUP BY c.owns, c.element, c.filing, c.identity
    ),
    filed AS (
        SELECT f.owns, f.element, f.filing, f.identity, count(*) AS n
        FROM (
            SELECT * FROM filed_derivations
        ) f
        GROUP BY f.owns, f.element, f.filing, f.identity
    ),
    cells AS (
        SELECT coalesce(c.owns, f.owns) AS owns, coalesce(c.element, f.element) AS element,
               coalesce(c.filing, f.filing) AS filing, coalesce(c.identity, f.identity) AS identity,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.owns = c.owns AND f.element = c.element AND f.filing = c.filing
                         AND f.identity = c.identity
    ),
    positions AS (
        SELECT DISTINCT r.owns, r.element
        FROM (
            SELECT * FROM identities_roster
        ) r
    )
    SELECT CASE WHEN q.element = q.owns THEN q.owns ELSE q.element || ' at ' || q.owns END AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing,
                                                     x.identity, x.filed, x.counted),
                                              '; ' ORDER BY x.filing, x.identity)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM positions q
    LEFT JOIN cells x ON x.owns = q.owns AND x.element = q.element
    GROUP BY q.owns, q.element
    UNION ALL
    SELECT 'pairs the roster does not admit',
           count(*) = 0,
           format('%s derivation(s) at a cell identities/roster.sqlc does not list%s', count(*),
                  coalesce(': ' || string_agg(DISTINCT f.element || ' at ' || f.owns || ' ' || f.identity::text, ', '), ''))
    FROM (
        SELECT * FROM filed_derivations
    ) f
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT * FROM identities_roster
        ) r
        WHERE r.owns = f.owns AND r.element = f.element AND r.identity = f.identity::text
    )
) p ON true
WHERE a.slug = 'derivations_filed'
UNION ALL
-- folds/fusion_parts.sqlc per composition, against composition/part_references.sqlc counted directly.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.composition AS subject,
           x.empty = 0 AND x.parts = coalesce(y.references_filed, 0) AS holds,
           format('%s fusion(s), %s named by a part, %s part(s), %s filed%s',
                  x.fusions, x.fusions - x.empty, x.parts, coalesce(y.references_filed, 0),
                  coalesce(': none names ' || x.unnamed, '')) AS detail
    FROM (
        SELECT d.filing                                   AS composition,
               count(*)                                   AS fusions,
               count(*) FILTER (WHERE f.parts IS NULL)    AS empty,
               coalesce(sum(f.parts), 0)                  AS parts,
               string_agg(d.layer, ', ' ORDER BY d.layer)
                   FILTER (WHERE f.parts IS NULL)         AS unnamed
        FROM      (
            SELECT * FROM fusions
        ) d
        LEFT JOIN (
            SELECT * FROM fusion_parts
        ) f ON f.composition = d.filing AND f.composed_layer = d.layer
        GROUP BY d.filing
    ) x
    LEFT JOIN (
        SELECT pr.composition, count(*) AS references_filed
        FROM (
            SELECT * FROM part_references
        ) pr
        GROUP BY pr.composition
    ) y ON y.composition = x.composition
) p ON true
WHERE a.slug = 'fusions_have_parts'
UNION ALL
-- epistemics/coupling_searches.sqlc against entries/couplings.sqlc, eliminations/searched.sqlc against eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT s.subject,
           count(*) FILTER (WHERE (s.answer IS NULL) <> (s.entries > 0)) = 0 AS holds,
           format('%s searched: %s filed entries, %s typed why not, %s both or neither',
                  count(*), count(*) FILTER (WHERE s.entries > 0 AND s.answer IS NULL),
                  count(*) FILTER (WHERE s.entries = 0 AND s.answer IS NOT NULL),
                  count(*) FILTER (WHERE (s.answer IS NULL) <> (s.entries > 0))) AS detail
    FROM (
        SELECT 'couplings' AS subject, cs.answer,
               (SELECT count(*) FROM (
                    SELECT * FROM couplings
                ) c WHERE c.filing = cs.filing) AS entries
        FROM (
            SELECT * FROM coupling_searches
        ) cs
        UNION ALL
        SELECT 'double counting', es.answer,
               (SELECT count(*) FROM (
                    SELECT * FROM filed
                ) e WHERE e.composition = es.composition AND e.composed_layer = es.composed_layer)
        FROM (
            SELECT * FROM searched
        ) es
    ) s
    GROUP BY s.subject
) p ON true
WHERE a.slug = 'searches_answered'
UNION ALL
-- every fold in folds/ whose population does not reach algebra/all.sqlc, its boxes against its rows and its rows against its population.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.unbalanced = 0 AND x.counted = x.population AS holds,
           format('%s rows over %s subjects, %s in the population; %s subjects whose boxes do not add up',
                  x.counted, x.subjects, x.population, x.unbalanced) AS detail
    FROM (
        SELECT 'rules' AS contract, f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM checks_all ) c) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.violated + s.passed) AS unbalanced
               FROM ( SELECT * FROM rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM arithmetic_all ) z) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.computable + s.suspended + s.not_comparable) AS unbalanced
               FROM ( SELECT * FROM site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM catalogue ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM expected ) e) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM absence_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM derivation_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'subject_boxes'
UNION ALL
-- composition/part_references.sqlc, each part's factor_state against the factor columns it carries.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/part_references' AS subject,
           count(*) FILTER (WHERE x.mislabelled) = 0 AS holds,
           format('%s parts: %s omitted, %s stated, %s absent, %s derivation; %s whose state is not the column they file',
                  count(*),
                  count(*) FILTER (WHERE x.factor_state = 'omitted'),
                  count(*) FILTER (WHERE x.factor_state = 'stated'),
                  count(*) FILTER (WHERE x.factor_state = 'absent'),
                  count(*) FILTER (WHERE x.factor_state = 'derivation'),
                  count(*) FILTER (WHERE x.mislabelled)) AS detail
    FROM (
        SELECT r.factor_state,
               r.factor_state IS NULL
                 OR (r.factor_state = 'stated')     <> (r.factor_low IS NOT NULL)
                 OR (r.factor_state = 'absent')     <> (r.factor_absent IS NOT NULL)
                 OR (r.factor_state = 'derivation') <> (r.factor_derivation IS NOT NULL)
                 OR (r.factor_state = 'omitted')
                      <> (num_nonnulls(r.factor_low, r.factor_absent, r.factor_derivation) = 0)
                   AS mislabelled
        FROM (
            SELECT * FROM part_references
        ) r
    ) x
) p ON true
WHERE a.slug = 'factor_state'
UNION ALL
-- layers/summed_quantities.sqlc against composition/fusion_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/fusion_quantities' AS subject,
           x.total = x.leaves + x.fused AS holds,
           format('%s summed quantities = %s of layers no fusion names + %s of composed layers',
                  x.total, x.leaves, x.fused) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM summed_quantities ) s)  AS total,
             (SELECT count(*) FROM ( SELECT * FROM summed_quantities ) s
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM fusions ) f
                                  WHERE f.filing = s.filing AND f.layer = s.layer))   AS leaves,
             (SELECT count(*) FROM ( SELECT * FROM fusion_quantities ) q) AS fused
         ) x
) p ON true
WHERE a.slug = 'fusion_quantities'
UNION ALL
-- folds/part_sums.sqlc summed over every fusion, against composition/converted.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT c.quantity::text AS subject,
           c.parts = f.parts AND c.low = f.low AND c.mode = f.mode AND c.high = f.high AS holds,
           format('%s parts summing to [%s, %s, %s]; the fold holds %s summing to [%s, %s, %s]',
                  c.parts, c.low, c.mode, c.high, f.parts, f.low, f.mode, f.high) AS detail
    FROM (
        SELECT v.quantity, count(*) AS parts, sum(v.low) AS low, sum(v.mode) AS mode,
               sum(v.high) AS high
        FROM (
            SELECT * FROM converted
        ) v
        GROUP BY v.quantity
    ) c
    LEFT JOIN (
        SELECT s.quantity, sum(s.parts) AS parts, sum(s.sum_low) AS low, sum(s.sum_mode) AS mode,
               sum(s.sum_high) AS high
        FROM (
            SELECT * FROM part_sums
        ) s
        GROUP BY s.quantity
    ) f ON f.quantity = c.quantity
) p ON true
WHERE a.slug = 'part_sums'
UNION ALL
-- composition/fusions.sqlc × pm.summed_quantity, against composition/suspended_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/suspended_quantities' AS subject,
           x.total = x.owing + x.suspended AS holds,
           format('%s fusion quantities = %s no ground reaches + %s suspended',
                  x.total, x.owing, x.suspended) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM suspended_fusions ) s
                                  WHERE s.composition = f.filing AND s.composed_layer = f.layer
                                    AND (s.quantity IS NULL OR s.quantity = q.quantity)))    AS owing,
             (SELECT count(*) FROM ( SELECT * FROM suspended_quantities ) s)       AS suspended
         ) x
) p ON true
WHERE a.slug = 'suspended_quantities'
UNION ALL
-- composition/unsized_conversions.sqlc projected onto its composed layers, inside composition/unsettled.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/unsized_conversions' AS subject,
           count(*) FILTER (WHERE u.filing IS NULL) = 0 AS holds,
           format('%s composed layer(s) cannot size a conversion, %s cannot be differenced, %s outside%s',
                  count(*), (SELECT count(*) FROM ( SELECT * FROM unsettled ) t),
                  count(*) FILTER (WHERE u.filing IS NULL),
                  coalesce(': ' || string_agg(c.composition || '/' || c.composed_layer, ', '
                                              ORDER BY c.composition, c.composed_layer)
                                   FILTER (WHERE u.filing IS NULL), '')) AS detail
    FROM      (
        SELECT DISTINCT composition, composed_layer
        FROM ( SELECT * FROM unsized_conversions ) x
    ) c
    LEFT JOIN (
        SELECT * FROM unsettled
    ) u ON u.filing = c.composition AND u.layer = c.composed_layer
) p ON true
WHERE a.slug = 'unsized_conversions_are_unsettled'
UNION ALL
-- composition/parts.sqlc with layers/quantities.sqlc, against composition/part_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/part_quantities' AS subject,
           x.total = x.alone + x.paired AS holds,
           format('%s part quantities = %s the composed layer does not file + %s set beside it',
                  x.total, x.alone, x.paired) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM parts ) p
               JOIN ( SELECT * FROM quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer)                  AS total,
             (SELECT count(*) FROM ( SELECT * FROM parts ) p
               JOIN ( SELECT * FROM quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM quantities ) c
                                  WHERE c.filing = p.composition AND c.layer = p.composed_layer
                                    AND c.quantity = q.quantity))                        AS alone,
             (SELECT count(*) FROM ( SELECT * FROM part_quantities ) x)       AS paired
         ) x
) p ON true
WHERE a.slug = 'part_quantities'
UNION ALL
-- layers/figures.sqlc against layers/demand.sqlc and layers/nameplate.sqlc counted by themselves.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/figures' AS subject,
           x.pairs = x.demands + x.nameplates - x.both AS holds,
           format('%s layers with a figure = %s with a demand + %s with a nameplate - %s with both',
                  x.pairs, x.demands, x.nameplates, x.both) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM figures ) f)     AS pairs,
             (SELECT count(*) FROM ( SELECT * FROM demand ) d)      AS demands,
             (SELECT count(*) FROM ( SELECT * FROM layers_nameplate ) n)   AS nameplates,
             (SELECT count(*) FROM ( SELECT * FROM demand ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM layers_nameplate ) n
                              WHERE n.filing = d.filing AND n.layer = d.layer))  AS both
         ) x
) p ON true
WHERE a.slug = 'figures'
UNION ALL
-- entries/holder_totals.sqlc against folds/served_totals.sqlc and entries/unserved_totals.sqlc, per layer.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'folds/served_totals' AS subject,
           count(*) FILTER (WHERE NOT x.balances) = 0 AS holds,
           format('%s layers with a holder, %s where held = served + unserved%s',
                  count(*), count(*) FILTER (WHERE x.balances),
                  coalesce(': not on ' || string_agg(x.filing || '/' || x.layer, ', ' ORDER BY x.filing, x.layer)
                                           FILTER (WHERE NOT x.balances), '')) AS detail
    FROM (
        SELECT t.filing, t.layer,
               t.holders = coalesce(s.holders, 0) + coalesce(u.holders, 0)
                 AND coalesce(t.shares_mode, 0) = coalesce(s.served_mode, 0) + coalesce(u.unserved_mode, 0)
                   AS balances
        FROM      (
            SELECT * FROM holder_totals
        ) t
        LEFT JOIN (
            SELECT * FROM served_totals
        ) s ON s.filing = t.filing AND s.layer = t.layer
        LEFT JOIN (
            SELECT * FROM unserved_totals
        ) u ON u.filing = t.filing AND u.layer = t.layer
    ) x
) p ON true
WHERE a.slug = 'served_totals'
UNION ALL
-- composition/derived_quantities.sqlc against composition/parts.sqlc, composition/resolved_quantities.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT d.filing || ' / ' || d.layer || ' / ' || d.quantity AS subject,
           (d.low IS NULL) = (x.low IS NULL)
           AND (d.low IS NULL
                OR (abs(d.low  - x.low)  < 1e-9 AND abs(d.mode - x.mode) < 1e-9
                    AND abs(d.high - x.high) < 1e-9))                          AS holds,
           CASE WHEN d.low IS NOT NULL
                THEN format('walked [%s, %s, %s], one level [%s, %s, %s]',
                            d.low, d.mode, d.high, x.low, x.mode, x.high)
                ELSE format('not computable: %s; one level %s', d.blocked_because,
                            CASE WHEN x.low IS NULL THEN 'cannot compute it either'
                                 ELSE format('gives [%s, %s, %s]', x.low, x.mode, x.high) END)
           END                                                                 AS detail
    FROM (
        SELECT * FROM derived_quantities
    ) d
    LEFT JOIN (
        SELECT s.filing, s.layer, s.quantity,
               CASE WHEN ok THEN s_low  - e_low  END AS low,
               CASE WHEN ok THEN s_mode - e_mode END AS mode,
               CASE WHEN ok THEN s_high - e_high END AS high
        FROM (
            SELECT t.*,
                   t.parts > 0 AND t.parts = t.resolved_parts AND t.figures = t.parts
                   AND t.searched_ok AND t.e_ok
                   AND t.s_low - t.e_low <= t.s_mode - t.e_mode
                   AND t.s_mode - t.e_mode <= t.s_high - t.e_high AS ok
            FROM (
                SELECT f.filing, f.layer, f.quantity,
                       coalesce(r.parts, 0) AS parts,
                       count(p.part_layer) AS resolved_parts,
                       count(q.low) FILTER (WHERE p.factor_state IN ('omitted', 'stated')) AS figures,
                       sum(least(   q.low  * coalesce(p.factor_low, 1),
                                    q.low  * coalesce(p.factor_high, 1))) AS s_low,
                       sum(q.mode * coalesce(p.factor_mode, 1))           AS s_mode,
                       sum(greatest(q.high * coalesce(p.factor_low, 1),
                                    q.high * coalesce(p.factor_high, 1))) AS s_high,
                       coalesce(max(e.low),  0) AS e_low,
                       coalesce(max(e.mode), 0) AS e_mode,
                       coalesce(max(e.high), 0) AS e_high,
                       bool_and(e.absent IS NULL AND e.derivation IS NULL) IS NOT FALSE AS e_ok,
                       coalesce(max(es.answer::text), '') <> 'unmeasured' AS searched_ok
                FROM      (
                    SELECT s.filing, s.layer, s.quantity
                    FROM ( SELECT * FROM summed_quantities ) s
                    WHERE s.derivation IS NOT NULL
                ) f
                LEFT JOIN (
                    SELECT * FROM fusion_parts
                ) r ON r.composition = f.filing AND r.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM parts
                ) p ON p.composition = f.filing AND p.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM resolved_quantities
                ) q ON q.filing = p.part_filing AND q.layer = p.part_layer AND q.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM filed
                ) e ON e.composition = f.filing AND e.composed_layer = f.layer AND e.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM searched
                ) es ON es.composition = f.filing AND es.composed_layer = f.layer
                GROUP BY f.filing, f.layer, f.quantity, r.parts
            ) t
        ) s
    ) x ON x.filing = d.filing AND x.layer = d.layer AND x.quantity = d.quantity
) p ON true
WHERE a.slug = 'derived_quantities'
UNION ALL
-- composition/part_references.sqlc partitioned by composition/parts.sqlc into composition/unresolved_parts.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/unresolved_parts' AS subject,
           x.total = x.kept + x.resolved AS holds,
           format('%s part references = %s unresolved + %s resolved', x.total, x.kept, x.resolved)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM part_references ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM unresolved_parts ) u) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM part_references ) r
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM parts ) p
                             WHERE p.composition = r.composition
                               AND p.composed_layer = r.composed_layer
                               AND p.part_notation = r.part_filing
                               AND p.part_layer = r.part_layer))                    AS resolved
         ) x
) p ON true
WHERE a.slug = 'unresolved_parts'
UNION ALL
-- layers/differenced_remainder.sqlc partitioned by composition/figureless_remainders.sqlc into layers/remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'layers/remainder' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s differenced = %s in force + %s with no legitimate figure', x.total, x.kept,
                  x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM differenced_remainder ) b) AS total,
             (SELECT count(*) FROM ( SELECT * FROM remainder ) r)             AS kept,
             (SELECT count(*) FROM ( SELECT * FROM differenced_remainder ) b
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM figureless_remainders ) g
                             WHERE g.filing = b.filing AND g.layer = b.layer))  AS removed
         ) x
) p ON true
WHERE a.slug = 'remainder_in_force'


)
SELECT z.law                            AS "law!",
       f.law                            AS "formula!",
       coalesce(z.subject, '')          AS "subject!",
       z.holds                          AS "holds",
       coalesce(z.detail, '')           AS "detail!"
FROM (
    SELECT * FROM algebra_all
) z
JOIN (
    SELECT * FROM algebra_roster
) f ON f.slug = z.law
ORDER BY z.law, z.subject
