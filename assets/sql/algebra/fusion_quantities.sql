-- layers/summed_quantities.sqlc against composition/fusion_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/fusion_quantities' AS subject,
           x.total = x.leaves + x.fused AS holds,
           format('%s summed quantities = %s of layers no fusion names + %s of composed layers',
                  x.total, x.leaves, x.fused) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) s)  AS total,
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) s
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fusions ) f
                                  WHERE f.filing = s.filing AND f.layer = s.layer))   AS leaves,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusion_quantities ) q) AS fused
         ) x
) p ON true
WHERE a.slug = 'fusion_quantities'
