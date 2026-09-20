-- asrt:Fusion/asrt:Part against itself; conformance rule "a fusion's parts partition what they compose".
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT f.filing, f.layer,
           j.filing IS NOT NULL AS violates,
           CASE WHEN j.filing IS NULL
                THEN format('`%s` draws each part once', f.layer)
                ELSE format('`%s/%s` arrives through `%s/%s` and through `%s/%s`',
                            j.doubled_filing, j.doubled_layer,
                            j.via_filing, j.via_layer, j.also_via_filing, j.also_via_layer)
           END AS detail
    FROM      (
        SELECT * FROM composition.fusions
    ) f
    LEFT JOIN (
        SELECT * FROM composition.jagged_layers
    ) j ON j.filing = f.filing AND j.layer = f.layer
) p ON true
WHERE r.slug = 'jagged_layer'
