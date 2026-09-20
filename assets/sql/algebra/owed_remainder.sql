-- composition/fusions.sqlc partitioned by composition/suspended_remainders.sqlc, bounded by
-- composition/owed_equality.sqlc and composition/derived_fusions.sqlc on the demand.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/owed_remainder' AS subject,
           x.total = x.kept + x.removed AND x.kept <= x.demand_owed + x.demand_derived AS holds,
           format('%s fusions = %s owing a remainder + %s suspended; %s owe a demand sum and %s file it derived',
                  x.total, x.kept, x.removed, x.demand_owed, x.demand_derived) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f)        AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_remainder ) o) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_remainders ) s
                              WHERE s.composition = f.filing AND s.composed_layer = f.layer)) AS removed,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_equality ) o
               WHERE o.quantity = 'demand')                                          AS demand_owed,
             (SELECT count(*) FROM ( SELECT * FROM composition.derived_fusions ) d
               WHERE d.quantity = 'demand')                                          AS demand_derived
         ) x
) p ON true
WHERE a.slug = 'owed_remainder'
