-- §3  What each composed layer actually filed, and the elimination to subtract from it.
-- layers/demand.sqlc minus composition/suspended_fusions.sqlc, with pm.elimination.
SELECT d.filing                     AS "filing!",
       d.layer                      AS "layer!",
       d.d_low::float8              AS "d_low!",
       d.d_mode::float8             AS "d_mode!",
       d.d_high::float8             AS "d_high!",
       coalesce(e.low, 0)::float8   AS "e_low!",
       coalesce(e.mode, 0)::float8  AS "e_mode!",
       coalesce(e.high, 0)::float8  AS "e_high!"
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
LEFT JOIN (
    -- the two pm:Absent reason="unmeasured" filings that lift the sum rule.
-- pm:Fusion/pm:Eliminations with pm:Absent reason="unmeasured".
SELECT es.composition, es.composed_layer,
       'the search was never made' AS suspended_because,
       es.note
FROM pm.elimination_search es
WHERE es.absent = 'unmeasured'
UNION ALL
-- pm:Eliminations/pm:Elimination quantity="demand" with pm:Absent reason="unmeasured".
SELECT e.composition, e.composed_layer,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM pm.elimination e
WHERE e.quantity = 'demand' AND e.absent = 'unmeasured'


) s
       ON s.composition = d.filing AND s.composed_layer = d.layer
LEFT JOIN pm.elimination e
       ON e.composition = d.filing AND e.composed_layer = d.layer
      AND e.quantity = 'demand'
WHERE s.composition IS NULL
