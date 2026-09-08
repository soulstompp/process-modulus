-- eliminations/searched.sqlc answering "notApplicable", counted over asrt:part.
SELECT es.composition, es.composed_layer, count(*) AS parts
FROM (
    -- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) es
JOIN (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
  ON p.composition = es.composition AND p.composed_layer = es.composed_layer
WHERE es.answer = 'notApplicable'
GROUP BY es.composition, es.composed_layer
