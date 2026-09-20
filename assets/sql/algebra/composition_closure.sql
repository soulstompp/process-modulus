-- rank/composition_closure.sqlc: the composite's dimension against the sum of its levels'.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/composition_closure' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE c.deepest >= 2) > 0
           AND count(*) FILTER (WHERE c.closure_kernel <> c.sum_kernel) = 0
           AND count(*) FILTER (WHERE c.row_dim <> 1) = 0
           AND count(*) FILTER (WHERE c.leaves_positive + c.leaves_unknown <> c.leaves) = 0
                                                                                     AS holds,
           format('%s root(s), %s reaching two levels or more; %s disagree between the '
                  'composite dimension and the sum of its blocks, %s have a leaf whose path '
                  'product is neither positive nor unstated, %s leaf arrival(s) unstated%s',
                  count(*), count(*) FILTER (WHERE c.deepest >= 2),
                  count(*) FILTER (WHERE c.closure_kernel <> c.sum_kernel),
                  count(*) FILTER (WHERE c.leaves_positive + c.leaves_unknown <> c.leaves),
                  coalesce(sum(c.leaves_unknown), 0),
                  coalesce(': ' || string_agg(format('%s/%s wants %s and sums to %s',
                                                     c.composition, c.composed_layer,
                                                     c.closure_kernel, c.sum_kernel),
                                              ', ' ORDER BY c.composition, c.composed_layer)
                                   FILTER (WHERE c.closure_kernel <> c.sum_kernel), ''))
                                                                                     AS detail
    FROM (
        -- composition/descent.sqlc reduced to one row per reached layer, against rank/composition_kernel.sqlc.
SELECT r.composition,
       r.composed_layer,
       coalesce(b.deepest, 0)                             AS deepest,
       1 + coalesce(b.fusions, 0)                         AS fusions_below,
       coalesce(b.leaves, 0)                              AS leaves,
       1::bigint                                          AS row_dim,
       coalesce(b.leaves, 0) - 1                          AS closure_kernel,
       r.kernel_dim + coalesce(b.kernel, 0)               AS sum_kernel,
       coalesce(b.leaves_positive, 0)                     AS leaves_positive,
       coalesce(b.leaves_unknown, 0)                      AS leaves_unknown
FROM      (
    SELECT * FROM rank.composition_kernel
) r
LEFT JOIN (
    SELECT w.root_filing,
           w.root_layer,
           max(w.depth)::bigint                                  AS deepest,
           count(*) FILTER (WHERE k.composition IS NOT NULL)      AS fusions,
           count(*) FILTER (WHERE k.composition IS NULL)          AS leaves,
           count(*) FILTER (WHERE k.composition IS NULL
                                  AND NOT w.factor_absent
                                  AND w.factor_mode > 0)          AS leaves_positive,
           count(*) FILTER (WHERE k.composition IS NULL
                                  AND w.factor_absent)            AS leaves_unknown,
           coalesce(sum(k.kernel_dim), 0)::bigint                 AS kernel
    FROM      (
        SELECT d.root_filing, d.root_layer, d.filing, d.layer,
               max(d.depth)             AS depth,
               bool_or(d.factor_absent) AS factor_absent,
               min(d.factor_mode)       AS factor_mode
        FROM (
            SELECT * FROM composition.descent
        ) d
        GROUP BY d.root_filing, d.root_layer, d.filing, d.layer
    ) w
    LEFT JOIN (
        SELECT * FROM rank.composition_kernel
    ) k ON k.composition = w.filing AND k.composed_layer = w.layer
    GROUP BY w.root_filing, w.root_layer
) b ON b.root_filing = r.composition AND b.root_layer = r.composed_layer

    ) c
) p ON true
WHERE a.slug = 'composition_closure'
