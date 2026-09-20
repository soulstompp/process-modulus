-- pm:Layer/pm:timeSlack filed as a clearance derivation, against pm:Divisibility/pm:window.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           lic.filing IS NULL AS violates,
           format('timeSlack is the `clearance` and the window is %s',
                  coalesce(d.window_absent::text,
                           format('%s %s', d.window_low, d.window_unit))) AS detail
    FROM      (
        SELECT * FROM entries.derived_time_slacks
    ) d
    LEFT JOIN (
        -- pm:Divisibility/window: absent notApplicable, or filed as one whole period.
SELECT w.filing, w.layer,
       CASE WHEN w.window_absent IS NOT NULL THEN 'the question has no denominator'
            ELSE 'it runs the whole period' END AS licensed_because
FROM (
    SELECT * FROM layers.windows
) w
WHERE w.window_absent = 'notApplicable'
   OR (w.window_low = 1 AND w.window_low = w.window_high
       AND EXISTS (
           SELECT 1
           FROM (
               SELECT * FROM units.with_a_period
           ) p
           WHERE p.filing = w.filing AND p.layer = w.layer
             AND p.period = w.window_unit
       ))

    ) lic USING (filing, layer)
) p ON true
WHERE r.slug = 'derived_slack_over_a_window'
