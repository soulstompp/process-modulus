-- composition/regime_crossings.sqlc; conformance rule "a part crossing a regime boundary files what reconciles it".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT x.composition AS filing, x.composed_layer AS layer,
           (x.crosses AND x.instrument IS NULL) AS violates,
           CASE WHEN NOT x.crosses
                THEN format('`%s` composes `%s/%s` inside %s', x.composed_layer,
                            x.part_filing, x.part_layer, x.composed_framework)
                WHEN x.instrument IS NOT NULL
                THEN format('`%s` crosses %s to %s, reconciled by %s %s', x.composed_layer,
                            x.part_framework, x.composed_framework, x.instrument, x.clause)
                ELSE format('`%s` crosses %s to %s and cites no instrument', x.composed_layer,
                            x.part_framework, x.composed_framework)
           END AS detail
    FROM (
        -- composition/part_regimes.sqlc: the composer's framework for each part against the framework
-- the composition itself reports under.
SELECT x.composition, x.composed_layer, x.part_filing, x.part_layer,
       own.framework_taxonomy AS composed_taxonomy,
       own.framework_value    AS composed_framework,
       x.composer_taxonomy    AS part_taxonomy,
       x.composer_value       AS part_framework,
       (own.states = 1 AND x.composer_value IS NOT NULL)                  AS crossing_known,
       (own.states = 1 AND x.composer_value IS NOT NULL
        AND (own.framework_taxonomy, own.framework_value)
            IS DISTINCT FROM (x.composer_taxonomy, x.composer_value))     AS crosses,
       c.instrument, c.clause
FROM      (
    SELECT * FROM composition.part_regimes
) x
LEFT JOIN (
    SELECT r.filing,
           count(*) FILTER (WHERE r.framework_value IS NOT NULL) AS states,
           min(r.framework_taxonomy) AS framework_taxonomy,
           min(r.framework_value)    AS framework_value
    FROM (
        SELECT * FROM composition.regimes
    ) r
    GROUP BY r.filing
) own ON own.filing = x.composition
LEFT JOIN (
    SELECT * FROM composition.citations
) c ON c.composition = x.composition

    ) x
    WHERE x.crossing_known
) p ON true
WHERE r.slug = 'regime_crossing_without_a_citation'
