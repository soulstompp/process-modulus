-- pm:Layer/pm:timeSlack filed as a clearance derivation, beside pm:Divisibility/pm:window.
SELECT w.filing, w.layer, w.window_low, w.window_unit, w.window_absent
FROM      (
    SELECT * FROM layers.windows
) w
JOIN      (
    SELECT * FROM entries.slacks
) s USING (filing, layer)
WHERE s.buffer = 'time' AND s.derivation = 'clearance'
