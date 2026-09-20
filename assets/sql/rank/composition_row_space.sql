-- asrt:Fusion/asrt:Part folded onto its fusion: the fibre's generator, and what it is known to.
SELECT p.composition,
       p.composed_layer,
       count(*)                                                             AS parts,
       1::bigint                                                            AS row_dim,
       count(*) - 1                                                         AS kernel_dim,
       count(*) FILTER (WHERE p.factor_state = 'stated')                    AS factors_stated,
       count(*) FILTER (WHERE p.factor_state = 'omitted')                   AS factors_one,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation'))   AS factors_unknown,
       count(*) FILTER (WHERE p.factor_state IN ('absent', 'derivation')) = 0
                                                                            AS direction_known
FROM (
    SELECT * FROM composition.parts
) p
GROUP BY p.composition, p.composed_layer
