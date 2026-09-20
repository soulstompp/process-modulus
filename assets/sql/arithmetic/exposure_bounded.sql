-- every slack on the layer accounted for and empty, against pm:Remainder/pm:holder of kind customer and unrealised.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT x.filing, x.layer,
           CASE WHEN u.unstated > 0                        THEN 'suspended'::public.arithmetic_verdict
                WHEN u.share_units <> ARRAY[x.unit]        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('exposure %s in %s against %s unserved holder(s)%s',
                  round(x.exposure, 3), x.unit, u.holders,
                  CASE WHEN u.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', u.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers.unabsorbed_exposure
    ) x
    JOIN      (
        SELECT * FROM entries.unserved_totals
    ) u USING (filing, layer)
) p ON true
WHERE a.slug = 'exposure_bounded'
