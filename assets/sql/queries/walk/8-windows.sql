-- §8 Windows: each shift line's window and the unit its amount counts in.
WITH layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
)
SELECT filing, layer, window_mode, window_unit, amount_unit
FROM (
    SELECT * FROM layers_windows
) w
WHERE layer IN ('shift-line', 'linha-partilhada')
  AND window_mode IS NOT NULL;
