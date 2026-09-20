-- folds/part_sums.sqlc summed over every fusion, against composition/converted.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT c.quantity::text AS subject,
           c.parts = f.parts AND c.low = f.low AND c.mode = f.mode AND c.high = f.high AS holds,
           format('%s parts summing to [%s, %s, %s]; the fold holds %s summing to [%s, %s, %s]',
                  c.parts, c.low, c.mode, c.high, f.parts, f.low, f.mode, f.high) AS detail
    FROM (
        SELECT v.quantity, count(*) AS parts, sum(v.low) AS low, sum(v.mode) AS mode,
               sum(v.high) AS high
        FROM (
            SELECT * FROM composition.converted
        ) v
        GROUP BY v.quantity
    ) c
    LEFT JOIN (
        SELECT s.quantity, sum(s.parts) AS parts, sum(s.sum_low) AS low, sum(s.sum_mode) AS mode,
               sum(s.sum_high) AS high
        FROM (
            SELECT * FROM folds.part_sums
        ) s
        GROUP BY s.quantity
    ) f ON f.quantity = c.quantity
) p ON true
WHERE a.slug = 'part_sums'
