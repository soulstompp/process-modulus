-- pm:Eliminations with pm:Absent reason="notApplicable", counted over pm:Part.
SELECT es.composition, es.composed_layer, count(*) AS parts
FROM pm.elimination_search es
JOIN (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
  ON p.composition = es.composition AND p.composed_layer = es.composed_layer
WHERE es.absent = 'notApplicable'
GROUP BY es.composition, es.composed_layer
