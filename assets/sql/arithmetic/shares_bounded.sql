-- the slack named by pm:Remainder/pm:absorber, against the served pm:Remainder/pm:holder under interference.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT s.filing, s.layer,
           CASE WHEN s.mode IS NULL                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[s.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN s.mode IS NULL
                     THEN format('the %s buffer is %s', s.buffer, s.absent)
                WHEN h.unstated > 0
                     THEN format('%s of %s shares unstated%s, against a %s slack of %s',
                                 h.unstated, h.holders,
                                 CASE WHEN h.derived > 0
                                      THEN format(' (%s of them filed as `sharesSum`''s output, which nothing here computes)', h.derived)
                                      ELSE '' END,
                                 s.buffer, s.mode)
                ELSE format('%s shares bounded by a %s slack of %s',
                            h.holders, s.buffer, s.mode)
           END AS detail
    FROM      (
        SELECT * FROM entries.absorbing_slack
    ) s
    JOIN      (
        SELECT * FROM folds.served_totals
    ) h USING (filing, layer)
    JOIN      (
        SELECT DISTINCT r.filing, r.layer
        FROM (
            SELECT * FROM layers.pressed
        ) r
        WHERE r.sign = 'interference'
    ) x USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_bounded'
