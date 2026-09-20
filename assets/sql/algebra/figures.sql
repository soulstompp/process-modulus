-- layers/figures.sqlc against layers/demand.sqlc and layers/nameplate.sqlc counted by themselves.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/figures' AS subject,
           x.pairs = x.demands + x.nameplates - x.both AS holds,
           format('%s layers with a figure = %s with a demand + %s with a nameplate - %s with both',
                  x.pairs, x.demands, x.nameplates, x.both) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.figures ) f)     AS pairs,
             (SELECT count(*) FROM ( SELECT * FROM layers.demand ) d)      AS demands,
             (SELECT count(*) FROM ( SELECT * FROM layers.nameplate ) n)   AS nameplates,
             (SELECT count(*) FROM ( SELECT * FROM layers.demand ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM layers.nameplate ) n
                              WHERE n.filing = d.filing AND n.layer = d.layer))  AS both
         ) x
) p ON true
WHERE a.slug = 'figures'
