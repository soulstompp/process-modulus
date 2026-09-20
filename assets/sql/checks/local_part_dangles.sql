-- asrt:Part whose pm:ForeignId/notation is its own composition's, against pm.layer.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT p.composition AS filing, p.composed_layer AS layer,
           l.layer IS NULL AS violates,
           format('local part `%s` is not a layer of this filing', p.part_layer) AS detail
    FROM      (
        -- pm.part where pm:ForeignId/notation equals the composition's own pm:notation.
SELECT p.*
FROM      (
    SELECT * FROM composition.part_references
) p
JOIN      (
    SELECT * FROM composition.notations
) fi ON fi.filing = p.composition AND fi.notation = p.part_filing

    ) p
    LEFT JOIN (
        SELECT * FROM layers.every_layer
    ) l ON l.filing = p.composition AND l.layer = p.part_layer
) p ON true
WHERE r.slug = 'local_part_dangles'
