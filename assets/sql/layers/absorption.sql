-- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack, summed across the row in the demand's unit.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE (s.sized AND s.unit IS NOT DISTINCT FROM d.d_unit)
                    OR s.absent = 'notApplicable')                                 AS absorbable,
       count(*)
         FILTER (WHERE (NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable')
                    OR (s.sized AND s.unit IS DISTINCT FROM d.d_unit))        AS unknown
FROM      (
    SELECT * FROM entries.slacks
) s
LEFT JOIN (
    SELECT * FROM layers.demand
) d ON d.filing = s.filing AND d.layer = s.layer
GROUP BY s.filing, s.layer
