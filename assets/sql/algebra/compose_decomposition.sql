-- algebra/roster.sqlc against rank/compose_measures.sqlc: the directory cut puts each template in
-- one directory.
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
rank_compose_edges AS (
-- public.compose_edge, generated by examples/compositions/main.rs from assets/sqlc/.
SELECT e.parent, e.child, e.splices, e.inner_joins
FROM public.compose_edge e
),
rank_compose_measures AS (
-- rank/compose_edges.sqlc, walked for components both ways, counted whole and by directory.
WITH RECURSIVE
edge AS (
    SELECT DISTINCT e.parent AS a, e.child AS b
    FROM ( SELECT * FROM rank_compose_edges ) e
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
)
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    SELECT 'rank/compose_decomposition' AS subject,
           x.whole_nodes = x.cut_nodes
             AND x.whole_edges = x.cut_edges + x.crossing                            AS holds,
           format('%s templates whole, %s over %s directories; %s edges, %s kept, %s crossing',
                  x.whole_nodes, x.cut_nodes, x.directories,
                  x.whole_edges, x.cut_edges, x.crossing)                            AS detail
    FROM ( SELECT
             (SELECT m.n_nodes FROM ( SELECT * FROM rank_compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_nodes,
             (SELECT coalesce(sum(m.n_nodes), 0) FROM ( SELECT * FROM rank_compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_nodes,
             (SELECT m.m_edges FROM ( SELECT * FROM rank_compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_edges,
             (SELECT coalesce(sum(m.m_edges), 0) FROM ( SELECT * FROM rank_compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_edges,
             (SELECT count(*) FROM ( SELECT * FROM rank_compose_edges ) e
               WHERE (CASE WHEN position('/' IN e.parent) > 0
                           THEN split_part(e.parent, '/', 1) ELSE '(root)' END)
                  <> (CASE WHEN position('/' IN e.child) > 0
                           THEN split_part(e.child, '/', 1) ELSE '(root)' END))       AS crossing,
             (SELECT count(*) FROM ( SELECT * FROM rank_compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS directories
         ) x
) p ON true
WHERE a.slug = 'compose_decomposition'
