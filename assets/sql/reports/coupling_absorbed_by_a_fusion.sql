-- pm:Coupling against asrt:Fusion/asrt:Part pairs that contain both of its ends, over the corpus.
SELECT c.filing,
       c.from_layer || ' -> ' || c.to_layer AS coupling,
       CASE WHEN a.composition IS NULL THEN '(no fusion holds both ends)'
            ELSE a.composition || '/' || a.composed_layer END AS absorbed_into,
       left(regexp_replace(c.observation, '\s+', ' ', 'g'), 56) || '...' AS what_was_observed
FROM (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
LEFT JOIN (
    SELECT DISTINCT sp.part_filing AS filing, sp.from_layer, sp.to_layer,
           sp.composition, sp.composed_layer
    FROM (
        -- composition/parts.sqlc crossed with itself on the composed layer and the part filing.
SELECT x.composition, x.composed_layer,
       x.part_filing,
       x.part_layer AS from_layer,
       y.part_layer AS to_layer,
       x.factor_low  AS from_factor_low,  x.factor_mode AS from_factor_mode,
       y.factor_low  AS to_factor_low,    y.factor_mode AS to_factor_mode
FROM (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) x
JOIN (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) y
  ON y.composition    = x.composition
 AND y.composed_layer = x.composed_layer
 AND y.part_filing    = x.part_filing

    ) sp
) a USING (filing, from_layer, to_layer)
JOIN      (
    -- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')

) sc USING (filing)
ORDER BY 1, 2
