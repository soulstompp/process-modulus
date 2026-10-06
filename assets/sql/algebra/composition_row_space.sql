-- rank/composition_row_space.sqlc against rank/composition_kernel.sqlc, then against
-- rank/composition_image.sqlc.
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
rank_composition_row_space AS (
-- asrt:Fusion/asrt:Part counted per fusion: the direction its figure reads,
-- and how well that direction is known.
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
    SELECT * FROM composition_parts
) p
GROUP BY p.composition, p.composed_layer
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
composition_fusions AS (
-- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f
),
rank_composition_image AS (
-- composition/fusions.sqlc against the fusions that have a resolved part.
SELECT f.filing                                         AS composition,
       count(*)                                         AS declared,
       count(k.composition)                             AS rank,
       count(*) - count(k.composition)                  AS left_null
FROM      (
    SELECT * FROM composition_fusions
) f
LEFT JOIN (
    SELECT * FROM rank_composition_kernel
) k ON k.composition = f.filing AND k.composed_layer = f.layer
GROUP BY f.filing
)
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
           format('%s fusion(s), %s with room to move parts alone; %s whose figure moves '
                  'other than one way, %s not adding up to their parts, %s at odds with the fold%s',
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
            SELECT * FROM rank_composition_row_space
        ) r
        LEFT JOIN (
            SELECT * FROM rank_composition_kernel
        ) k ON k.composition = r.composition AND k.composed_layer = r.composed_layer
    ) x
    UNION ALL
    SELECT 'rank/composition_row_space / the count along the fusions',
           y.blocks > 0 AND z.matrix_rows > 0 AND y.blocks = z.matrix_rows
           AND y.parts = y.blocks + y.kernel                                         AS holds,
           format('%s figure(s) the parts can move, fusion by fusion, and %s fusion rows; '
                  '%s part(s) over %s fusion(s) leave room for %s move(s) of parts alone',
                  y.blocks, z.matrix_rows, y.parts, y.blocks, y.kernel)
    FROM       (
        SELECT coalesce(sum(s.row_dim),    0) AS blocks,
               coalesce(sum(s.parts),      0) AS parts,
               coalesce(sum(s.kernel_dim), 0) AS kernel
        FROM (
            SELECT * FROM rank_composition_row_space
        ) s
    ) y
    CROSS JOIN (
        SELECT coalesce(sum(i.rank), 0) AS matrix_rows
        FROM (
            SELECT * FROM rank_composition_image
        ) i
    ) z
) p ON true
WHERE a.slug = 'composition_row_space'
