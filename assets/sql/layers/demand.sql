-- composition/resolved_quantities.sqlc's pm:Layer/pm:Demand, where it has a figure.
SELECT q.filing, q.layer,
       q.low  AS d_low,
       q.mode AS d_mode,
       q.high AS d_high,
       q.unit AS d_unit,
       q.low = q.high AS is_a_point,
       q.derived AS d_derived
FROM (
    SELECT * FROM composition.resolved_quantities
) q
WHERE q.quantity = 'demand'
  AND q.low IS NOT NULL
