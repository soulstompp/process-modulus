-- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack, summed across the row.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE s.sized OR s.absent = 'notApplicable')            AS absorbable,
       count(*)
         FILTER (WHERE NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable') AS unknown
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
GROUP BY s.filing, s.layer
