-- pm:Layer/pm:timeSlack with pm:absent/reason = derived, beside pm:Divisibility/pm:window.
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) w
JOIN      (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.absent = 'derived'
