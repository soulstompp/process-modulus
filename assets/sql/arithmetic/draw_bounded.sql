-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.capacity_slack IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit       THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.capacity_slack IS NULL
                     THEN format('the capacity buffer is %s', d.capacity_absent)
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit
                     THEN format('a draw in %s against a rating in %s and a slack in %s',
                                 d.draw_unit, d.n_unit, d.capacity_unit)
                ELSE format('draw, rating and slack all in %s', d.n_unit) END AS detail
    FROM (
        SELECT * FROM layers.drawn
    ) d
) p ON true
WHERE a.slug = 'draw_bounded'
