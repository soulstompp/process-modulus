-- layers/summed_quantities.sqlc partitioned by the query the roster names as this law's subject.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'queries/matrices/3b-composed-quantities' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s stated figures = %s carried + %s suspended', x.total, x.kept, x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) d
               WHERE d.low IS NOT NULL)                                              AS total,
             (SELECT count(*) FROM ( -- §3  What each layer actually filed, per quantity, and the elimination to subtract from it.
-- layers/summed_quantities.sqlc minus composition/suspended_quantities.sqlc, with eliminations/filed.sqlc.
SELECT d.filing                     AS "filing!",
       d.layer                      AS "layer!",
       d.quantity::text             AS "quantity!",
       d.low::float8                AS "x_low!",
       d.mode::float8               AS "x_mode!",
       d.high::float8               AS "x_high!",
       coalesce(e.low, 0)::float8   AS "e_low!",
       coalesce(e.mode, 0)::float8  AS "e_mode!",
       coalesce(e.high, 0)::float8  AS "e_high!"
FROM      (
    SELECT * FROM layers.summed_quantities
) d
LEFT JOIN (
    SELECT * FROM composition.suspended_quantities
) s
       ON s.composition = d.filing AND s.composed_layer = d.layer
      AND s.quantity = d.quantity
LEFT JOIN (
    SELECT * FROM eliminations.filed
) e
       ON e.composition = d.filing AND e.composed_layer = d.layer
      AND e.quantity = d.quantity
WHERE s.composition IS NULL
  AND d.low IS NOT NULL
 ) k)
                                                                                     AS kept,
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) d
               WHERE d.low IS NOT NULL
                 AND EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_quantities ) s
                              WHERE s.composition = d.filing AND s.composed_layer = d.layer
                                AND s.quantity = d.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'composed_quantities'
