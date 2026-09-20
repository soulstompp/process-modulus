-- asrt:Part/pm:ForeignId against pm.filing_identity and pm.layer.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT a.composition AS filing, a.composed_layer AS layer,
           r.composition IS NULL AS violates,
           format('%s / %s resolves to nothing', a.part_filing, a.part_layer) AS detail
    FROM      (
        SELECT * FROM composition.part_references
    ) a
    LEFT JOIN (
        SELECT * FROM composition.parts
    ) r
           ON r.composition    = a.composition
          AND r.composed_layer = a.composed_layer
          AND r.part_notation  = a.part_filing
          AND r.part_layer     = a.part_layer
) p ON true
WHERE r.slug = 'unresolved_part'
