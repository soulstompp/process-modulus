-- asrt:Part followed to a layer that names no parts of its own.
SELECT d.*
FROM      (
    SELECT * FROM composition.descent
) d
LEFT JOIN (
    SELECT * FROM composition.fusions
) f
       ON f.filing = d.filing AND f.layer = d.layer
WHERE f.filing IS NULL
