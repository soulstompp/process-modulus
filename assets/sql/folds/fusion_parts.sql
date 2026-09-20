-- composition/part_references.sqlc folded to one row per fusion it names.
SELECT r.composition, r.composed_layer, count(*) AS parts
FROM (
    SELECT * FROM composition.part_references
) r
GROUP BY r.composition, r.composed_layer
