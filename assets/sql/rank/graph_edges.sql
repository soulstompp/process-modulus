-- composition/parts.sqlc and units/conversions.sqlc, each labelled with the graph it is an edge of.
SELECT 'layers' AS graph,
       p.composition                            AS filing,
       p.composition  || '/' || p.composed_layer AS from_node,
       p.part_filing  || '/' || p.part_layer     AS to_node
FROM (
    SELECT * FROM composition.parts
) p
UNION ALL
SELECT 'units', c.filing, c.from_unit, c.to_unit
FROM (
    SELECT * FROM units.conversions
) c
