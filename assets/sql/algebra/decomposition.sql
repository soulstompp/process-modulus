-- rank/decomposition.sqlc's two scopes, counted: the whole against the sum of the parts.
SELECT a.law, p.subject, p.holds, p.detail
FROM      (
    -- the set-algebraic laws this tree's relations claim to obey.
SELECT * FROM (VALUES
  ('decomposition',    '|E| = Σ_filing |E_filing|',  'rank/decomposition',               'partition',  'bag: one edge counted in both scopes'),
  -- ⭐⭐⭐ NOT A SET IDENTITY, AND IT IS THE FIRST ROW HERE THAT IS NOT. Every other law on this
  --    roster is a cardinality identity over relations. This one is about the compose DAG: which
  --    templates may compose the layer DIMENSION. A dimension reaches every layer by
  --    construction, so a relation composing it hands the whole dimension to every consumer, and
  --    any downstream bound of the form *this reach is inside that reach* goes vacuous. Measured:
  --    one edge put the dimension into 20 of 29 rules' closures.
  ('dimension_use',    'parents(dimension) ⊆ declared', 'algebra/dimension_use',         'roster',     'set: one row per undeclared parent'),
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('jagged_layers',    '|A| = |A∖B| + |A⋉B|',        'queries/observations/14-jagged-layers','difference','bag: one row per doubled layer'),
  ('composed_demand',  '|A| = |A∖B| + |A⋉B|',        'queries/matrices/3b-composed-demand','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('carried',          '|A| = |A∖B| + |A⋉B|',        'composition/carried',              'difference', 'bag: anti-join preserves it'),
  ('owed_remainder',   '|A| = |A∖B| + |A⋉B|',        'composition/owed_remainder',       'difference', 'set'),
  ('settled_remainders','|A| = |A∖B| + |A⋉B|',       'composition/settled_remainders',   'difference', 'bag: one row per path'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('exposure_standing', 'each exposed layer in exactly one standing','layers/exposure_scope','partition','set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL'),
  ('part_regimes',     '|A| = |A∖B| + |A⋉B|',        'checks/part_regime_disagrees',     'difference', 'set: pm.part''s key')
) AS a(slug, law, governs, form, multiplicity)

) a
LEFT JOIN (
    SELECT 'rank/decomposition' AS subject,
           x.whole = x.per_filing AS holds,
           format('%s edges corpus-wide = %s summed over %s filings, across %s graphs',
                  x.whole, x.per_filing, x.filings, x.graphs) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.from_node, g.to_node
                 FROM ( -- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
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

) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    -- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       part.unit AS from_unit,
       comp.unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
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
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) part ON part.filing = p.part_filing AND part.layer = p.part_layer
      AND part.quantity = 'nameplate'
JOIN      (
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = 'nameplate'
WHERE p.factor_low IS NOT NULL

) c
 ) g) e)                      AS whole,
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.filing, g.from_node, g.to_node
                 FROM ( -- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
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

) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    -- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       part.unit AS from_unit,
       comp.unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
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
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) part ON part.filing = p.part_filing AND part.layer = p.part_layer
      AND part.quantity = 'nameplate'
JOIN      (
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = 'nameplate'
WHERE p.factor_low IS NOT NULL

) c
 ) g) e)                      AS per_filing,
             (SELECT count(DISTINCT g.filing)
              FROM ( -- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
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

) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    -- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       part.unit AS from_unit,
       comp.unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
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
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) part ON part.filing = p.part_filing AND part.layer = p.part_layer
      AND part.quantity = 'nameplate'
JOIN      (
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = 'nameplate'
WHERE p.factor_low IS NOT NULL

) c
 ) g)                            AS filings,
             -- ⛔ `2` WAS A LITERAL HERE, AND A THIRD GRAPH WOULD NOT HAVE MOVED IT. The claimant
             --    graph has no edges today, so the number was right and unreadable: nothing said
             --    whether it meant *this model composes two graphs* or *two of them have edges*.
             (SELECT count(DISTINCT g.graph)
              FROM ( -- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
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

) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    -- asrt:Part/asrt:factor at the nameplate, as part-layer-unit to composed-layer-unit.
SELECT DISTINCT
       part.unit AS from_unit,
       comp.unit AS to_unit,
       p.factor_low, p.factor_mode, p.factor_high,
       p.composition AS filing, p.composed_layer AS layer
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
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) part ON part.filing = p.part_filing AND part.layer = p.part_layer
      AND part.quantity = 'nameplate'
JOIN      (
    -- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand' AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate',
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n
UNION ALL
SELECT s.filing, s.layer, s.buffer || 'Slack',
       s.low, s.mode, s.high, s.unit
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.low IS NOT NULL

) comp ON comp.filing = p.composition AND comp.layer = p.composed_layer
      AND comp.quantity = 'nameplate'
WHERE p.factor_low IS NOT NULL

) c
 ) g)                            AS graphs
         ) x
) p ON true
WHERE a.slug = 'decomposition'
