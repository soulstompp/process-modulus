-- pm:Divisibility/pm:quantum against pm:Nameplate/pm:amount.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.quantum_mode IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN l.quantum_unit IS DISTINCT FROM l.amount_unit     THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.quantum_mode IS NULL THEN format('quantum %s', l.quantum_absent)
                ELSE format('%s of %s against a rating in %s',
                            l.quantum_mode, l.quantum_unit, l.amount_unit) END AS detail
    FROM (
        SELECT * FROM layers.lumpy
    ) l
) p ON true
WHERE a.slug = 'whole_multiple'
