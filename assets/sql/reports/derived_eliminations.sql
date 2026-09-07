-- eliminations/derived.sqlc, with the evidence each composing document attests to.
SELECT s.part_filing || '/' || s.part_layer      AS part,
       s.composition_a || '/' || s.composed_a    AS counted_into,
       s.composition_b || '/' || s.composed_b    AS and_also_into,
       fa.evidence                               AS evidence,
       s.would_double_count_demand               AS demand,
       s.would_double_count_nameplate            AS nameplate,
       s.unit
FROM      (
    -- composition/parts.sqlc crossed with itself on the part each side names, with that part's own figures.
SELECT a.part_filing, a.part_layer,
       a.composition    AS composition_a, a.composed_layer AS composed_a,
       b.composition    AS composition_b, b.composed_layer AS composed_b,
       (a.composition = b.composition) AS within_one_filing,
       d.d_mode         AS would_double_count_demand,
       n.n_mode         AS would_double_count_nameplate,
       d.d_unit         AS unit
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) a
JOIN      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) b ON  b.part_filing = a.part_filing
    AND b.part_layer  = a.part_layer
    AND (a.composition, a.composed_layer) < (b.composition, b.composed_layer)
LEFT JOIN (
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

) d ON d.filing = a.part_filing AND d.layer = a.part_layer
LEFT JOIN (
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

) n ON n.filing = a.part_filing AND n.layer = a.part_layer

) s
JOIN      (
    -- from pm.filing, both evidence values.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f

) fa ON fa.filing = s.composition_a
ORDER BY fa.evidence, 1
