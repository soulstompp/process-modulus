-- pm:Divisibility/window with pm:absent/reason = notApplicable, against pm:Claim/pm:denominator.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT w.filing, w.layer,
           r.filing IS NOT NULL AS violates,
           CASE WHEN r.filing IS NOT NULL
                THEN format('%s runs on a period, so the duty cycle question is answerable',
                            w.amount_unit)
                ELSE format('%s has no period under the line, so the question really is malformed',
                            w.amount_unit)
           END AS detail
    FROM      (
        SELECT * FROM layers.windows
    ) w
    LEFT JOIN (
        SELECT * FROM units.with_a_period
    ) r USING (filing, layer)
    WHERE w.window_absent = 'notApplicable'
      AND w.amount_unit IS NOT NULL
) p ON true
WHERE r.slug = 'window_not_applicable_on_a_rate'
