-- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime
FROM pm.elimination_between b

) b

) b
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = b.notation
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer
