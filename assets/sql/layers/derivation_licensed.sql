-- pm:Divisibility/window absent for a licensing reason.
SELECT w.filing, w.layer, w.window_absent AS licensed_because
FROM (
    -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

) w
WHERE w.window_absent IN ('none', 'notApplicable')
