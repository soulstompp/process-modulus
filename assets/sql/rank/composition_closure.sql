-- composition/descent.sqlc reduced to one row per reached layer, against rank/composition_kernel.sqlc.
WITH composition_part_references AS (
-- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
composition_parts AS (
-- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition_part_references
) p
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer
),
rank_composition_kernel AS (
-- asrt:Fusion/asrt:Part folded onto its fusion: the fibre size, and the block dimension it fixes.
SELECT p.composition,
       p.composed_layer,
       count(*)     AS parts,
       count(*) - 1 AS kernel_dim
FROM (
    SELECT * FROM composition_parts
) p
GROUP BY p.composition, p.composed_layer
),
composition_descent AS (
-- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition_parts
),
walk(root_filing, root_layer, filing, layer, depth, path,
     factor_low, factor_mode, factor_high, factor_absent) AS (
        SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, 1,
               ARRAY[p.composition  || '/' || p.composed_layer,
                     p.part_filing  || '/' || p.part_layer],
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation')
        FROM resolved p
    UNION ALL
        SELECT w.root_filing, w.root_layer, p.part_filing, p.part_layer, w.depth + 1,
               w.path || (p.part_filing || '/' || p.part_layer),
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation')
        FROM walk w
        JOIN resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
) CYCLE filing, layer SET is_cycle USING route
SELECT root_filing, root_layer, filing, layer, depth, path,
       factor_low, factor_mode, factor_high, factor_absent, is_cycle
FROM walk
)
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
    SELECT * FROM rank_composition_kernel
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
            SELECT * FROM composition_descent
        ) d
        GROUP BY d.root_filing, d.root_layer, d.filing, d.layer
    ) w
    LEFT JOIN (
        SELECT * FROM rank_composition_kernel
    ) k ON k.composition = w.filing AND k.composed_layer = w.layer
    GROUP BY w.root_filing, w.root_layer
) b ON b.root_filing = r.composition AND b.root_layer = r.composed_layer
