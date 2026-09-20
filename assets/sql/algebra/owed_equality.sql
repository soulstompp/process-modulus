-- composition/fusions.sqlc for every quantity, partitioned by composition/suspended_quantities.sqlc and composition/derived_fusions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/owed_equality' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s fusion quantities = %s owing + %s suspended or derived', x.total, x.kept,
                  x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_equality ) o)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE EXISTS (SELECT 1
                             FROM ( SELECT s.composition AS filing, s.composed_layer AS layer,
                                           s.quantity
                                    FROM ( SELECT * FROM composition.suspended_quantities ) s
                                    UNION ALL
                                    SELECT d.filing, d.layer, d.quantity
                                    FROM ( SELECT * FROM composition.derived_fusions ) d ) b
                             WHERE b.filing = f.filing AND b.layer = f.layer
                               AND b.quantity = q.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'owed_equality'
