-- §3  What each composed layer actually filed, and the elimination to subtract from it.
--
-- The right-hand side of `x_composed = F Φ x_parts − e`. The example compares this against
-- the matrix product built from 3a-fusion-parts.sql.
--
-- ⛔⛔⛔ THE FUSIONS THAT OWE NO EQUALITY ARE EXCLUDED, AND THAT LAST PREDICATE IS THE
-- WHOLE OF IT. A composer who states they never looked for double counting has not claimed
-- their figure equals the sum of its parts, and asserting it anyway is the exact defect
-- `StatedEliminations` was added to prevent — arriving in the CHECKER instead of in the
-- document.
-- ⭐ `none` and `notApplicable` still owe the sum exactly. Only `unmeasured` suspends it,
-- and before the wrapper existed all three were an empty list.
SELECT l.filing                     AS "filing!",
       l.layer                      AS "layer!",
       l.demand_low::float8         AS "d_low!",
       l.demand_mode::float8        AS "d_mode!",
       l.demand_high::float8        AS "d_high!",
       coalesce(e.low, 0)::float8   AS "e_low!",
       coalesce(e.mode, 0)::float8  AS "e_mode!",
       coalesce(e.high, 0)::float8  AS "e_high!"
FROM pm.layer l
LEFT JOIN pm.elimination e
       ON e.composition = l.filing
      AND e.composed_layer = l.layer
      AND e.quantity = 'demand'
LEFT JOIN pm.elimination_search es
       ON es.composition = l.filing
      AND es.composed_layer = l.layer
WHERE l.demand_low IS NOT NULL
  AND (es.absent IS DISTINCT FROM 'unmeasured'::pm.absence_reason)
