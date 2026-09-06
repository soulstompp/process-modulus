-- §4  The one layer where a conversion factor is correlated with itself.
-- layers/filed_against_derived.sqlc at the one layer with a spread conversion factor.
SELECT r.qty_low::float8      AS "q_low!",
       r.qty_mode::float8     AS "q_mode!",
       r.qty_high::float8     AS "q_high!",
       r.d_low::float8        AS "d_low!",
       r.d_mode::float8       AS "d_mode!",
       r.d_high::float8       AS "d_high!",
       r.n_low::float8        AS "n_low!",
       r.n_mode::float8       AS "n_mode!",
       r.n_high::float8       AS "n_high!"
FROM (
    -- layers/filed_remainders.sqlc against layers/remainder.sqlc, on the layer they share.
SELECT l.filing, l.layer,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       r.r_low, r.r_mode, r.r_high, r.unit,
       r.d_low, r.d_mode, r.d_high,
       r.n_low, r.n_mode, r.n_high, r.amount_unit,
       r.sign, r.derived_fit
FROM      (
    -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent
FROM pm.layer l
WHERE l.remainder_absent IS NULL

) l
JOIN      (
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

) r USING (filing, layer)

) r
WHERE r.filing = 'merge-holding-composition'
  AND r.layer  = 'compute'
