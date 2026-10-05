-- pm:Coupling against asrt:Fusion/asrt:Part pairs that contain both of its ends, over the corpus.
WITH entries_couplings AS (
-- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c
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
composition_sibling_parts AS (
-- composition/parts.sqlc crossed with itself on the composed layer and the part filing.
SELECT x.composition, x.composed_layer,
       x.part_filing,
       x.part_layer AS from_layer,
       y.part_layer AS to_layer,
       x.factor_low  AS from_factor_low,  x.factor_mode AS from_factor_mode,
       y.factor_low  AS to_factor_low,    y.factor_mode AS to_factor_mode
FROM (
    SELECT * FROM composition_parts
) x
JOIN (
    SELECT * FROM composition_parts
) y
  ON y.composition    = x.composition
 AND y.composed_layer = x.composed_layer
 AND y.part_filing    = x.part_filing
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
)
SELECT c.filing,
       c.from_layer || ' -> ' || c.to_layer AS coupling,
       CASE WHEN a.composition IS NULL THEN '(no fusion holds both ends)'
            ELSE a.composition || '/' || a.composed_layer END AS absorbed_into,
       left(regexp_replace(c.observation, '\s+', ' ', 'g'), 56) || '...' AS what_was_observed
FROM (
    SELECT * FROM entries_couplings
) c
LEFT JOIN (
    SELECT DISTINCT sp.part_filing AS filing, sp.from_layer, sp.to_layer,
           sp.composition, sp.composed_layer
    FROM (
        SELECT * FROM composition_sibling_parts
    ) sp
) a USING (filing, from_layer, to_layer)
JOIN      (
    SELECT * FROM scope_corpus
) sc USING (filing)
ORDER BY 1, 2
