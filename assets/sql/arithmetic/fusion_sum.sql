-- asrt:Fusion/asrt:Part against asrt:eliminations, via composition/owed_equality.sqlc and composition/derived_quantities.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT f.filing, f.layer,
           CASE WHEN o.owed IS NULL AND d.computed IS NOT TRUE
                THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           concat_ws('; ',
                     CASE WHEN o.owed IS NOT NULL THEN format('owed exactly for %s', o.owed) END,
                     d.derived,
                     s.suspended) AS detail
    FROM      (
        SELECT * FROM composition.fusions
    ) f
    LEFT JOIN (
        SELECT o.filing, o.layer, string_agg(o.quantity::text, ', ' ORDER BY o.quantity) AS owed
        FROM (
            SELECT * FROM composition.owed_equality
        ) o
        GROUP BY o.filing, o.layer
    ) o USING (filing, layer)
    LEFT JOIN (
        SELECT g.composition, g.composed_layer,
               string_agg(DISTINCT format('suspended for %s: %s',
                                          coalesce(g.quantity::text, 'every quantity'),
                                          g.suspended_because), '; ') AS suspended
        FROM (
            SELECT * FROM composition.suspension_grounds
        ) g
        GROUP BY g.composition, g.composed_layer
    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
    LEFT JOIN (
        SELECT d.filing, d.layer, bool_or(q.low IS NOT NULL) AS computed,
               string_agg(CASE WHEN q.low IS NOT NULL
                               THEN format('derived for %s: computed [%s, %s, %s]', d.quantity,
                                           q.low, q.mode, q.high)
                               ELSE format('derived for %s, not computable: %s', d.quantity,
                                           q.blocked_because) END,
                          '; ' ORDER BY d.quantity) AS derived
        FROM      (
            SELECT * FROM composition.derived_fusions
        ) d
        JOIN      (
            SELECT * FROM composition.derived_quantities
        ) q ON q.filing = d.filing AND q.layer = d.layer AND q.quantity = d.quantity
        GROUP BY d.filing, d.layer
    ) d ON d.filing = f.filing AND d.layer = f.layer
) p ON true
WHERE a.slug = 'fusion_sum'
