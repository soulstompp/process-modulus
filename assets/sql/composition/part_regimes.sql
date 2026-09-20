-- composition/parts.sqlc's regime handle resolved into composition/composer_regimes.sqlc, against
-- the part filing's own composition/regimes.sqlc.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_value IS NOT NULL AND EXISTS (
            SELECT 1
            FROM (
                SELECT * FROM composition.regimes
            ) r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*)
        FROM (
            SELECT * FROM composition.regimes
        ) r
        WHERE r.filing = p.part_filing AND r.framework_value IS NOT NULL) AS frameworks_the_filing_states
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM composition.composer_regimes
) cr ON cr.composition = p.composition AND cr.id = p.part_regime
