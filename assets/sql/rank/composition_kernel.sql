-- asrt:Fusion/asrt:Part folded onto its fusion: the fibre size, and the block dimension it fixes.
SELECT p.composition,
       p.composed_layer,
       count(*)     AS parts,
       count(*) - 1 AS kernel_dim
FROM (
    SELECT * FROM composition.parts
) p
GROUP BY p.composition, p.composed_layer
