-- composition/resolved_quantities.sqlc's demand against its nameplate, before layers/remainder.sqlc drops either,
-- with composition/figureless_remainders.sqlc for a layer whose n - d is not its remainder.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.low IS NULL OR n.low IS NULL   THEN 'suspended'::public.arithmetic_verdict
                WHEN d.unit IS DISTINCT FROM n.unit   THEN 'not comparable'::public.arithmetic_verdict
                WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.low IS NULL AND n.low IS NULL
                     THEN format('demand %s and nameplate %s', d.why, n.why)
                WHEN d.low IS NULL THEN format('demand %s', d.why)
                WHEN n.low IS NULL THEN format('nameplate %s', n.why)
                WHEN d.unit IS DISTINCT FROM n.unit
                     THEN format('%s against %s', d.unit, n.unit)
                WHEN g.filing IS NOT NULL
                     THEN 'a conversion with width scales both totals, and the composed remainder is lifted'
                ELSE format('both in %s', d.unit) END AS detail
    FROM      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition.resolved_quantities ) q
    ) d
    JOIN      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition.resolved_quantities ) q
    ) n ON n.filing = d.filing AND n.layer = d.layer AND n.quantity = 'nameplate'
    LEFT JOIN (
        SELECT * FROM composition.figureless_remainders
    ) g ON g.filing = d.filing AND g.layer = d.layer
    WHERE d.quantity = 'demand'
) p ON true
WHERE a.slug = 'remainder'
