-- composition/fusions.sqlc against the fusions that are a row of F Phi.
WITH composition_fusions AS (
-- asrt:Fusion: the composed layer it names, and asrt:observed.
SELECT f.composition AS filing, f.composed_layer AS layer, f.observed
FROM pm.fusion f
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
-- asrt:Fusion/asrt:Part folded onto its fusion: the fibre size, and the block dimension it fixes.
SELECT p.composition,
       p.composed_layer,
       count(*)     AS parts,
       count(*) - 1 AS kernel_dim
FROM (
    SELECT * FROM composition_parts
) p
GROUP BY p.composition, p.composed_layer
)
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
