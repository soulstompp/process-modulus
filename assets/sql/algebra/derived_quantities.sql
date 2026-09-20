-- composition/derived_quantities.sqlc against composition/parts.sqlc, composition/resolved_quantities.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT d.filing || ' / ' || d.layer || ' / ' || d.quantity AS subject,
           (d.low IS NULL) = (x.low IS NULL)
           AND (d.low IS NULL
                OR (abs(d.low  - x.low)  < 1e-9 AND abs(d.mode - x.mode) < 1e-9
                    AND abs(d.high - x.high) < 1e-9))                          AS holds,
           CASE WHEN d.low IS NOT NULL
                THEN format('walked [%s, %s, %s], one level [%s, %s, %s]',
                            d.low, d.mode, d.high, x.low, x.mode, x.high)
                ELSE format('not computable: %s; one level %s', d.blocked_because,
                            CASE WHEN x.low IS NULL THEN 'cannot compute it either'
                                 ELSE format('gives [%s, %s, %s]', x.low, x.mode, x.high) END)
           END                                                                 AS detail
    FROM (
        SELECT * FROM composition.derived_quantities
    ) d
    LEFT JOIN (
        SELECT s.filing, s.layer, s.quantity,
               CASE WHEN ok THEN s_low  - e_low  END AS low,
               CASE WHEN ok THEN s_mode - e_mode END AS mode,
               CASE WHEN ok THEN s_high - e_high END AS high
        FROM (
            SELECT t.*,
                   t.parts > 0 AND t.parts = t.resolved_parts AND t.figures = t.parts
                   AND t.searched_ok AND t.e_ok
                   AND t.s_low - t.e_low <= t.s_mode - t.e_mode
                   AND t.s_mode - t.e_mode <= t.s_high - t.e_high AS ok
            FROM (
                SELECT f.filing, f.layer, f.quantity,
                       coalesce(r.parts, 0) AS parts,
                       count(p.part_layer) AS resolved_parts,
                       count(q.low) FILTER (WHERE p.factor_state IN ('omitted', 'stated')) AS figures,
                       sum(least(   q.low  * coalesce(p.factor_low, 1),
                                    q.low  * coalesce(p.factor_high, 1))) AS s_low,
                       sum(q.mode * coalesce(p.factor_mode, 1))           AS s_mode,
                       sum(greatest(q.high * coalesce(p.factor_low, 1),
                                    q.high * coalesce(p.factor_high, 1))) AS s_high,
                       coalesce(max(e.low),  0) AS e_low,
                       coalesce(max(e.mode), 0) AS e_mode,
                       coalesce(max(e.high), 0) AS e_high,
                       bool_and(e.absent IS NULL AND e.derivation IS NULL) IS NOT FALSE AS e_ok,
                       coalesce(max(es.answer::text), '') <> 'unmeasured' AS searched_ok
                FROM      (
                    SELECT s.filing, s.layer, s.quantity
                    FROM ( SELECT * FROM layers.summed_quantities ) s
                    WHERE s.derivation IS NOT NULL
                ) f
                LEFT JOIN (
                    SELECT * FROM folds.fusion_parts
                ) r ON r.composition = f.filing AND r.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM composition.parts
                ) p ON p.composition = f.filing AND p.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM composition.resolved_quantities
                ) q ON q.filing = p.part_filing AND q.layer = p.part_layer AND q.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM eliminations.filed
                ) e ON e.composition = f.filing AND e.composed_layer = f.layer AND e.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM eliminations.searched
                ) es ON es.composition = f.filing AND es.composed_layer = f.layer
                GROUP BY f.filing, f.layer, f.quantity, r.parts
            ) t
        ) s
    ) x ON x.filing = d.filing AND x.layer = d.layer AND x.quantity = d.quantity
) p ON true
WHERE a.slug = 'derived_quantities'
