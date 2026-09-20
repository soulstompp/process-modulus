-- composition/part_regimes.sqlc partitioned by whether both sides state a framework.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_regimes' AS subject,
           x.total = x.askable + x.unaskable AS holds,
           format('%s parts with a regime handle = %s askable + %s where a typed absence or an unstated filing makes the question not arise',
                  x.total, x.askable, x.unaskable) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r
               WHERE r.composer_absent IS NULL AND r.frameworks_the_filing_states > 0) AS askable,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r
               WHERE r.composer_absent IS NOT NULL OR r.frameworks_the_filing_states = 0) AS unaskable
         ) x
) p ON true
WHERE a.slug = 'part_regimes'
