-- composition/descent.sqlc unioned with the identity on composition/parts.sqlc: F* = F+ ∪ I.
SELECT DISTINCT root_filing, root_layer, filing, layer
FROM (
    SELECT * FROM composition.descent
) w
  UNION
SELECT DISTINCT part_filing, part_layer, part_filing, part_layer
FROM (
    SELECT * FROM composition.parts
) p
