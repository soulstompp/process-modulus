-- eliminations/searched.sqlc answering "notApplicable", beside folds/fusion_parts.sqlc.
WITH eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
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
folds_fusion_parts AS (
-- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM composition_part_references
) r
GROUP BY r.composition, r.composed_layer
)
SELECT es.composition, es.composed_layer, f.parts
FROM (
    SELECT * FROM eliminations_searched
) es
JOIN (
    SELECT * FROM folds_fusion_parts
) f
  ON f.composition = es.composition AND f.composed_layer = es.composed_layer
WHERE es.answer = 'notApplicable'
  AND f.parts > 0
