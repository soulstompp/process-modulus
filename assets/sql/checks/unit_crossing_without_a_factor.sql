-- asrt:Part against its composed pm:Layer's unit, per quantity they both file.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT DISTINCT x.filing, x.layer, x.violates, x.detail
    FROM (
        SELECT p.composition AS filing, p.composed_layer AS layer,
               p.factor_state = 'omitted' AS violates,
               format('the part %s/%s is quoted in %s and this layer in %s, and the conversion '
                      'is %s', p.part_filing, p.part_layer, p.part_unit, p.composed_unit,
                      CASE p.factor_state
                           WHEN 'stated'     THEN 'filed'
                           WHEN 'absent'     THEN format('filed as `%s`', p.factor_absent)
                           WHEN 'derivation' THEN format('filed as the output of `%s`', p.factor_derivation)
                           WHEN 'omitted'    THEN 'NOT FILED, so a reader supplies one' END) AS detail
        FROM (
            SELECT * FROM composition.part_quantities
        ) p
        WHERE p.part_unit IS DISTINCT FROM p.composed_unit
    ) x
) p ON true
WHERE r.slug = 'unit_crossing_without_a_factor'
