-- algebra/roster.sqlc joined to each law's own subjects.
-- algebra/roster.sqlc against public.compose_edge: who composes the layer dimension.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/every_layer.sqlc' AS subject,
           count(*) = 0              AS holds,
           format('%s undeclared parent(s) compose the layer dimension: %s',
                  count(*), coalesce(string_agg(u.parent, ', ' ORDER BY u.parent), '(none)'))
                                     AS detail
    FROM (
        SELECT e.parent
        FROM ( SELECT * FROM rank.compose_edges ) e
        WHERE e.child = 'layers/every_layer.sqlc'
          AND e.inner_joins > 0
          AND e.parent NOT IN ('entries/spillovers.sqlc')
    ) u
) p ON true
WHERE a.slug = 'dimension_use'
UNION ALL
-- algebra/roster.sqlc against rank/compose_measures.sqlc: the directory cut is a partition.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/compose_decomposition' AS subject,
           x.whole_nodes = x.cut_nodes
             AND x.whole_edges = x.cut_edges + x.crossing                            AS holds,
           format('%s templates whole = %s summed over %s directories; %s edges = %s kept + %s crossing',
                  x.whole_nodes, x.cut_nodes, x.directories,
                  x.whole_edges, x.cut_edges, x.crossing)                            AS detail
    FROM ( SELECT
             (SELECT m.n_nodes FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_nodes,
             (SELECT coalesce(sum(m.n_nodes), 0) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_nodes,
             (SELECT m.m_edges FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NULL)                                                AS whole_edges,
             (SELECT coalesce(sum(m.m_edges), 0) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS cut_edges,
             (SELECT count(*) FROM ( SELECT * FROM rank.compose_edges ) e
               WHERE (CASE WHEN position('/' IN e.parent) > 0
                           THEN split_part(e.parent, '/', 1) ELSE '(root)' END)
                  <> (CASE WHEN position('/' IN e.child) > 0
                           THEN split_part(e.child, '/', 1) ELSE '(root)' END))       AS crossing,
             (SELECT count(*) FROM ( SELECT * FROM rank.compose_measures ) m
               WHERE m.scope IS NOT NULL)                                            AS directories
         ) x
) p ON true
WHERE a.slug = 'compose_decomposition'
UNION ALL
-- rank/decomposition.sqlc's two scopes, counted: the whole against the sum of the parts.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/decomposition' AS subject,
           x.whole = x.per_filing AS holds,
           format('%s edges corpus-wide = %s summed over %s filings, across %s graphs',
                  x.whole, x.per_filing, x.filings, x.graphs) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.from_node, g.to_node
                 FROM ( SELECT * FROM rank.graph_edges ) g) e)                      AS whole,
             (SELECT count(*) FROM (
                 SELECT DISTINCT g.graph, g.filing, g.from_node, g.to_node
                 FROM ( SELECT * FROM rank.graph_edges ) g) e)                      AS per_filing,
             (SELECT count(DISTINCT g.filing)
              FROM ( SELECT * FROM rank.graph_edges ) g)                            AS filings,
             (SELECT count(DISTINCT g.graph)
              FROM ( SELECT * FROM rank.graph_edges ) g)                            AS graphs
         ) x
) p ON true
WHERE a.slug = 'decomposition'
UNION ALL
-- rank/graph_measures.sqlc's layer row at the corpus scope against checks/jagged_layer.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/cycle_space' AS subject,
           x.nodes > 0 AND x.edges > 0 AND x.examined > 0
           AND (x.dim = 0) = (x.violations = 0)                                      AS holds,
           format('dim %s over %s node(s), %s edge(s), %s component(s); %s of %s fusion(s) '
                  'examined violate the partition',
                  x.dim, x.nodes, x.edges, x.components, x.violations, x.examined)   AS detail
    FROM (
        SELECT m.cycle_space_dim AS dim, m.n_nodes AS nodes, m.m_edges AS edges,
               m.c_components AS components, j.violations, j.examined
        FROM      (
            SELECT * FROM rank.graph_measures
        ) m
        CROSS JOIN (
            SELECT count(*) FILTER (WHERE k.violates)             AS violations,
                   count(*) FILTER (WHERE k.violates IS NOT NULL) AS examined
            FROM ( SELECT * FROM checks.jagged_layer ) k
        ) j
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'cycle_space'
UNION ALL
-- rank/composition_kernel.sqlc folded, against rank/graph_measures.sqlc's layer row.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/composition_kernel' AS subject,
           x.parts > 0 AND x.fusions > 0 AND x.edges > 0
           AND x.parts = x.edges
           AND x.kernel = x.edges - x.fusions                                        AS holds,
           format('dim ker %s over %s part(s) in %s fusion(s); the layer graph has %s edge(s), '
                  '%s node(s), %s component(s) and cycle space %s',
                  x.kernel, x.parts, x.fusions, x.edges,
                  x.nodes, x.components, x.dim)                                      AS detail
    FROM (
        SELECT k.parts, k.fusions, k.kernel,
               m.m_edges AS edges, m.n_nodes AS nodes,
               m.c_components AS components, m.cycle_space_dim AS dim
        FROM      (
            SELECT coalesce(sum(c.parts), 0)      AS parts,
                   count(*)                       AS fusions,
                   coalesce(sum(c.kernel_dim), 0) AS kernel
            FROM ( SELECT * FROM rank.composition_kernel ) c
        ) k
        CROSS JOIN (
            SELECT * FROM rank.graph_measures
        ) m
        WHERE m.graph = 'layers' AND m.filing IS NULL
    ) x
) p ON true
WHERE a.slug = 'composition_kernel'
UNION ALL
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
UNION ALL
-- rank/composition_image.sqlc, then the compositions carrying a dimension against checks/unresolved_part.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'rank/composition_image' AS subject,
           count(*) > 0 AND sum(i.declared) > 0
           AND count(*) FILTER (WHERE i.declared <> i.rank + i.left_null) = 0
           AND sum(i.left_null) = 0                                                  AS holds,
           format('%s composition(s), %s declared fusion(s), rank %s, left null %s%s',
                  count(*), sum(i.declared), sum(i.rank), sum(i.left_null),
                  coalesce(': ' || string_agg(i.composition, ', ' ORDER BY i.composition)
                                   FILTER (WHERE i.left_null > 0), ''))              AS detail
    FROM (
        SELECT * FROM rank.composition_image
    ) i
    UNION ALL
    SELECT 'rank/composition_image / the rule',
           count(*) FILTER (WHERE x.examined > 0) > 0
           AND count(*) FILTER (WHERE x.left_null > 0 AND x.accused = 0) = 0         AS holds,
           format('%s composition(s) carry a dimension, %s of those have no part accused; '
                  '%s part reference(s) examined, %s accused%s',
                  count(*) FILTER (WHERE x.left_null > 0),
                  count(*) FILTER (WHERE x.left_null > 0 AND x.accused = 0),
                  sum(x.examined), sum(x.accused),
                  coalesce(': ' || string_agg(x.composition, ', ' ORDER BY x.composition)
                                   FILTER (WHERE x.left_null > 0 AND x.accused = 0), ''))
    FROM (
        SELECT i.composition, i.left_null,
               count(u.filing) FILTER (WHERE u.violates)             AS accused,
               count(u.filing) FILTER (WHERE u.violates IS NOT NULL) AS examined
        FROM      (
            SELECT * FROM rank.composition_image
        ) i
        LEFT JOIN (
            SELECT * FROM checks.unresolved_part
        ) u ON u.filing = i.composition
        GROUP BY i.composition, i.left_null
    ) x
) p ON true
WHERE a.slug = 'composition_image'
UNION ALL
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
UNION ALL
-- layers/quantities.sqlc folded to one row per layer: how many units its quantities name.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/quantities' AS subject,
           count(*) > 0
           AND count(*) FILTER (WHERE x.units > 0) > 0
           AND count(*) FILTER (WHERE x.units > 1) = 0                               AS holds,
           format('%s layer(s) file a quantity, %s state a unit, %s state more than one%s',
                  count(*), count(*) FILTER (WHERE x.units > 0),
                  count(*) FILTER (WHERE x.units > 1),
                  coalesce(': ' || string_agg(x.filing || '/' || x.layer, ', '
                                              ORDER BY x.filing, x.layer)
                                   FILTER (WHERE x.units > 1), ''))                  AS detail
    FROM (
        SELECT q.filing, q.layer, count(DISTINCT q.unit) AS units
        FROM      (
            SELECT * FROM layers.quantities
        ) q
        GROUP BY q.filing, q.layer
    ) x
    UNION ALL
    SELECT 'composition/part_quantities',
           count(*) > 0
           AND count(*) FILTER (WHERE y.stated) > 0
           AND count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin) = 0            AS holds,
           format('%s part(s), %s with a stated factor, %s of those file no nameplate%s',
                  count(*), count(*) FILTER (WHERE y.stated),
                  count(*) FILTER (WHERE y.stated AND NOT y.at_the_pin),
                  coalesce(': ' || string_agg(y.composition || '/' || y.part_layer, ', '
                                              ORDER BY y.composition, y.part_layer)
                                   FILTER (WHERE y.stated AND NOT y.at_the_pin), ''))
    FROM (
        SELECT r.composition, r.composed_layer, r.part_filing, r.part_layer,
               bool_or(r.factor_state = 'stated')  AS stated,
               bool_or(r.quantity = 'nameplate')   AS at_the_pin
        FROM      (
            SELECT * FROM composition.part_quantities
        ) r
        GROUP BY r.composition, r.composed_layer, r.part_filing, r.part_layer
    ) y
) p ON true
WHERE a.slug = 'layer_units'
UNION ALL
-- composition/fusions.sqlc for every quantity, partitioned by composition/suspended_quantities.sqlc and composition/derived_fusions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/owed_equality' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s fusion quantities = %s owing + %s suspended or derived', x.total, x.kept,
                  x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_equality ) o)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE EXISTS (SELECT 1
                             FROM ( SELECT s.composition AS filing, s.composed_layer AS layer,
                                           s.quantity
                                    FROM ( SELECT * FROM composition.suspended_quantities ) s
                                    UNION ALL
                                    SELECT d.filing, d.layer, d.quantity
                                    FROM ( SELECT * FROM composition.derived_fusions ) d ) b
                             WHERE b.filing = f.filing AND b.layer = f.layer
                               AND b.quantity = q.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'owed_equality'
UNION ALL
-- composition/descent.sqlc partitioned by composition/fusions.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/leaves' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s descent rows = %s leaves + %s that name parts (over %s distinct keys)',
                  x.total, x.kept, x.removed, x.keys) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.descent ) d)  AS total,
             (SELECT count(DISTINCT (d.filing, d.layer)) FROM ( SELECT * FROM composition.descent ) d) AS keys,
             (SELECT count(*) FROM ( -- asrt:Part followed to a layer that names no parts of its own.
SELECT d.*
FROM      (
    SELECT * FROM composition.descent
) d
LEFT JOIN (
    SELECT * FROM composition.fusions
) f
       ON f.filing = d.filing AND f.layer = d.layer
WHERE f.filing IS NULL
 ) l)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.descent ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fusions ) f
                              WHERE f.filing = d.filing AND f.layer = d.layer)) AS removed
         ) x
) p ON true
WHERE a.slug = 'leaves'
UNION ALL
-- composition/jagged_layers.sqlc partitioned by eliminations/filed.sqlc, multiplicity preserved.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/jagged_layers' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s jagged rows = %s nobody admitted + %s on a fusion that filed one', 
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                                  WHERE e.composition = j.filing
                                    AND e.composed_layer = j.layer))            AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.jagged_layers ) j
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                              WHERE e.composition = j.filing
                                AND e.composed_layer = j.layer))                AS removed
         ) x
) p ON true
WHERE a.slug = 'jagged_layers'
UNION ALL
-- layers/summed_quantities.sqlc partitioned by the query the roster names as this law's subject.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'queries/matrices/3b-composed-quantities' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s stated figures = %s carried + %s suspended', x.total, x.kept, x.removed)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) d
               WHERE d.low IS NOT NULL)                                              AS total,
             (SELECT count(*) FROM ( -- §3  What each layer actually filed, per quantity, and the elimination to subtract from it.
-- layers/summed_quantities.sqlc minus composition/suspended_quantities.sqlc, with eliminations/filed.sqlc.
SELECT d.filing                     AS "filing!",
       d.layer                      AS "layer!",
       d.quantity::text             AS "quantity!",
       d.low::float8                AS "x_low!",
       d.mode::float8               AS "x_mode!",
       d.high::float8               AS "x_high!",
       coalesce(e.low, 0)::float8   AS "e_low!",
       coalesce(e.mode, 0)::float8  AS "e_mode!",
       coalesce(e.high, 0)::float8  AS "e_high!"
FROM      (
    SELECT * FROM layers.summed_quantities
) d
LEFT JOIN (
    SELECT * FROM composition.suspended_quantities
) s
       ON s.composition = d.filing AND s.composed_layer = d.layer
      AND s.quantity = d.quantity
LEFT JOIN (
    SELECT * FROM eliminations.filed
) e
       ON e.composition = d.filing AND e.composed_layer = d.layer
      AND e.quantity = d.quantity
WHERE s.composition IS NULL
  AND d.low IS NOT NULL
 ) k)
                                                                                     AS kept,
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) d
               WHERE d.low IS NOT NULL
                 AND EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_quantities ) s
                              WHERE s.composition = d.filing AND s.composed_layer = d.layer
                                AND s.quantity = d.quantity)) AS removed
         ) x
) p ON true
WHERE a.slug = 'composed_quantities'
UNION ALL
-- every fold in folds/ whose population does not reach algebra/all.sqlc, against its roster and its population by EXCEPT.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.roster = x.missing + x.produced
             AND x.declared = x.roster
             AND x.unproduced = x.missing
             AND x.undeclared = x.stray AS holds,
           format('%s declared = %s unproduced + %s produced, %s undeclared; by EXCEPT, %s on the roster, %s unproduced, %s undeclared',
                  x.declared, x.unproduced, x.produced, x.undeclared, x.roster, x.missing, x.stray) AS detail
    FROM (
        SELECT 'rules' AS contract,
               (SELECT count(DISTINCT r.rule) FROM ( SELECT * FROM checks.roster ) r) AS roster,
               (SELECT count(*) FROM ( SELECT r.rule FROM ( SELECT * FROM checks.roster ) r
                                       EXCEPT
                                       SELECT c.rule FROM ( SELECT * FROM checks.all ) c ) x) AS missing,
               (SELECT count(*) FROM ( SELECT c.rule FROM ( SELECT * FROM checks.all ) c
                                       EXCEPT
                                       SELECT r.rule FROM ( SELECT * FROM checks.roster ) r ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic',
               (SELECT count(DISTINCT a.site) FROM ( SELECT * FROM arithmetic.roster ) a) AS roster,
               (SELECT count(*) FROM ( SELECT a.site FROM ( SELECT * FROM arithmetic.roster ) a
                                       EXCEPT
                                       SELECT z.site FROM ( SELECT * FROM arithmetic.all ) z ) x) AS missing,
               (SELECT count(*) FROM ( SELECT z.site FROM ( SELECT * FROM arithmetic.all ) z
                                       EXCEPT
                                       SELECT a.site FROM ( SELECT * FROM arithmetic.roster ) a ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams',
               (SELECT count(DISTINCT d.object) FROM ( SELECT * FROM diagrams.domain_objects ) d) AS roster,
               (SELECT count(*) FROM ( SELECT d.object FROM ( SELECT * FROM diagrams.domain_objects ) d
                                       EXCEPT
                                       SELECT k.object FROM ( SELECT * FROM diagrams.catalogue ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.object FROM ( SELECT * FROM diagrams.catalogue ) k
                                       EXCEPT
                                       SELECT d.object FROM ( SELECT * FROM diagrams.domain_objects ) d ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws',
               (SELECT count(DISTINCT l.slug) FROM ( SELECT * FROM diagrams.roster ) l) AS roster,
               (SELECT count(*) FROM ( SELECT l.slug FROM ( SELECT * FROM diagrams.roster ) l
                                       EXCEPT
                                       SELECT e.slug FROM ( SELECT * FROM diagrams.expected ) e ) x) AS missing,
               (SELECT count(*) FROM ( SELECT e.slug FROM ( SELECT * FROM diagrams.expected ) e
                                       EXCEPT
                                       SELECT l.slug FROM ( SELECT * FROM diagrams.roster ) l ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences',
               (SELECT count(DISTINCT q.table_name || '.' || q.column_name) FROM ( SELECT * FROM epistemics.absence_questions ) q) AS roster,
               (SELECT count(*) FROM ( SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM epistemics.absence_questions ) q
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.absence_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.absence_columns ) k
                                       EXCEPT
                                       SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM epistemics.absence_questions ) q ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations',
               (SELECT count(DISTINCT i.table_name || '.' || i.column_name) FROM ( SELECT * FROM identities.roster ) i) AS roster,
               (SELECT count(*) FROM ( SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities.roster ) i
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.derivation_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.derivation_columns ) k
                                       EXCEPT
                                       SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities.roster ) i ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'integrity'
UNION ALL
-- composition/carriable.sqlc partitioned by eliminations/filed.sqlc and composition/suspended_quantities.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/carried' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s carriable = %s carried + %s eliminated or suspended',
                  x.total, x.kept, x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.carriable ) c) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.carried ) k)   AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.carriable ) c
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM eliminations.filed ) e
                              WHERE e.composition = c.filing AND e.composed_layer = c.layer)
                  OR EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_quantities ) s
                              WHERE s.composition = c.filing AND s.composed_layer = c.layer
                                AND s.quantity::text = c.quantity::text)) AS removed
         ) x
) p ON true
WHERE a.slug = 'carried'
UNION ALL
-- composition/fusions.sqlc partitioned by composition/suspended_remainders.sqlc, bounded by
-- composition/owed_equality.sqlc and composition/derived_fusions.sqlc on the demand.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/owed_remainder' AS subject,
           x.total = x.kept + x.removed AND x.kept <= x.demand_owed + x.demand_derived AS holds,
           format('%s fusions = %s owing a remainder + %s suspended; %s owe a demand sum and %s file it derived',
                  x.total, x.kept, x.removed, x.demand_owed, x.demand_derived) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f)        AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_remainder ) o) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_remainders ) s
                              WHERE s.composition = f.filing AND s.composed_layer = f.layer)) AS removed,
             (SELECT count(*) FROM ( SELECT * FROM composition.owed_equality ) o
               WHERE o.quantity = 'demand')                                          AS demand_owed,
             (SELECT count(*) FROM ( SELECT * FROM composition.derived_fusions ) d
               WHERE d.quantity = 'demand')                                          AS demand_derived
         ) x
) p ON true
WHERE a.slug = 'owed_remainder'
UNION ALL
-- composition/remainder_frontier.sqlc partitioned into composition/settled_remainders.sqlc, composition/passed_nodes.sqlc and the stops layers/differenced_remainder.sqlc has no row for,
-- the figureless stops held to composition/suspended_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH stops AS (
        SELECT w.root_filing, w.root_layer
        FROM ( SELECT * FROM composition.remainder_frontier ) w
        WHERE w.usable
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.unsettled ) o
                          WHERE o.filing = w.filing AND o.layer = w.layer)
          AND NOT EXISTS (SELECT 1 FROM ( SELECT * FROM layers.differenced_remainder ) r
                          WHERE r.filing = w.filing AND r.layer = w.layer)
    ),
    x AS (
        SELECT
          (SELECT count(*) FROM ( SELECT * FROM composition.remainder_frontier ) w
            WHERE w.usable)                                                          AS total,
          (SELECT count(*) FROM ( SELECT * FROM composition.settled_remainders ) s) AS kept,
          (SELECT count(*) FROM ( SELECT * FROM composition.passed_nodes ) w
            WHERE w.usable)                                                          AS removed,
          (SELECT count(*) FROM stops)                                               AS figureless,
          (SELECT string_agg(DISTINCT s.root_filing || ' / ' || s.root_layer, ', ')
           FROM stops s
           WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_remainders ) l
                             WHERE l.composition = s.root_filing
                               AND l.composed_layer = s.root_layer))                 AS unlifted
    )
    SELECT 'composition/settled_remainders' AS subject,
           x.total = x.kept + x.removed + x.figureless AND x.unlifted IS NULL AS holds,
           format('%s frontier rows = %s settled + %s walked through + %s stopped with no figure%s',
                  x.total, x.kept, x.removed, x.figureless,
                  CASE WHEN x.unlifted IS NOT NULL
                       THEN format('; owed although a node it reaches has none: %s', x.unlifted) END)
               AS detail
    FROM x
) p ON true
WHERE a.slug = 'settled_remainders'
UNION ALL
-- entries/served_holders.sqlc and entries/unserved_holders.sqlc against pm:Remainder/pm:holder.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.held - x.served - x.unserved) < 1e-9 AS holds,
           format('%s held = %s absorbed + %s unserved', x.held, x.served, x.unserved) AS detail
    FROM (
        SELECT h.filing, h.layer,
               sum(h.share_mode)                                            AS held,
               coalesce((SELECT sum(v.share_mode) FROM (
                   SELECT * FROM entries.served_holders
               ) v WHERE v.filing = h.filing AND v.layer = h.layer), 0)      AS served,
               coalesce((SELECT sum(u.share_mode) FROM (
                   SELECT * FROM entries.unserved_holders
               ) u WHERE u.filing = h.filing AND u.layer = h.layer), 0)      AS unserved
        FROM (
            SELECT * FROM entries.holders
        ) h
        WHERE h.share_mode IS NOT NULL
        GROUP BY h.filing, h.layer
    ) x
) p ON true
WHERE a.slug = 'borne'
UNION ALL
-- arithmetic/all.sqlc, one candidate to exactly one verdict.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT z.site AS subject,
           count(*) FILTER (WHERE z.classes <> 1) = 0 AS holds,
           format('%s candidates, %s in exactly one class', count(*),
                  count(*) FILTER (WHERE z.classes = 1)) AS detail
    FROM ( SELECT site, filing, layer,
                  count(*) FILTER (WHERE w.verdict IS NOT NULL) AS classes
           FROM ( SELECT * FROM arithmetic.all ) w
           GROUP BY site, filing, layer ) z
    GROUP BY z.site
) p ON true
WHERE a.slug = 'arithmetic_class'
UNION ALL
-- layers/remainder.sqlc against layers/remainder_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/remainder_scope' AS subject,
           x.computable = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s computable remainders, %s classified, %s classified twice, %s with no standing',
                  x.computable, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r)       AS computable,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder_scope ) z) AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer FROM ( SELECT * FROM layers.remainder_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder_scope ) z
               WHERE z.standing IS NULL)                                             AS unclassified
         ) x
) p ON true
WHERE a.slug = 'remainder_standing'
UNION ALL
-- layers/remainder.sqlc where exposure > 0, against layers/exposure_scope.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/exposure_scope' AS subject,
           x.exposed = x.classified AND x.doubled = 0 AND x.unclassified = 0 AS holds,
           format('%s exposed layers, %s classified, %s classified twice, %s with no standing',
                  x.exposed, x.classified, x.doubled, x.unclassified) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r
               WHERE r.exposure > 1e-9)                                          AS exposed,
             (SELECT count(*) FROM ( SELECT * FROM layers.exposure_scope ) z)   AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer
                                     FROM ( SELECT * FROM layers.exposure_scope ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled,
             (SELECT count(*) FROM ( SELECT * FROM layers.exposure_scope ) z
               WHERE z.standing IS NULL)                                         AS unclassified
         ) x
) p ON true
WHERE a.slug = 'exposure_standing'
UNION ALL
-- epistemics/searches.sqlc against the two relations it unions.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'epistemics/searches' AS subject,
           x.whole = x.couplings + x.eliminations AS holds,
           format('%s searches = %s coupling + %s double-counting',
                  x.whole, x.couplings, x.eliminations) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM epistemics.searches ) s)              AS whole,
             (SELECT count(*) FROM ( SELECT * FROM epistemics.coupling_searches ) c)     AS couplings,
             (SELECT count(*) FROM ( SELECT * FROM eliminations.searched ) e)  AS eliminations
         ) x
) p ON true
WHERE a.slug = 'searches'
UNION ALL
-- composition/part_regimes.sqlc partitioned by whether both sides state a framework.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_regimes' AS subject,
           x.total = x.askable + x.unaskable AS holds,
           format('%s parts with a regime handle = %s askable + %s where a typed absence or an unstated filing makes the question not arise',
                  x.total, x.askable, x.unaskable) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r
               WHERE r.composer_absent IS NULL AND r.frameworks_the_filing_states > 0) AS askable,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_regimes ) r
               WHERE r.composer_absent IS NOT NULL OR r.frameworks_the_filing_states = 0) AS unaskable
         ) x
) p ON true
WHERE a.slug = 'part_regimes'
UNION ALL
-- layers/remainder.sqlc against layers/demand.sqlc and layers/nameplate.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           (r.pivoted OR (r.r_low  = n.n_low  - d.d_high
                      AND r.r_mode = n.n_mode - d.d_mode
                      AND r.r_high = n.n_high - d.d_low))
           AND r.r_low <= r.r_mode AND r.r_mode <= r.r_high
           AND (r.derived_fit = 'clearance')    = (r.r_low >= 0)
           AND (r.derived_fit = 'interference') = (r.r_high <= 0 AND r.r_low < 0)
           AND (r.derived_fit = 'transition')   = (r.r_low < 0 AND r.r_high > 0)
           AND r.m_low  = greatest(r.r_low, -r.r_high, 0)
           AND r.m_mode = abs(r.r_mode)
           AND r.m_high = greatest(r.r_high, -r.r_low) AS holds,
           format('%s [%s, %s, %s] from n [%s, %s, %s] and d [%s, %s, %s]; %s; |r| [%s, %s, %s]',
                  CASE WHEN r.pivoted THEN 'pivoted r' ELSE 'r' END,
                  r.r_low, r.r_mode, r.r_high, n.n_low, n.n_mode, n.n_high,
                  d.d_low, d.d_mode, d.d_high, r.derived_fit, r.m_low, r.m_mode, r.m_high) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM layers.demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
) p ON true
WHERE a.slug = 'crossed_remainder'
UNION ALL
-- layers/remainder.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/fused_remainders.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.filing || ' / ' || r.layer AS subject,
           r.exposure = CASE WHEN r.pivoted THEN greatest(-f.pivoted_low, 0)
                             ELSE greatest(d.d_high - n.n_low, 0) END
           AND (r.exposure = 0) = (r.derived_fit = 'clearance')
           AND r.exposure <= r.m_high AS holds,
           format('exposure %s from %s; %s; |r| at most %s',
                  r.exposure,
                  CASE WHEN r.pivoted THEN format('the pivoted low %s', f.pivoted_low)
                       ELSE format('d_high %s against n_low %s', d.d_high, n.n_low) END,
                  r.derived_fit, r.m_high) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM layers.demand
    ) d ON d.filing = r.filing AND d.layer = r.layer
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = r.filing AND n.layer = r.layer
    LEFT JOIN (
        SELECT * FROM composition.fused_remainders
    ) f ON f.composition = r.filing AND f.composed_layer = r.layer
) p ON true
WHERE a.slug = 'exposure'
UNION ALL
-- layers/decomposed.sqlc against layers/differenced_remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.m_low  * x.q - x.d_high_residue - r.r_low)  < 1e-9
           AND abs(x.m_mode * x.q - x.d_mode_residue - r.r_mode) < 1e-9
           AND abs(x.m_high * x.q - x.d_low_residue  - r.r_high) < 1e-9
           AND x.d_low_residue  >= 0 AND x.d_low_residue  < x.q
           AND x.d_mode_residue >= 0 AND x.d_mode_residue < x.q
           AND x.d_high_residue >= 0 AND x.d_high_residue < x.q AS holds,
           format('m [%s, %s, %s] quanta of %s, residues [%s, %s, %s], against r [%s, %s, %s]',
                  round(x.m_low, 6), round(x.m_mode, 6), round(x.m_high, 6), x.q,
                  x.d_high_residue, x.d_mode_residue, x.d_low_residue,
                  r.r_low, r.r_mode, r.r_high) AS detail
    FROM      (
        SELECT * FROM layers.decomposed
    ) x
    JOIN      (
        SELECT * FROM layers.differenced_remainder
    ) r ON r.filing = x.filing AND r.layer = x.layer
) p ON true
WHERE a.slug = 'remainder_decomposes'
UNION ALL
-- layers/decomposed.sqlc, restricted to demands inside one tooth.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           x.d_low_residue <= x.d_mode_residue AND x.d_mode_residue <= x.d_high_residue AS holds,
           format('demand [%s, %s, %s] inside tooth %s of %s, residues [%s, %s, %s]',
                  x.d_low, x.d_mode, x.d_high, x.d_low_tooth, x.q,
                  x.d_low_residue, x.d_mode_residue, x.d_high_residue) AS detail
    FROM (
        SELECT * FROM layers.decomposed
    ) x
    WHERE NOT x.crosses_tooth
) p ON true
WHERE a.slug = 'sawtooth'
UNION ALL
-- composition/composed_quantum.sqlc against layers/nameplate.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT c.composition || ' / ' || c.composed_layer AS subject,
           abs(n.n_mode - c.composed_quantum * round(n.n_mode / c.composed_quantum)) < 1e-9
           AND (e.mode IS NULL
                OR abs(e.mode - c.composed_quantum * round(e.mode / c.composed_quantum)) < 1e-9)
           AS holds,
           format('quantum %s %s%s against a nameplate of %s%s',
                  c.composed_quantum, c.unit,
                  CASE WHEN c.spread THEN ', read at a factor''s mode' ELSE '' END,
                  n.n_mode,
                  CASE WHEN e.mode IS NULL THEN ''
                       ELSE format(' and an elimination of %s', e.mode) END) AS detail
    FROM      (
        SELECT * FROM composition.composed_quantum
    ) c
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = c.composition AND n.layer = c.composed_layer
    LEFT JOIN (
        SELECT * FROM eliminations.filed
    ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
       AND e.quantity = 'nameplate'
    WHERE c.composed_quantum IS NOT NULL
) p ON true
WHERE a.slug = 'composed_quantum'
UNION ALL
-- composition/fused.sqlc against composition/resolved_quantities.sqlc, composition/parts.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT o.filing || ' / ' || o.layer || ' / ' || o.quantity AS subject,
           f.composition IS NOT NULL
           AND abs(f.sum_low  - r.sum_low)  < 1e-9
           AND abs(f.sum_mode - r.sum_mode) < 1e-9
           AND abs(f.sum_high - r.sum_high) < 1e-9
           AND f.computed_low <= f.computed_mode AND f.computed_mode <= f.computed_high
           AND abs(f.computed_mode - (r.sum_mode - coalesce(e.mode, 0))) < 1e-9
           AND CASE WHEN r.sum_low  - coalesce(e.low,  0) <= r.sum_mode - coalesce(e.mode, 0)
                     AND r.sum_mode - coalesce(e.mode, 0) <= r.sum_high - coalesce(e.high, 0)
                    THEN abs(f.computed_low  - (r.sum_low  - coalesce(e.low,  0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.high, 0))) < 1e-9
                    ELSE abs(f.computed_low  - (r.sum_low  - coalesce(e.high, 0))) < 1e-9
                     AND abs(f.computed_high - (r.sum_high - coalesce(e.low,  0))) < 1e-9 END
           AND f.agrees = (abs(f.computed_low  - d.low)  < 1e-9
                       AND abs(f.computed_mode - d.mode) < 1e-9
                       AND abs(f.computed_high - d.high) < 1e-9) AS holds,
           format('Σ [%s, %s, %s] less [%s, %s, %s] gives [%s, %s, %s] against a filed [%s, %s, %s]',
                  r.sum_low, r.sum_mode, r.sum_high,
                  coalesce(e.low, 0), coalesce(e.mode, 0), coalesce(e.high, 0),
                  f.computed_low, f.computed_mode, f.computed_high,
                  d.low, d.mode, d.high) AS detail
    FROM      (
        SELECT * FROM composition.owed_equality
    ) o
    JOIN      (
        SELECT p.composition, p.composed_layer, s.quantity,
               sum(least(   s.low  * coalesce(p.factor_low, 1),
                            s.low  * coalesce(p.factor_high, 1))) AS sum_low,
               sum(s.mode * coalesce(p.factor_mode, 1))           AS sum_mode,
               sum(greatest(s.high * coalesce(p.factor_low, 1),
                            s.high * coalesce(p.factor_high, 1))) AS sum_high
        FROM      (
            SELECT * FROM composition.parts
        ) p
        JOIN      (
            SELECT * FROM composition.resolved_quantities
        ) s ON s.filing = p.part_filing AND s.layer = p.part_layer
        GROUP BY p.composition, p.composed_layer, s.quantity
    ) r ON r.composition = o.filing AND r.composed_layer = o.layer AND r.quantity = o.quantity
    JOIN      (
        SELECT * FROM layers.summed_quantities
    ) d ON d.filing = o.filing AND d.layer = o.layer AND d.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM eliminations.filed
    ) e ON e.composition = o.filing AND e.composed_layer = o.layer AND e.quantity = o.quantity
    LEFT JOIN (
        SELECT * FROM composition.fused
    ) f ON f.composition = o.filing AND f.composed_layer = o.layer AND f.quantity = o.quantity
) p ON true
WHERE a.slug = 'fusion_sum'
UNION ALL
-- composition/fused_remainders.sqlc against layers/demand.sqlc, layers/nameplate.sqlc and composition/remainder_frontier.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.subject,
           x.pivoted_low <= x.pivoted_mode AND x.pivoted_mode <= x.pivoted_high
           AND x.pivoted_low >= x.cross_low - 1e-9 AND x.pivoted_high <= x.cross_high + 1e-9
           AND (NOT x.sums_agree OR abs(x.pivoted_mode - x.cross_mode) < 1e-9)
           AND (NOT x.sums_agree OR x.spread
                OR (abs(x.pivoted_low - x.cross_low) < 1e-9
                    AND abs(x.pivoted_high - x.cross_high) < 1e-9)) AS holds,
           format('pivot [%s, %s, %s] against n - d [%s, %s, %s]; %s',
                  x.pivoted_low, x.pivoted_mode, x.pivoted_high,
                  x.cross_low, x.cross_mode, x.cross_high,
                  CASE WHEN NOT x.sums_agree THEN 'a composed sum disagrees with its filing'
                       WHEN x.spread THEN 'a factor on the walk has width'
                       ELSE 'no factor on the walk has width' END) AS detail
    FROM (
        SELECT r.composition || ' / ' || r.composed_layer AS subject,
               r.pivoted_low, r.pivoted_mode, r.pivoted_high,
               n.n_low  - d.d_high AS cross_low,
               n.n_mode - d.d_mode AS cross_mode,
               n.n_high - d.d_low  AS cross_high,
               EXISTS (SELECT 1 FROM ( SELECT * FROM composition.remainder_frontier ) w
                        WHERE w.root_filing = r.composition AND w.root_layer = r.composed_layer
                          AND w.factor_low IS DISTINCT FROM w.factor_high) AS spread,
               NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fused ) f
                            WHERE f.composition = r.composition
                              AND f.composed_layer = r.composed_layer
                              AND f.quantity IN ('demand', 'nameplate')
                              AND NOT f.agrees) AS sums_agree
        FROM      (
            SELECT * FROM composition.fused_remainders
        ) r
        JOIN      (
            SELECT * FROM layers.demand
        ) d ON d.filing = r.composition AND d.layer = r.composed_layer
        JOIN      (
            SELECT * FROM layers.nameplate
        ) n ON n.filing = r.composition AND n.layer = r.composed_layer
    ) x
) p ON true
WHERE a.slug = 'composed_remainder'
UNION ALL
-- folds/rule_subjects.sqlc for every rule checks/roster.sqlc declares, one verdict per rule.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT r.slug AS subject,
           f.violated = 0 AS holds,
           format('%s examined, %s violating', f.answered, f.violated) AS detail
    FROM (
        SELECT * FROM checks.roster
    ) r
    JOIN (
        SELECT * FROM folds.rule_subjects
    ) f ON f.subject = r.rule
) p ON true
WHERE a.slug = 'conforms'
UNION ALL
-- checks/fit_axes.sqlc and checks/fit_domain.sqlc against rank/rule_closure.sqlc and reports/fit_coverage.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT s.slug AS subject,
           r.slug IS NOT NULL
           AND coalesce(x.axes, 0) = 1
           AND (x.axis = 'not read') = NOT coalesce(h.reaches, false)
           AND CASE WHEN x.axis = 'not read' THEN coalesce(k.cells, 0) = 0
                    ELSE coalesce(k.cells, 0) = 4 AND k.distinct_cells = 4 END
           AND coalesce(k.disagreeing, 0) = 0                             AS holds,
           format('%s; its closure %s the fit; %s cells, %s disagreeing with what it examined%s',
                  coalesce(x.axis::text, 'no axis declared'),
                  CASE WHEN coalesce(h.reaches, false) THEN 'reaches' ELSE 'does not reach' END,
                  coalesce(k.cells, 0), coalesce(k.disagreeing, 0),
                  coalesce(': ' || k.cells_read, ''))                     AS detail
    FROM (
        SELECT slug FROM ( SELECT * FROM checks.roster ) r0
        UNION
        SELECT slug FROM ( SELECT * FROM checks.fit_axes ) a0
        UNION
        SELECT slug FROM ( SELECT * FROM checks.fit_domain ) d0
    ) s
    LEFT JOIN (
        SELECT * FROM checks.roster
    ) r ON r.slug = s.slug
    LEFT JOIN (
        SELECT f.slug, count(*) AS axes, min(f.axis) AS axis
        FROM ( SELECT * FROM checks.fit_axes ) f
        GROUP BY f.slug
    ) x ON x.slug = s.slug
    LEFT JOIN (
        SELECT c.slug, true AS reaches
        FROM ( -- rank/compose_edges.sqlc walked from each rule on checks/roster.sqlc.
WITH RECURSIVE closure(slug, template) AS (
    SELECT r.slug, 'checks/' || r.slug || '.sqlc'
    FROM (
        SELECT * FROM checks.roster
    ) r
    UNION
    SELECT c.slug, e.child
    FROM closure c
    JOIN (
        SELECT * FROM rank.compose_edges
    ) e ON e.parent = c.template
)
SELECT slug, template FROM closure
 ) c
        WHERE c.template IN ('layers/remainder.sqlc', 'layers/filed_remainders.sqlc')
        GROUP BY c.slug
    ) h ON h.slug = s.slug
    LEFT JOIN (
        SELECT v.slug,
               count(*)                                                        AS cells,
               count(DISTINCT coalesce(v.fit::text, 'no fit'))                 AS distinct_cells,
               count(*) FILTER (WHERE (v.standing = 'exercised') <> (v.examined > 0)) AS disagreeing,
               string_agg(coalesce(v.fit::text, 'no fit') || ' ' || v.standing || ' ' || v.examined,
                          ', ' ORDER BY v.fit NULLS LAST)                      AS cells_read
        FROM ( SELECT * FROM reports.fit_coverage ) v
        GROUP BY v.slug
    ) k ON k.slug = s.slug
) p ON true
WHERE a.slug = 'fit_domain'
UNION ALL
-- epistemics/absences.sqlc against epistemics/filed_absences.sqlc, through epistemics/absence_positions.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH positions AS (
        SELECT * FROM (
            -- The XSD's Stated* wrapper positions in the documents ingest loads, against epistemics/absences.sqlc's questions.
SELECT * FROM (VALUES
  ('pm:processModulus/pm:notation',     'its own notation',                       NULL::text),
  ('pm:processModulus/pm:evidence',     'what it is evidence for',                NULL),
  ('pm:stack/pm:scope',                 'how much of the system',                 NULL),
  ('pm:stack/pm:couplings',             'did anybody look for couplings',         NULL),
  ('pm:regime/pm:framework',            'regime framework',                       NULL),
  ('pm:regime/pm:chart',                'regime chart',                           NULL),
  ('asrt:regime/pm:framework',          'part regime framework',                  NULL),
  ('asrt:regime/pm:chart',              'part regime chart',                      NULL),
  ('asrt:provenance/pm:standing',       'assertion standing',                     NULL),
  ('pm:provenance/pm:standing',         'provenance standing',                    NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on an absence',     NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on a derivation',   NULL),
  ('pm:claim/pm:narrowsWhen',           'narrowsWhen',                            NULL),
  ('pm:claim/pm:boundOrigin',           'boundOrigin',                            NULL),
  ('pm:claim/pm:denominator',           'denominator',                            NULL),
  ('pm:coupling/pm:strength',           'coupling strength',                      NULL),
  ('pm:operation/pm:notationPosition',  'where the operation is in a notation',   NULL),
  ('pm:draw/pm:quantity',               'operation draw',                         NULL),
  ('pm:induces/pm:commitment',          'operation induction',                    NULL),
  ('pm:demand/pm:amount',               'demand',                                 NULL),
  ('pm:demand/pm:patience',             'patience',                               NULL),
  ('pm:layer/pm:timeSlack',             'buffer slack',                           NULL),
  ('pm:nameplate/pm:capacitySlack',     'buffer slack',                           NULL),
  ('pm:nameplate/pm:inventorySlack',    'buffer slack',                           NULL),
  ('pm:layer/pm:remainder',             'remainder',                              NULL),
  ('pm:remainder/pm:sign',              'remainder sign',                         NULL),
  ('pm:remainder/pm:absorber',          'remainder absorber',                     NULL),
  ('pm:remainder/pm:quantity',          'remainder quantity',                     NULL),
  ('pm:holder/pm:share',                'holder share',                           NULL),
  ('pm:nameplate/pm:amount',            'nameplate amount',                       NULL),
  ('pm:nameplate/pm:amountOrigin',      'who committed the amount',               NULL),
  ('pm:nameplate/pm:divisibility',      'divisibility',                           NULL),
  ('pm:divisibility/pm:window',         'duty-cycle window',                      NULL),
  ('pm:lumpy/pm:size',                  'lump size',                              NULL),
  ('pm:quantum/pm:size',                'duty-cycle period',                      NULL),
  ('pm:jagged/pm:draw',                 'draw',                                   NULL),
  ('pm:jagged/pm:measurementBasis',     'measurement basis',                      NULL),
  ('asrt:fusion/asrt:eliminations',     'did anybody look for double counting',   NULL),
  ('asrt:elimination/asrt:quantity',    'eliminated quantity',                    NULL),
  ('asrt:part/asrt:factor',             'part factor',                            NULL),
  ('pm:continuous/pm:premium',          NULL,
   'a premium is a claim nothing reads, so it has no columns of its own: its value is in claim and its absence here alone'),
  ('pm:remainder/pm:holder',            NULL,
   'a holder that is typed absent has no row in holder, whose rows are the holders that bear a share')
) AS p(owns, question, why_no_column)

        ) r
    ),
    by_owns AS (
        SELECT owns, min(question) AS g FROM positions WHERE question IS NOT NULL GROUP BY owns
    ),
    by_question AS (
        SELECT p.question, min(o.g) AS g
        FROM positions p JOIN by_owns o USING (owns)
        WHERE p.question IS NOT NULL
        GROUP BY p.question
    ),
    owns_group AS (
        SELECT p.owns, min(q.g) AS g
        FROM positions p JOIN by_question q USING (question)
        GROUP BY p.owns
    ),
    counted AS (
        SELECT q.g, c.filing, c.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics.absences
        ) c
        JOIN by_question q USING (question)
        GROUP BY q.g, c.filing, c.reason
    ),
    filed AS (
        SELECT o.g, f.filing, f.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics.filed_absences
        ) f
        JOIN owns_group o USING (owns)
        GROUP BY o.g, f.filing, f.reason
    ),
    cells AS (
        SELECT coalesce(c.g, f.g) AS g, coalesce(c.filing, f.filing) AS filing,
               coalesce(c.reason, f.reason) AS reason,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.g = c.g AND f.filing = c.filing AND f.reason = c.reason
    )
    SELECT q.g AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing, x.reason,
                                                     x.filed, x.counted), '; ' ORDER BY x.filing, x.reason)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM (SELECT DISTINCT g FROM by_question) q
    LEFT JOIN cells x ON x.g = q.g
    GROUP BY q.g
    UNION ALL
    SELECT 'positions the roster does not name',
           count(*) FILTER (WHERE p.owns IS NULL) = 0,
           format('%s absences at %s undeclared position(s)%s; %s at positions no column answers',
                  count(*) FILTER (WHERE p.owns IS NULL),
                  count(DISTINCT f.owns) FILTER (WHERE p.owns IS NULL),
                  coalesce(': ' || string_agg(DISTINCT f.owns, ', ') FILTER (WHERE p.owns IS NULL), ''),
                  count(*) FILTER (WHERE p.owns IS NOT NULL AND p.question IS NULL))
    FROM (
        SELECT * FROM epistemics.filed_absences
    ) f
    LEFT JOIN (SELECT owns, min(question) AS question FROM positions GROUP BY owns) p USING (owns)
    UNION ALL
    SELECT 'questions no position holds',
           count(*) = 0,
           format('%s question(s) on the census with no position%s', count(*),
                  coalesce(': ' || string_agg(q.question, ', '), ''))
    FROM (
        SELECT * FROM epistemics.absence_questions
    ) q
    WHERE q.question NOT IN (SELECT question FROM positions WHERE question IS NOT NULL)
) p ON true
WHERE a.slug = 'absences_filed'
UNION ALL
-- epistemics/derivations.sqlc against epistemics/filed_derivations.sqlc, through identities/roster.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH counted AS (
        SELECT c.owns, c.element, c.filing, c.identity, count(*) AS n
        FROM (
            -- every pm:derivation/identity in the schema, from every column that keeps one.
SELECT filing, subject, owns, coalesce(element, owns) AS element, identity FROM (
    SELECT filing, layer AS subject, 'pm:demand/pm:amount' AS owns, NULL::text AS element,
           derivation AS identity FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'pm:nameplate/pm:amount', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'pm:jagged/pm:draw', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:sign', NULL, sign_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer || ' / ' || buffer::text,
                     CASE s.buffer WHEN 'time'     THEN 'pm:layer/pm:timeSlack'
                                   WHEN 'capacity' THEN 'pm:nameplate/pm:capacitySlack'
                                   ELSE 'pm:nameplate/pm:inventorySlack' END,
                     NULL, derivation FROM (
        SELECT * FROM entries.slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text, 'pm:holder/pm:share', NULL, share_derivation FROM (
        SELECT * FROM entries.holders
    ) h
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, owns, element, identity FROM (
        SELECT * FROM epistemics.claim_derivations
    ) c
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'asrt:elimination/asrt:quantity', NULL, derivation FROM (
        SELECT * FROM eliminations.filed
    ) e
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'asrt:part/asrt:factor', NULL, factor_derivation FROM (
        SELECT * FROM composition.part_references
    ) pr
) d
WHERE identity IS NOT NULL

        ) c
        GROUP BY c.owns, c.element, c.filing, c.identity
    ),
    filed AS (
        SELECT f.owns, f.element, f.filing, f.identity, count(*) AS n
        FROM (
            SELECT * FROM epistemics.filed_derivations
        ) f
        GROUP BY f.owns, f.element, f.filing, f.identity
    ),
    cells AS (
        SELECT coalesce(c.owns, f.owns) AS owns, coalesce(c.element, f.element) AS element,
               coalesce(c.filing, f.filing) AS filing, coalesce(c.identity, f.identity) AS identity,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.owns = c.owns AND f.element = c.element AND f.filing = c.filing
                         AND f.identity = c.identity
    ),
    positions AS (
        SELECT DISTINCT r.owns, r.element
        FROM (
            SELECT * FROM identities.roster
        ) r
    )
    SELECT CASE WHEN q.element = q.owns THEN q.owns ELSE q.element || ' at ' || q.owns END AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing,
                                                     x.identity, x.filed, x.counted),
                                              '; ' ORDER BY x.filing, x.identity)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM positions q
    LEFT JOIN cells x ON x.owns = q.owns AND x.element = q.element
    GROUP BY q.owns, q.element
    UNION ALL
    SELECT 'pairs the roster does not admit',
           count(*) = 0,
           format('%s derivation(s) at a cell identities/roster.sqlc does not list%s', count(*),
                  coalesce(': ' || string_agg(DISTINCT f.element || ' at ' || f.owns || ' ' || f.identity::text, ', '), ''))
    FROM (
        SELECT * FROM epistemics.filed_derivations
    ) f
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT * FROM identities.roster
        ) r
        WHERE r.owns = f.owns AND r.element = f.element AND r.identity = f.identity::text
    )
) p ON true
WHERE a.slug = 'derivations_filed'
UNION ALL
-- folds/fusion_parts.sqlc per composition, against composition/part_references.sqlc counted directly.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.composition AS subject,
           x.empty = 0 AND x.parts = coalesce(y.references_filed, 0) AS holds,
           format('%s fusion(s), %s named by a part, %s part(s), %s filed%s',
                  x.fusions, x.fusions - x.empty, x.parts, coalesce(y.references_filed, 0),
                  coalesce(': none names ' || x.unnamed, '')) AS detail
    FROM (
        SELECT d.filing                                   AS composition,
               count(*)                                   AS fusions,
               count(*) FILTER (WHERE f.parts IS NULL)    AS empty,
               coalesce(sum(f.parts), 0)                  AS parts,
               string_agg(d.layer, ', ' ORDER BY d.layer)
                   FILTER (WHERE f.parts IS NULL)         AS unnamed
        FROM      (
            SELECT * FROM composition.fusions
        ) d
        LEFT JOIN (
            SELECT * FROM folds.fusion_parts
        ) f ON f.composition = d.filing AND f.composed_layer = d.layer
        GROUP BY d.filing
    ) x
    LEFT JOIN (
        SELECT pr.composition, count(*) AS references_filed
        FROM (
            SELECT * FROM composition.part_references
        ) pr
        GROUP BY pr.composition
    ) y ON y.composition = x.composition
) p ON true
WHERE a.slug = 'fusions_have_parts'
UNION ALL
-- epistemics/coupling_searches.sqlc against entries/couplings.sqlc, eliminations/searched.sqlc against eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT s.subject,
           count(*) FILTER (WHERE (s.answer IS NULL) <> (s.entries > 0)) = 0 AS holds,
           format('%s searched: %s filed entries, %s typed why not, %s both or neither',
                  count(*), count(*) FILTER (WHERE s.entries > 0 AND s.answer IS NULL),
                  count(*) FILTER (WHERE s.entries = 0 AND s.answer IS NOT NULL),
                  count(*) FILTER (WHERE (s.answer IS NULL) <> (s.entries > 0))) AS detail
    FROM (
        SELECT 'couplings' AS subject, cs.answer,
               (SELECT count(*) FROM (
                    SELECT * FROM entries.couplings
                ) c WHERE c.filing = cs.filing) AS entries
        FROM (
            SELECT * FROM epistemics.coupling_searches
        ) cs
        UNION ALL
        SELECT 'double counting', es.answer,
               (SELECT count(*) FROM (
                    SELECT * FROM eliminations.filed
                ) e WHERE e.composition = es.composition AND e.composed_layer = es.composed_layer)
        FROM (
            SELECT * FROM eliminations.searched
        ) es
    ) s
    GROUP BY s.subject
) p ON true
WHERE a.slug = 'searches_answered'
UNION ALL
-- every fold in folds/ whose population does not reach algebra/all.sqlc, its boxes against its rows and its rows against its population.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.unbalanced = 0 AND x.counted = x.population AS holds,
           format('%s rows over %s subjects, %s in the population; %s subjects whose boxes do not add up',
                  x.counted, x.subjects, x.population, x.unbalanced) AS detail
    FROM (
        SELECT 'rules' AS contract, f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM checks.all ) c) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.violated + s.passed) AS unbalanced
               FROM ( SELECT * FROM folds.rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM arithmetic.all ) z) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.computable + s.suspended + s.not_comparable) AS unbalanced
               FROM ( SELECT * FROM folds.site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM diagrams.catalogue ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM diagrams.expected ) e) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM epistemics.absence_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM epistemics.derivation_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'subject_boxes'
