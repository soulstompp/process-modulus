-- pm:Remainder/pm:quantity against the layer's own r = n - d.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.qty_low IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN l.qty_unit IS DISTINCT FROM l.unit      THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.qty_low IS NULL THEN format('the quantity is %s', l.qty_absent)
                ELSE format('filed %s %s against a derived magnitude %s %s',
                            l.qty_mode, l.qty_unit, round(l.m_mode, 3), l.unit) END AS detail
    FROM      (
        SELECT * FROM layers.filed_against_derived
    ) l
) p ON true
WHERE a.slug = 'filed_remainder'
