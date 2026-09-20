-- pm:Remainder/pm:holder against the three slack elements, keyed by pm:Remainder/pm:absorber through pm.buffer_term.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT b.filing, b.layer,
           coalesce(b.borne > b.slack_mode + 1e-9, false) AS violates,
           format('%s attributed to the %s buffer, whose slack is %s',
                  b.borne, b.buffer, b.slack_mode) AS detail
    FROM (
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

    ) b
    WHERE b.unstated = 0
) p ON true
WHERE r.slug = 'share_exceeds_slack'
