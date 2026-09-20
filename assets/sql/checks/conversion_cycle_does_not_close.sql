-- units/conversions.sqlc walked until a unit repeats; the product against one.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    WITH RECURSIVE e AS (
        SELECT * FROM units.conversions
    ),
    walk(start, at, depth, p_low, p_mode, p_high, path, filing, layer) AS (
        SELECT from_unit, to_unit, 1, factor_low, factor_mode, factor_high,
               ARRAY[from_unit, to_unit], filing, layer
        FROM e
        UNION ALL
        SELECT w.start, e.to_unit, w.depth + 1,
               w.p_low * e.factor_low, w.p_mode * e.factor_mode, w.p_high * e.factor_high,
               w.path || e.to_unit, w.filing, w.layer
        FROM walk w
        JOIN e ON e.from_unit = w.at
        WHERE NOT (e.to_unit = ANY (w.path[2:array_length(w.path, 1)]))
    )
    SELECT w.filing, w.layer,
           NOT (w.p_low <= 1 AND w.p_high >= 1) AS violates,
           format('%s: the factors multiply to [%s, %s] round it, and one %s inside',
                  array_to_string(w.path, ' to '),
                  round(w.p_low, 6), round(w.p_high, 6),
                  CASE WHEN w.p_low <= 1 AND w.p_high >= 1 THEN 'lies' ELSE 'DOES NOT lie' END)
           AS detail
    FROM walk w
    WHERE w.at = w.start
      AND w.start = (SELECT min(u) FROM unnest(w.path) u)
) p ON true
WHERE r.slug = 'conversion_cycle_does_not_close'