UNION ALL
-- composition/part_references.sqlc, each part's factor_state against the factor columns it carries.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_references' AS subject,
           count(*) FILTER (WHERE x.mislabelled) = 0 AS holds,
           format('%s parts: %s omitted, %s stated, %s absent, %s derivation; %s whose state is not the column they file',
                  count(*),
                  count(*) FILTER (WHERE x.factor_state = 'omitted'),
                  count(*) FILTER (WHERE x.factor_state = 'stated'),
                  count(*) FILTER (WHERE x.factor_state = 'absent'),
                  count(*) FILTER (WHERE x.factor_state = 'derivation'),
                  count(*) FILTER (WHERE x.mislabelled)) AS detail
    FROM (
        SELECT r.factor_state,
               r.factor_state IS NULL
                 OR (r.factor_state = 'stated')     <> (r.factor_low IS NOT NULL)
                 OR (r.factor_state = 'absent')     <> (r.factor_absent IS NOT NULL)
                 OR (r.factor_state = 'derivation') <> (r.factor_derivation IS NOT NULL)
                 OR (r.factor_state = 'omitted')
                      <> (num_nonnulls(r.factor_low, r.factor_absent, r.factor_derivation) = 0)
                   AS mislabelled
        FROM (
            SELECT * FROM composition.part_references
        ) r
    ) x
) p ON true
WHERE a.slug = 'factor_state'
UNION ALL
-- layers/summed_quantities.sqlc against composition/fusion_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/fusion_quantities' AS subject,
           x.total = x.leaves + x.fused AS holds,
           format('%s summed quantities = %s of layers no fusion names + %s of composed layers',
                  x.total, x.leaves, x.fused) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) s)  AS total,
             (SELECT count(*) FROM ( SELECT * FROM layers.summed_quantities ) s
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.fusions ) f
                                  WHERE f.filing = s.filing AND f.layer = s.layer))   AS leaves,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusion_quantities ) q) AS fused
         ) x
) p ON true
WHERE a.slug = 'fusion_quantities'
UNION ALL
-- folds/part_sums.sqlc summed over every fusion, against composition/converted.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT c.quantity::text AS subject,
           c.parts = f.parts AND c.low = f.low AND c.mode = f.mode AND c.high = f.high AS holds,
           format('%s parts summing to [%s, %s, %s]; the fold holds %s summing to [%s, %s, %s]',
                  c.parts, c.low, c.mode, c.high, f.parts, f.low, f.mode, f.high) AS detail
    FROM (
        SELECT v.quantity, count(*) AS parts, sum(v.low) AS low, sum(v.mode) AS mode,
               sum(v.high) AS high
        FROM (
            SELECT * FROM composition.converted
        ) v
        GROUP BY v.quantity
    ) c
    LEFT JOIN (
        SELECT s.quantity, sum(s.parts) AS parts, sum(s.sum_low) AS low, sum(s.sum_mode) AS mode,
               sum(s.sum_high) AS high
        FROM (
            SELECT * FROM folds.part_sums
        ) s
        GROUP BY s.quantity
    ) f ON f.quantity = c.quantity
) p ON true
WHERE a.slug = 'part_sums'
UNION ALL
-- composition/fusions.sqlc × pm.summed_quantity, against composition/suspended_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/suspended_quantities' AS subject,
           x.total = x.owing + x.suspended AS holds,
           format('%s fusion quantities = %s no ground reaches + %s suspended',
                  x.total, x.owing, x.suspended) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.fusions ) f
               CROSS JOIN unnest(enum_range(NULL::pm.summed_quantity)) AS q(quantity)
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM composition.suspended_fusions ) s
                                  WHERE s.composition = f.filing AND s.composed_layer = f.layer
                                    AND (s.quantity IS NULL OR s.quantity = q.quantity)))    AS owing,
             (SELECT count(*) FROM ( SELECT * FROM composition.suspended_quantities ) s)       AS suspended
         ) x
) p ON true
WHERE a.slug = 'suspended_quantities'
UNION ALL
-- composition/unsized_conversions.sqlc projected onto its composed layers, inside composition/unsettled.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/unsized_conversions' AS subject,
           count(*) FILTER (WHERE u.filing IS NULL) = 0 AS holds,
           format('%s composed layer(s) cannot size a conversion, %s cannot be differenced, %s outside%s',
                  count(*), (SELECT count(*) FROM ( SELECT * FROM composition.unsettled ) t),
                  count(*) FILTER (WHERE u.filing IS NULL),
                  coalesce(': ' || string_agg(c.composition || '/' || c.composed_layer, ', '
                                              ORDER BY c.composition, c.composed_layer)
                                   FILTER (WHERE u.filing IS NULL), '')) AS detail
    FROM      (
        SELECT DISTINCT composition, composed_layer
        FROM ( SELECT * FROM composition.unsized_conversions ) x
    ) c
    LEFT JOIN (
        SELECT * FROM composition.unsettled
    ) u ON u.filing = c.composition AND u.layer = c.composed_layer
) p ON true
WHERE a.slug = 'unsized_conversions_are_unsettled'
UNION ALL
-- composition/parts.sqlc with layers/quantities.sqlc, against composition/part_quantities.sqlc and its complement.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/part_quantities' AS subject,
           x.total = x.alone + x.paired AS holds,
           format('%s part quantities = %s the composed layer does not file + %s set beside it',
                  x.total, x.alone, x.paired) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.parts ) p
               JOIN ( SELECT * FROM layers.quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer)                  AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.parts ) p
               JOIN ( SELECT * FROM layers.quantities ) q
                 ON q.filing = p.part_filing AND q.layer = p.part_layer
               WHERE NOT EXISTS (SELECT 1 FROM ( SELECT * FROM layers.quantities ) c
                                  WHERE c.filing = p.composition AND c.layer = p.composed_layer
                                    AND c.quantity = q.quantity))                        AS alone,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_quantities ) x)       AS paired
         ) x
) p ON true
WHERE a.slug = 'part_quantities'
UNION ALL
-- layers/figures.sqlc against layers/demand.sqlc and layers/nameplate.sqlc counted by themselves.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/figures' AS subject,
           x.pairs = x.demands + x.nameplates - x.both AS holds,
           format('%s layers with a figure = %s with a demand + %s with a nameplate - %s with both',
                  x.pairs, x.demands, x.nameplates, x.both) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.figures ) f)     AS pairs,
             (SELECT count(*) FROM ( SELECT * FROM layers.demand ) d)      AS demands,
             (SELECT count(*) FROM ( SELECT * FROM layers.nameplate ) n)   AS nameplates,
             (SELECT count(*) FROM ( SELECT * FROM layers.demand ) d
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM layers.nameplate ) n
                              WHERE n.filing = d.filing AND n.layer = d.layer))  AS both
         ) x
) p ON true
WHERE a.slug = 'figures'
UNION ALL
-- entries/holder_totals.sqlc against folds/served_totals.sqlc and entries/unserved_totals.sqlc, per layer.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'folds/served_totals' AS subject,
           count(*) FILTER (WHERE NOT x.balances) = 0 AS holds,
           format('%s layers with a holder, %s where held = served + unserved%s',
                  count(*), count(*) FILTER (WHERE x.balances),
                  coalesce(': not on ' || string_agg(x.filing || '/' || x.layer, ', ' ORDER BY x.filing, x.layer)
                                           FILTER (WHERE NOT x.balances), '')) AS detail
    FROM (
        SELECT t.filing, t.layer,
               t.holders = coalesce(s.holders, 0) + coalesce(u.holders, 0)
                 AND coalesce(t.shares_mode, 0) = coalesce(s.served_mode, 0) + coalesce(u.unserved_mode, 0)
                   AS balances
        FROM      (
            SELECT * FROM entries.holder_totals
        ) t
        LEFT JOIN (
            SELECT * FROM folds.served_totals
        ) s ON s.filing = t.filing AND s.layer = t.layer
        LEFT JOIN (
            SELECT * FROM entries.unserved_totals
        ) u ON u.filing = t.filing AND u.layer = t.layer
    ) x
) p ON true
WHERE a.slug = 'served_totals'
UNION ALL
-- composition/derived_quantities.sqlc against composition/parts.sqlc, composition/resolved_quantities.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT d.filing || ' / ' || d.layer || ' / ' || d.quantity AS subject,
           (d.low IS NULL) = (x.low IS NULL)
           AND (d.low IS NULL
                OR (abs(d.low  - x.low)  < 1e-9 AND abs(d.mode - x.mode) < 1e-9
                    AND abs(d.high - x.high) < 1e-9))                          AS holds,
           CASE WHEN d.low IS NOT NULL
                THEN format('walked [%s, %s, %s], one level [%s, %s, %s]',
                            d.low, d.mode, d.high, x.low, x.mode, x.high)
                ELSE format('not computable: %s; one level %s', d.blocked_because,
                            CASE WHEN x.low IS NULL THEN 'cannot compute it either'
                                 ELSE format('gives [%s, %s, %s]', x.low, x.mode, x.high) END)
           END                                                                 AS detail
    FROM (
        SELECT * FROM composition.derived_quantities
    ) d
    LEFT JOIN (
        SELECT s.filing, s.layer, s.quantity,
               CASE WHEN ok THEN s_low  - e_low  END AS low,
               CASE WHEN ok THEN s_mode - e_mode END AS mode,
               CASE WHEN ok THEN s_high - e_high END AS high
        FROM (
            SELECT t.*,
                   t.parts > 0 AND t.parts = t.resolved_parts AND t.figures = t.parts
                   AND t.searched_ok AND t.e_ok
                   AND t.s_low - t.e_low <= t.s_mode - t.e_mode
                   AND t.s_mode - t.e_mode <= t.s_high - t.e_high AS ok
            FROM (
                SELECT f.filing, f.layer, f.quantity,
                       coalesce(r.parts, 0) AS parts,
                       count(p.part_layer) AS resolved_parts,
                       count(q.low) FILTER (WHERE p.factor_state IN ('omitted', 'stated')) AS figures,
                       sum(least(   q.low  * coalesce(p.factor_low, 1),
                                    q.low  * coalesce(p.factor_high, 1))) AS s_low,
                       sum(q.mode * coalesce(p.factor_mode, 1))           AS s_mode,
                       sum(greatest(q.high * coalesce(p.factor_low, 1),
                                    q.high * coalesce(p.factor_high, 1))) AS s_high,
                       coalesce(max(e.low),  0) AS e_low,
                       coalesce(max(e.mode), 0) AS e_mode,
                       coalesce(max(e.high), 0) AS e_high,
                       bool_and(e.absent IS NULL AND e.derivation IS NULL) IS NOT FALSE AS e_ok,
                       coalesce(max(es.answer::text), '') <> 'unmeasured' AS searched_ok
                FROM      (
                    SELECT s.filing, s.layer, s.quantity
                    FROM ( SELECT * FROM layers.summed_quantities ) s
                    WHERE s.derivation IS NOT NULL
                ) f
                LEFT JOIN (
                    SELECT * FROM folds.fusion_parts
                ) r ON r.composition = f.filing AND r.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM composition.parts
                ) p ON p.composition = f.filing AND p.composed_layer = f.layer
                LEFT JOIN (
                    SELECT * FROM composition.resolved_quantities
                ) q ON q.filing = p.part_filing AND q.layer = p.part_layer AND q.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM eliminations.filed
                ) e ON e.composition = f.filing AND e.composed_layer = f.layer AND e.quantity = f.quantity
                LEFT JOIN (
                    SELECT * FROM eliminations.searched
                ) es ON es.composition = f.filing AND es.composed_layer = f.layer
                GROUP BY f.filing, f.layer, f.quantity, r.parts
            ) t
        ) s
    ) x ON x.filing = d.filing AND x.layer = d.layer AND x.quantity = d.quantity
) p ON true
WHERE a.slug = 'derived_quantities'
UNION ALL
-- composition/part_references.sqlc partitioned by composition/parts.sqlc into composition/unresolved_parts.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'composition/unresolved_parts' AS subject,
           x.total = x.kept + x.resolved AS holds,
           format('%s part references = %s unresolved + %s resolved', x.total, x.kept, x.resolved)
               AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM composition.part_references ) r) AS total,
             (SELECT count(*) FROM ( SELECT * FROM composition.unresolved_parts ) u) AS kept,
             (SELECT count(*) FROM ( SELECT * FROM composition.part_references ) r
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.parts ) p
                             WHERE p.composition = r.composition
                               AND p.composed_layer = r.composed_layer
                               AND p.part_notation = r.part_filing
                               AND p.part_layer = r.part_layer))                    AS resolved
         ) x
) p ON true
WHERE a.slug = 'unresolved_parts'
UNION ALL
-- layers/differenced_remainder.sqlc partitioned by composition/figureless_remainders.sqlc into layers/remainder.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'layers/remainder' AS subject,
           x.total = x.kept + x.removed AS holds,
           format('%s differenced = %s in force + %s with no legitimate figure', x.total, x.kept,
                  x.removed) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM layers.differenced_remainder ) b) AS total,
             (SELECT count(*) FROM ( SELECT * FROM layers.remainder ) r)             AS kept,
             (SELECT count(*) FROM ( SELECT * FROM layers.differenced_remainder ) b
               WHERE EXISTS (SELECT 1 FROM ( SELECT * FROM composition.figureless_remainders ) g
                             WHERE g.filing = b.filing AND g.layer = b.layer))  AS removed
         ) x
) p ON true
WHERE a.slug = 'remainder_in_force'

