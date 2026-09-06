-- pm:Supply/pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT n.filing, n.layer,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       s.low    AS capacity_low,
       s.mode   AS capacity_slack,
       s.high   AS capacity_high,
       s.absent AS capacity_absent
FROM pm.nameplate n
LEFT JOIN (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s ON s.filing = n.filing AND s.layer = n.layer AND s.buffer = 'capacity'
WHERE n.draw_mode   IS NOT NULL
  AND n.amount_mode IS NOT NULL
