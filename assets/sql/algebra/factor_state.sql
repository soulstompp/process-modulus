-- composition/part_references.sqlc, each part's factor_state against the factor columns it carries.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_references' AS subject,
           count(*) FILTER (WHERE x.mislabelled) = 0 AS holds,
           format('%s parts: %s omitted, %s stated, %s absent, %s derivation; %s whose state is not the column they file',
                  count(*),
                  count(*) FILTER (WHERE x.factor_state = 'omitted'),
                  count(*) FILTER (WHERE x.factor_state = 'stated'),
                  count(*) FILTER (WHERE x.factor_state = 'absent'),
                  count(*) FILTER (WHERE x.factor_state = 'derivation'),
                  count(*) FILTER (WHERE x.mislabelled)) AS detail
    FROM (
        SELECT r.factor_state,
               r.factor_state IS NULL
                 OR (r.factor_state = 'stated')     <> (r.factor_low IS NOT NULL)
                 OR (r.factor_state = 'absent')     <> (r.factor_absent IS NOT NULL)
                 OR (r.factor_state = 'derivation') <> (r.factor_derivation IS NOT NULL)
                 OR (r.factor_state = 'omitted')
                      <> (num_nonnulls(r.factor_low, r.factor_absent, r.factor_derivation) = 0)
                   AS mislabelled
        FROM (
            SELECT * FROM composition.part_references
        ) r
    ) x
) p ON true
WHERE a.slug = 'factor_state'
