-- §3  The parts going into each composed layer, with their conversion factors.
-- composition/parts.sqlc against layers/demand.sqlc; F and Phi live in one table.
SELECT p.composition                      AS "composition!",
       p.composed_layer                   AS "composed!",
       coalesce(p.factor_low, 1)::float8  AS "f_low!",
       coalesce(p.factor_mode, 1)::float8 AS "f_mode!",
       coalesce(p.factor_high, 1)::float8 AS "f_high!",
       d.d_low::float8                    AS "d_low!",
       d.d_mode::float8                   AS "d_mode!",
       d.d_high::float8                   AS "d_high!"
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
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN (
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
  ON d.filing = p.part_filing AND d.layer = p.part_layer
ORDER BY p.composition, p.composed_layer, p.part_layer
