-- composition/descent.sqlc partitioned by composition/fusions.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/leaves' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s descent rows = %s leaves + %s that name parts (over %s distinct keys)',
                  x.total, x.kept, x.removed, x.keys) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.descent ) d)  AS total,
             (SELECT count(DISTINCT (d.filing, d.layer)) FROM ( SELECT * FROM composition.descent ) d) AS keys,
             (SELECT count(*) FROM ( -- asrt:Part followed to a layer that names no parts of its own.
SELECT d.*
FROM      (
    SELECT * FROM composition.descent
) d
LEFT JOIN (
    SELECT * FROM composition.fusions
) f
       ON f.filing = d.filing AND f.layer = d.layer
WHERE f.filing IS NULL
 ) l)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.descent ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fusions ) f
                              WHERE f.filing = d.filing AND f.layer = d.layer)) AS removed
         ) x
) p ON true
WHERE a.slug = 'leaves'
