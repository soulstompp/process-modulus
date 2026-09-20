-- asrt:eliminations with pm:absent/reason = notApplicable, counted over asrt:Part.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT m.composition AS filing, m.composed_layer AS layer,
           m.parts > 1 AS violates,
           format('%s parts and the search is `notApplicable`', m.parts) AS detail
    FROM (
        -- eliminations/searched.sqlc answering "notApplicable", beside folds/fusion_parts.sqlc.
SELECT es.composition, es.composed_layer, f.parts
FROM (
    SELECT * FROM eliminations.searched
) es
JOIN (
    SELECT * FROM folds.fusion_parts
) f
  ON f.composition = es.composition AND f.composed_layer = es.composed_layer
WHERE es.answer = 'notApplicable'
  AND f.parts > 0

    ) m
) p ON true
WHERE r.slug = 'elimination_not_applicable_with_parts'
