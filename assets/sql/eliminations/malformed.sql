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
