-- composition/fusions.sqlc against the fusions that are a row of F Phi.
SELECT f.filing                                         AS composition,
       count(*)                                         AS declared,
       count(k.composition)                             AS rank,
       count(*) - count(k.composition)                  AS left_null
FROM      (
    SELECT * FROM composition.fusions
) f
LEFT JOIN (
    SELECT * FROM rank.composition_kernel
) k ON k.composition = f.filing AND k.composed_layer = f.layer
GROUP BY f.filing
