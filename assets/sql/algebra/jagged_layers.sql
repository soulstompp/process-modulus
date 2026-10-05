-- composition/jagged_layers.sqlc partitioned by eliminations/filed.sqlc, multiplicity preserved.
WITH algebra_roster AS (
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
  ('layer_units',      'a pin is the whole relation: the payload constant on the key, the pinned value reaching it', 'units/conversions', 'dependency', 'set: one row per condition'),
  ('class_domain',     'every class of every declared codomain stands where its count puts it', 'epistemics/class_domain', 'roster',     'set: one row per condition')
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
composition_descent AS (
-- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
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
composition_reachable AS (
-- composition/descent.sqlc unioned with the identity on composition/parts.sqlc: F* = F+ ∪ I.
SELECT DISTINCT root_filing, root_layer, filing, layer
FROM (
    SELECT * FROM composition_descent
) w
  UNION
SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
FROM (
    SELECT * FROM composition_parts
) p
),
composition_jagged_layers AS (
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
    SELECT * FROM composition_parts
) a
JOIN      (
    SELECT * FROM composition_parts
) b ON  b.composition    = a.composition
    AND b.composed_layer = a.composed_layer
    AND (a.part_filing, a.part_layer) < (b.part_filing, b.part_layer)
JOIN      (
    SELECT * FROM composition_reachable
) r1 ON r1.root_filing = a.part_filing AND r1.root_layer = a.part_layer
JOIN      (
    SELECT * FROM composition_reachable
) r2 ON  r2.root_filing = b.part_filing AND r2.root_layer = b.part_layer
     AND r2.filing = r1.filing AND r2.layer = r1.layer
),
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
)
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
             (SELECT count(*) FROM ( SELECT * FROM composition_jagged_layers ) j) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition_jagged_layers ) j
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations_filed ) e
                                  WHERE e.composition = j.filing
                                    AND e.composed_layer = j.layer))            AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition_jagged_layers ) j
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations_filed ) e
                              WHERE e.composition = j.filing
                                AND e.composed_layer = j.layer))                AS removed
         ) x
) p ON true
WHERE a.slug = 'jagged_layers'
