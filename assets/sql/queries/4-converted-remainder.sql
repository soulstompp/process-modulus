-- §4  The one layer where a conversion factor is correlated with itself.
--
-- `merge-holding-composition/compute` converts a US part metered per reserved card into
-- GPU-hour. One factor multiplies BOTH the nameplate and the demand, so the two converted
-- intervals move together.
--
-- ⛔ The example takes the filed remainder (`qty_*`) against the remainder RE-DERIVED from
-- the converted nameplate and demand with the bounds crossed. They agree at the mode and
-- nowhere else, because the mode is the one point where the factor is a single number with
-- no spread to double. Both figures are arithmetically correct; only the filed one is the
-- remainder.
SELECT l.qty_low::float8      AS "q_low!",
       l.qty_mode::float8     AS "q_mode!",
       l.qty_high::float8     AS "q_high!",
       l.demand_low::float8   AS "d_low!",
       l.demand_mode::float8  AS "d_mode!",
       l.demand_high::float8  AS "d_high!",
       n.amount_low::float8   AS "n_low!",
       n.amount_mode::float8  AS "n_mode!",
       n.amount_high::float8  AS "n_high!"
FROM pm.layer l
JOIN pm.nameplate n USING (filing, layer)
WHERE l.filing = 'merge-holding-composition'
  AND l.layer = 'compute'
