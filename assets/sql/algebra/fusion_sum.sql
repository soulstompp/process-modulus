-- composition/fused.sqlc against composition/resolved_quantities.sqlc, composition/parts.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT o.filing || ' / ' || o.layer || ' / ' || o.quantity AS subject,
           f.composition IS NOT NULL
           AND abs(f.sum_low  - r.sum_low)  < 1e-9
           AND abs(f.sum_mode - r.sum_mode) < 1e-9
           AND abs(f.sum_high - r.sum_high) < 1e-9
           AND f.computed_low <= f.computed_mode AND f.computed_mode <= f.computed_high
           AND abs(f.computed_mode - (r.sum_mode - coalesce(e.mode, 0))) < 1e-9
           AND CASE WHEN r.sum_low  - coalesce(e.low,  0) <= r.sum_mode - coalesce(e.mode, 0)
                     AND r.sum_mode - coalesce(e.mode, 0) <= r.sum_high - coalesce(e.high, 0)
                    THEN abs(f.computed_low  - (r.sum_low  - coalesce(e.low,  0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.high, 0))) < 1e-9
                    ELSE abs(f.computed_low  - (r.sum_low  - coalesce(e.high, 0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.low,  0))) < 1e-9 END
           AND f.agrees = (abs(f.computed_low  - d.low)  < 1e-9
                       AND abs(f.computed_mode - d.mode) < 1e-9
                       AND abs(f.computed_high - d.high) < 1e-9) AS holds,
           format('Σ [%s, %s, %s] less [%s, %s, %s] gives [%s, %s, %s] against a filed [%s, %s, %s]',
                  r.sum_low, r.sum_mode, r.sum_high,
                  coalesce(e.low, 0), coalesce(e.mode, 0), coalesce(e.high, 0),
                  f.computed_low, f.computed_mode, f.computed_high,
                  d.low, d.mode, d.high) AS detail
    FROM      (
        SELECT * FROM composition.owed_equality
    ) o
    JOIN      (
        SELECT p.composition, p.composed_layer, s.quantity,
               sum(least(   s.low  * coalesce(p.factor_low, 1),
                            s.low  * coalesce(p.factor_high, 1))) AS sum_low,
               sum(s.mode * coalesce(p.factor_mode, 1))           AS sum_mode,
               sum(greatest(s.high * coalesce(p.factor_low, 1),
                            s.high * coalesce(p.factor_high, 1))) AS sum_high
        FROM      (
            SELECT * FROM composition.parts
        ) p
        JOIN      (
            SELECT * FROM composition.resolved_quantities
        ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
        GROUP BY p.composition, p.composed_layer, s.quantity
    ) r ON r.composition = o.filing AND r.composed_layer = o.layer AND r.quantity = o.quantity
    JOIN      (
        SELECT * FROM layers.summed_quantities
    ) d ON d.filing = o.filing AND d.layer = o.layer AND d.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM eliminations.filed
    ) e ON e.composition = o.filing AND e.composed_layer = o.layer AND e.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM composition.fused
    ) f ON f.composition = o.filing AND f.composed_layer = o.layer AND f.quantity = o.quantity
) p ON true
WHERE a.slug = 'fusion_sum'
