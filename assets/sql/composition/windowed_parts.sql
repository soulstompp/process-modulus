-- asrt:Part's own pm:Divisibility/window against the composed pm:Layer's.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       pw.window_low, pw.window_unit,
       cw.window_low    AS composed_window_low,
       cw.window_absent AS composed_window_absent
FROM      (
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

) p
JOIN      (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) cw
       ON cw.filing = p.composition  AND cw.layer = p.composed_layer
WHERE pw.window_low IS NOT NULL
