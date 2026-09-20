-- pm.part where pm:ForeignId/notation equals the composition's own pm:notation.
SELECT p.*
FROM      (
    SELECT * FROM composition.part_references
) p
JOIN      (
    SELECT * FROM composition.notations
) fi ON fi.filing = p.composition AND fi.notation = p.part_filing
