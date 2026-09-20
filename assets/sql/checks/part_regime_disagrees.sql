-- composition/part_regimes.sqlc; conformance rule "a composer's regime for a part is one that part's own filing declares".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT x.composition AS filing, x.composed_layer AS layer,
           NOT x.agrees AS violates,
           CASE WHEN x.agrees
                THEN format('`%s` is under `%s` and `%s` declares it', x.part_layer,
                            x.composer_value, x.part_filing)
                ELSE format('the composer puts `%s/%s` under `%s` (%s), and that filing declares %s framework(s), none of them this one',
                            x.part_filing, x.part_layer, x.composer_value,
                            x.composer_taxonomy, x.frameworks_the_filing_states)
           END AS detail
    FROM (
        SELECT * FROM composition.part_regimes
    ) x
    WHERE x.composer_absent IS NULL
      AND x.frameworks_the_filing_states > 0
) p ON true
WHERE r.slug = 'part_regime_disagrees'
