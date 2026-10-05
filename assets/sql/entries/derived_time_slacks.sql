-- pm:Layer/pm:timeSlack filed as a clearance derivation, beside pm:Divisibility/pm:window.
WITH layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
),
entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
)
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    SELECT * FROM layers_windows
) w
JOIN      (
    SELECT * FROM entries_slacks
) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.derivation = 'clearance'
