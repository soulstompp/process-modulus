-- composition/fusions.sqlc × pm.summed_quantity, against composition/suspended_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/suspended_quantities' AS subject,
           x.total = x.owing + x.suspended AS holds,
           format('%s fusion quantities = %s no ground reaches + %s suspended',
                  x.total, x.owing, x.suspended) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_fusions ) s
                                  WHERE s.composition = f.filing AND s.composed_layer = f.layer
                                    AND (s.quantity IS NULL OR s.quantity = q.quantity)))    AS owing,
             (SELECT count(*) FROM ( SELECT * FROM composition.suspended_quantities ) s)       AS suspended
         ) x
) p ON true
WHERE a.slug = 'suspended_quantities'
