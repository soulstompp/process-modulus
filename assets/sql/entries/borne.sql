-- pm:Remainder/pm:holder summed against the slack it names, keyed by pm:Remainder/pm:absorber.
SELECT b.filing, b.layer, b.buffer, b.borne, s.mode AS slack_mode, s.unit AS slack_unit, b.unstated
FROM (
    SELECT p.filing, p.layer, a.buffer, h.served_mode AS borne, h.unstated
    FROM      (
        SELECT * FROM layers.pressed
    ) p
    JOIN      (
        SELECT * FROM layers.absorber
    ) a USING (filing, layer)
    JOIN      (
        SELECT * FROM folds.served_totals
    ) h USING (filing, layer)
    WHERE p.sign = 'interference'
) b
JOIN (
    SELECT * FROM entries.slacks
) s USING (filing, layer, buffer)
WHERE s.mode IS NOT NULL
