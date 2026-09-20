-- pm:Divisibility/pm:window/pm:quantum/pm:size with pm:absent/pm:reason = notApplicable.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT w.filing, w.layer,
           w.window_size_absent IS NOT DISTINCT FROM 'notApplicable' AS violates,
           CASE WHEN w.window_size_absent IS NOT NULL
                THEN format('the window is filed as a quantum and its size as %s', w.window_size_absent)
                ELSE format('the window is filed as %s %s', w.window_low, w.window_unit)
           END AS detail
    FROM (
        SELECT * FROM layers.windows
    ) w
    WHERE w.window_low IS NOT NULL OR w.window_size_absent IS NOT NULL
) p ON true
WHERE r.slug = 'window_size_not_applicable'
