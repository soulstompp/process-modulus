-- rank/composition_row_space.sqlc against rank/composition_kernel.sqlc, then against rank/composition_image.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/composition_row_space' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE x.kernel_dim > 0) > 0
           AND count(*) FILTER (WHERE x.row_dim <> 1) = 0
           AND count(*) FILTER (WHERE x.row_dim + x.kernel_dim <> x.parts) = 0
           AND count(*) FILTER (WHERE x.kernel_dim IS DISTINCT FROM x.kernel_by_fold) = 0
           AND count(*) FILTER (WHERE x.parts IS DISTINCT FROM x.parts_by_fold) = 0     AS holds,
           format('%s fusion(s), %s with a null space; %s report a row space other than one '
                  'dimension, %s do not sum to their own part count, %s disagree with the fold%s',
                  count(*), count(*) FILTER (WHERE x.kernel_dim > 0),
                  count(*) FILTER (WHERE x.row_dim <> 1),
                  count(*) FILTER (WHERE x.row_dim + x.kernel_dim <> x.parts),
                  count(*) FILTER (WHERE x.kernel_dim IS DISTINCT FROM x.kernel_by_fold
                                         OR x.parts IS DISTINCT FROM x.parts_by_fold),
                  coalesce(': ' || string_agg(x.composition || '/' || x.composed_layer, ', '
                                              ORDER BY x.composition, x.composed_layer)
                                   FILTER (WHERE x.row_dim <> 1
                                                 OR x.row_dim + x.kernel_dim <> x.parts
                                                 OR x.kernel_dim IS DISTINCT FROM x.kernel_by_fold
                                                 OR x.parts IS DISTINCT FROM x.parts_by_fold), ''))
                                                                                     AS detail
    FROM (
        SELECT r.composition, r.composed_layer, r.parts, r.row_dim, r.kernel_dim,
               k.parts      AS parts_by_fold,
               k.kernel_dim AS kernel_by_fold
        FROM      (
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

        ) r
        LEFT JOIN (
            SELECT * FROM rank.composition_kernel
        ) k ON k.composition = r.composition AND k.composed_layer = r.composed_layer
    ) x
    UNION ALL
    SELECT 'rank/composition_row_space / the rank',
           y.blocks > 0 AND z.matrix_rows > 0 AND y.blocks = z.matrix_rows
           AND y.parts = y.blocks + y.kernel                                         AS holds,
           format('rank %s summed over the part-side blocks and %s counted as fusion rows; '
                  '%s part(s) over %s block(s) leaves %s dimension(s) of null space',
                  y.blocks, z.matrix_rows, y.parts, y.blocks, y.kernel)
    FROM       (
        SELECT coalesce(sum(s.row_dim),    0) AS blocks,
               coalesce(sum(s.parts),      0) AS parts,
               coalesce(sum(s.kernel_dim), 0) AS kernel
        FROM (
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

        ) s
    ) y
    CROSS JOIN (
        SELECT coalesce(sum(i.rank), 0) AS matrix_rows
        FROM (
            SELECT * FROM rank.composition_image
        ) i
    ) z
) p ON true
WHERE a.slug = 'composition_row_space'
