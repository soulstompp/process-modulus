-- §1  The remainder and its fit, read off the ranges rather than off a point.
--
-- Every layer that states both a demand range and a nameplate range, with the sign the
-- document filed. The example recomputes `r = n - d` with the bounds CROSSED — the low of
-- a difference pairs n's low against d's HIGH — classifies each layer by ISO 286's
-- criterion, and asserts the answer matches this `sign` column.
--
-- Run it alone and the interesting column is `sign!`: one layer in the whole corpus is a
-- `transition`, which is the case a two-member enumeration could not name.
SELECT l.filing              AS "filing!",
       l.layer               AS "layer!",
       l.demand_low::float8  AS "d_low!",
       l.demand_mode::float8 AS "d_mode!",
       l.demand_high::float8 AS "d_high!",
       n.amount_low::float8  AS "n_low!",
       n.amount_mode::float8 AS "n_mode!",
       n.amount_high::float8 AS "n_high!",
       l.sign::text          AS "sign!"
FROM pm.layer l
JOIN pm.nameplate n USING (filing, layer)
WHERE l.demand_low IS NOT NULL
  AND n.amount_low IS NOT NULL
  AND l.sign IS NOT NULL
ORDER BY l.filing, l.layer
