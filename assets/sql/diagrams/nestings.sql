-- diagrams/calls.sqlc pinned to local parts, folded to the parent lane that will hold them.
SELECT DISTINCT c.composition, c.composed_layer
FROM (
    SELECT * FROM diagrams.calls
) c
WHERE c.is_local
