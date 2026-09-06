-- composition/parts.sqlc against layers/lumpy.sqlc, folded by gcd over each composed layer.
WITH RECURSIVE base AS (
    SELECT p.composition, p.composed_layer, l.quantum_unit, l.quantum_mode
    FROM (
        -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
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
        -- pm:Nameplate/pm:Divisibility with a pm:LumpyQuantum.
SELECT r.*
FROM (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
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
JOIN      (
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

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) r
WHERE r.lumpy

    ) l ON l.filing = p.part_filing AND l.layer = p.part_layer
    WHERE l.quantum_mode IS NOT NULL AND l.quantum_mode > 0
),
shape AS (
    SELECT composition, composed_layer,
           count(*)                      AS parts,
           count(DISTINCT quantum_unit)  AS units,
           min(quantum_unit)             AS unit
    FROM base GROUP BY composition, composed_layer
),
ordered AS (
    SELECT b.*, row_number() OVER (PARTITION BY b.composition, b.composed_layer
                                   ORDER BY b.quantum_unit, b.quantum_mode) AS i
    FROM base b
),
fold AS (
    SELECT composition, composed_layer, i, quantum_mode AS g FROM ordered WHERE i = 1
  UNION ALL
    SELECT o.composition, o.composed_layer, o.i, gcd(f.g, o.quantum_mode)
    FROM fold f
    JOIN ordered o ON o.composition    = f.composition
                  AND o.composed_layer = f.composed_layer
                  AND o.i              = f.i + 1
)
SELECT s.composition, s.composed_layer, s.parts, s.units,
       CASE WHEN s.units = 1 THEN s.unit END                    AS unit,
       CASE WHEN s.units = 1 THEN f.g      END                  AS composed_quantum,
       CASE WHEN s.units > 1 THEN 'notApplicable'::pm.absence_reason END AS absent
FROM shape s
JOIN fold  f ON f.composition = s.composition
            AND f.composed_layer = s.composed_layer
            AND f.i = s.parts
