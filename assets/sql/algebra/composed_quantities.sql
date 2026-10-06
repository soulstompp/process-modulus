-- layers/summed_quantities.sqlc split by the query the roster names as this law's subject.
WITH algebra_roster AS (
-- the laws these queries' relations claim to obey.
SELECT * FROM (VALUES
  ('decomposition',
   'cutting the graph by filing loses no edge',
   'rank/decomposition', 'partition', 'repeats: one edge counted in both scopes'),
  ('compose_decomposition',
   'cut by directory, every template is in one directory and every edge is kept or crossing',
   'rank/compose_decomposition', 'partition',
   'no repeats: a template is in exactly one directory'),
  ('cycle_space',
   'the layer graph has a loop exactly when some fusion''s parts overlap',
   'rank/cycle_space', 'value', 'no repeats: one row, the layer graph against its rule'),
  ('composition_kernel',
   'the room to move parts without moving a composed figure is the parts less the fusions',
   'rank/composition_kernel', 'value',
   'no repeats: one row, the fusion fold against the layer graph'),
  ('composition_row_space',
   'per fusion, the one way its figure moves and the ways that leave it still make up every '
   'part, and the parts and the fusions agree on how many figures the parts can move',
   'rank/composition_row_space', 'value',
   'no repeats: one row per fusion, folded to two subjects'),
  ('composition_image',
   'nothing on the fusion side is out of reach of the parts, and where something would be, a '
   'rule accuses somebody',
   'rank/composition_image', 'value', 'no repeats: one row per composition'),
  ('composition_closure',
   'under any fusion, the room to move the layers at the bottom is the room inside each fusion '
   'below it, added up',
   'rank/composition_closure', 'value', 'no repeats: one row per fusion taken as a root'),
  ('dimension_use',
   'only a declared template composes the list of every layer',
   'algebra/dimension_use', 'roster', 'no repeats: one row per undeclared parent'),
  ('owed_equality',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/owed_equality', 'difference', 'no repeats'),
  ('leaves',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/leaves', 'difference', 'repeats: removing them would be a defect'),
  ('jagged_layers',
   'what the difference keeps and what it removes make up the whole left side',
   'queries/observations/14-jagged-layers', 'difference', 'repeats: one row per doubled layer'),
  ('composed_quantities',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/composed_quantities', 'difference', 'no repeats'),
  ('integrity',
   'what the difference keeps and what it removes make up the whole left side',
   'reports/integrity', 'difference', 'repeats: removing them is intended'),
  ('carried',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/carried', 'difference', 'repeats: the anti-join keeps them'),
  ('owed_remainder',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/owed_remainder', 'difference', 'no repeats'),
  ('settled_remainders',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/settled_remainders', 'difference', 'repeats: one row per path'),
  ('unresolved_parts',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/unresolved_parts', 'difference', 'no repeats: pm.part''s key'),
  ('remainder_in_force',
   'what the difference keeps and what it removes make up the whole left side',
   'layers/remainder', 'difference', 'no repeats: one row per layer'),
  ('borne',
   'what every holder holds is what a buffer absorbed plus what went unserved',
   'entries/borne', 'additive', 'repeats: added up over holders'),
  ('arithmetic_class',
   'each candidate in exactly one class',
   'arithmetic/all', 'partition', 'no repeats'),
  ('remainder_standing',
   'each remainder in exactly one standing',
   'layers/remainder_scope', 'partition', 'no repeats'),
  ('exposure_standing',
   'each exposed layer in exactly one standing',
   'layers/exposure_scope', 'partition', 'no repeats'),
  ('searches',
   'the union holding both searches has as many rows as the two added together',
   'epistemics/searches', 'union', 'repeats: UNION ALL'),
  ('part_regimes',
   'what the difference keeps and what it removes make up the whole left side',
   'checks/part_regime_disagrees', 'difference', 'no repeats: pm.part''s key'),
  ('crossed_remainder',
   'the remainder''s low is the nameplate''s low less the demand''s high, its most likely is '
   'the two most likely values, and its high the nameplate''s high less the demand''s low',
   'layers/remainder', 'value', 'no repeats: one row per remainder'),
  ('exposure',
   'exposure is the largest demand less the smallest supply, and never below zero',
   'layers/remainder', 'value', 'no repeats: one row per remainder'),
  ('remainder_decomposes',
   'the whole quanta, times the quantum, less the residue, give back the remainder',
   'layers/decomposed', 'value', 'no repeats: one row per lumpy remainder'),
  ('sawtooth',
   'a demand inside one whole quantum keeps its residues in order',
   'layers/decomposed', 'value', 'no repeats: one row per demand inside one whole quantum'),
  ('composed_quantum',
   'the composed quantum divides the composed nameplate',
   'composition/composed_quantum', 'value',
   'no repeats: one row per composed layer with a quantum'),
  ('fusion_sum',
   'a composed figure is its parts, converted and added up, less its eliminations, per quantity',
   'composition/fused', 'value', 'no repeats: one row per owed fusion quantity'),
  ('composed_remainder',
   'a composed remainder worked out through its parts lies inside the composed totals'' remainder',
   'composition/fused_remainders', 'value', 'no repeats: one row per owed composed remainder'),
  ('derived_quantities',
   'a figure filed as derived is its parts, converted and added up, less its eliminations, one '
   'level at a time',
   'composition/derived_quantities', 'value',
   'no repeats: one row per figure filed as its fusion''s sum'),
  ('conforms',
   'no loaded document violates a rule',
   'checks/all', 'conformance', 'no repeats: one row per rule'),
  ('fit_domain',
   'a rule declares a fit axis exactly when it reaches the fit, and a cell exercised exactly when '
   'it examined something there',
   'reports/fit_coverage', 'roster', 'no repeats: one row per rule'),
  ('absences_filed',
   'the blanks counted from the columns are the blanks counted from the elements, per filing, '
   'group and reason',
   'epistemics/absences', 'roster', 'no repeats: one row per group of positions'),
  ('derivations_filed',
   'the derivations counted from the columns are those counted from the elements, per filing, '
   'position and identity',
   'epistemics/derivations', 'roster', 'no repeats: one row per position'),
  ('fusions_have_parts',
   'every fusion names at least one part, and its parts, counted fusion by fusion, add up to the '
   'part references',
   'folds/fusion_parts', 'partition', 'no repeats: one row per composition'),
  ('searches_answered',
   'each search either filed what it found or typed why it filed nothing, and never both',
   'epistemics/searches', 'partition', 'no repeats: one row per search'),
  ('subject_boxes',
   'each subject''s boxes add up to its rows, and the rows add up to the population',
   'folds/contract_subjects', 'partition', 'repeats: a population counted into its subjects'),
  ('factor_state',
   'each part in the factor state its columns file',
   'composition/part_references', 'partition', 'no repeats: pm.part''s key'),
  ('fusion_quantities',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/fusion_quantities', 'difference', 'no repeats: one row per layer and quantity'),
  ('part_sums',
   'the parts added up fusion by fusion come to the parts added up whole',
   'folds/part_sums', 'additive', 'repeats: every part counted'),
  ('suspended_quantities',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/suspended_quantities', 'difference', 'no repeats: one row per fusion and quantity'),
  ('unsized_conversions_are_unsettled',
   'a layer whose conversion nobody could size is a layer whose own totals cannot be subtracted',
   'composition/unsized_conversions', 'containment', 'no repeats: one row per composed layer'),
  ('part_quantities',
   'what the difference keeps and what it removes make up the whole left side',
   'composition/part_quantities', 'difference', 'no repeats: one row per part and quantity'),
  ('figures',
   'the layers with a figure are those with a demand, plus those with a nameplate, less those '
   'with both',
   'layers/figures', 'union', 'no repeats: one row per layer'),
  ('served_totals',
   'what a layer holds is what was served plus what went unserved',
   'folds/served_totals', 'additive', 'repeats: added up over holders'),
  ('layer_units',
   'one value read stands for the whole relation: every value under the key is the same, and '
   'the one read reaches every key',
   'units/conversions', 'dependency', 'no repeats: one row per condition'),
  ('class_domain',
   'every class of every declared type stands where its count puts it',
   'epistemics/class_domain', 'roster', 'no repeats: one row per condition')
) AS a(slug, law, governs, form, multiplicity)
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
eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
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
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
eliminations_unsized AS (
-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per
-- quantity.
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
composition_unsized_conversions AS (
-- asrt:Part/asrt:factor taking its pm:absent or pm:derivation branch, as a suspension of the
-- composed sum.
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
composition_fusions AS (
-- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f
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
-- layers/summed_quantities.sqlc without a figure on a part or on the composed layer, and not a
-- derivation, per fusion.
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
folds_fusion_parts AS (
-- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM composition_part_references
) r
GROUP BY r.composition, r.composed_layer
),
composition_derived_frontier AS (
-- layers/summed_quantities.sqlc filed as a derivation, walked through composition/parts.sqlc while
-- the node's figure is derived too.
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
composition_derived_quantities AS (
-- composition/derived_frontier.sqlc summed at the nodes stating the figure, less
-- eliminations/filed.sqlc at the root and each derived node passed.
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
composition_underived_parts AS (
-- composition/parts.sqlc whose figure composition/derived_quantities.sqlc cannot compute, per
-- fusion.
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
-- the grounds that lift the sum rule: those read off the filing, and a derived part that cannot
-- be computed.
SELECT * FROM composition_filed_grounds
UNION ALL
SELECT * FROM composition_underived_parts
),
composition_suspended_fusions AS (
-- composition/suspension_grounds.sqlc reduced to the fusion it suspends.
SELECT DISTINCT g.composition, g.composed_layer, g.quantity
FROM (
    SELECT * FROM composition_suspension_grounds
) g
),
composition_suspended_quantities AS (
-- composition/suspended_fusions.sqlc spread over pm.summed_quantity.
SELECT DISTINCT s.composition, s.composed_layer, q.quantity
FROM      (
    SELECT * FROM composition_suspended_fusions
) s
JOIN      unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
       ON s.quantity IS NULL OR s.quantity = q.quantity
),
composition_composed_quantities AS (
-- What each composed layer filed, per quantity, and the elimination to subtract from it.
-- layers/summed_quantities.sqlc minus composition/suspended_quantities.sqlc,
-- with eliminations/filed.sqlc.
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
    SELECT * FROM layers_summed_quantities
) d
LEFT JOIN (
    SELECT * FROM composition_suspended_quantities
) s
       ON s.composition = d.filing AND s.composed_layer = d.layer
      AND s.quantity = d.quantity
LEFT JOIN (
    SELECT * FROM eliminations_filed
) e
       ON e.composition = d.filing AND e.composed_layer = d.layer
      AND e.quantity = d.quantity
WHERE s.composition IS NULL
  AND d.low IS NOT NULL
)
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'composition/composed_quantities' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s stated figures: %s carried, %s suspended', x.total, x.kept, x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers_summed_quantities ) d
               WHERE d.low IS NOT NULL)                                              AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition_composed_quantities ) k)
                                                                                     AS kept,
             (SELECT count(*) FROM ( SELECT * FROM layers_summed_quantities ) d
               WHERE d.low IS NOT NULL
                 AND EXISTS (SELECT 1 FROM ( SELECT * FROM composition_suspended_quantities ) s
                              WHERE s.composition = d.filing AND s.composed_layer = d.layer
                                AND s.quantity = d.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'composed_quantities'
