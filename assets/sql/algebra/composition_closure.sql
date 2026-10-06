-- rank/composition_closure.sqlc: the whole composition's room against the sum of its levels'.
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
rank_composition_kernel AS (
-- asrt:Fusion/asrt:Part counted per fusion: its parts, and the offsets that count fixes.
SELECT p.composition,
       p.composed_layer,
       count(*)     AS parts,
       count(*) - 1 AS kernel_dim
FROM (
    SELECT * FROM composition_parts
) p
GROUP BY p.composition, p.composed_layer
),
composition_descent AS (
-- asrt:Fusion/asrt:Part followed through every level by way of pm.filing_identity.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition_parts
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
rank_composition_closure AS (
-- composition/descent.sqlc reduced to one row per reached layer,
-- against rank/composition_kernel.sqlc.
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
    SELECT * FROM rank_composition_kernel
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
            SELECT * FROM composition_descent
        ) d
        GROUP BY d.root_filing, d.root_layer, d.filing, d.layer
    ) w
    LEFT JOIN (
        SELECT * FROM rank_composition_kernel
    ) k ON k.composition = w.filing AND k.composed_layer = w.layer
    GROUP BY w.root_filing, w.root_layer
) b ON b.root_filing = r.composition AND b.root_layer = r.composed_layer
)
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
           format('%s root(s), %s reaching two levels or more; %s whose own room is not that of '
                  'its fusions added up, %s with a leaf whose factors along the path multiply to '
                  'neither a positive number nor an unstated one, %s leaf arrival(s) unstated%s',
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
        SELECT * FROM rank_composition_closure
    ) c
) p ON true
WHERE a.slug = 'composition_closure'
