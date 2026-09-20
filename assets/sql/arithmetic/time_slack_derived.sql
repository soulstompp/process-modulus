-- pm:Layer/pm:timeSlack with pm:absent/reason = derived, against the clearance it stands for.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT t.filing, t.layer,
           CASE WHEN r.filing IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN r.unit IS DISTINCT FROM r.amount_unit        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN r.filing IS NULL THEN 'no demand and nameplate to take a clearance from'
                WHEN r.unit IS DISTINCT FROM r.amount_unit
                     THEN format('a demand in %s against a nameplate in %s', r.unit, r.amount_unit)
                ELSE format('the clearance [%s, %s, %s] %s is the slack',
                            greatest(r.r_low, 0), greatest(r.r_mode, 0), greatest(r.r_high, 0),
                            r.unit) END AS detail
    FROM      (
        SELECT * FROM entries.derived_time_slacks
    ) t
    LEFT JOIN (
        SELECT * FROM layers.remainder
    ) r USING (filing, layer)
) p ON true
WHERE a.slug = 'time_slack_derived'
