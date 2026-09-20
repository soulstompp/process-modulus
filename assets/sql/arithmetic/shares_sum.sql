-- pm:Remainder/pm:holder against the layer the magnitude belongs to.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT r.filing, r.layer,
           CASE WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[r.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('%s holders, %s unstated%s', h.holders, h.unstated,
                  CASE WHEN h.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', h.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM entries.holder_totals
    ) h USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_sum'
