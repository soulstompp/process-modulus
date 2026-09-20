-- composition/derived_frontier.sqlc summed at the nodes stating the figure, less eliminations/filed.sqlc at the root and each derived node passed.
WITH
root AS (
    SELECT s.filing, s.layer, s.quantity, s.derivation, coalesce(b.parts, 0) AS parts
    FROM      ( SELECT * FROM layers.summed_quantities ) s
    LEFT JOIN (
        SELECT * FROM folds.fusion_parts
    ) b ON b.composition = s.filing AND b.composed_layer = s.layer
    WHERE s.derivation IS NOT NULL
),
node AS (
    SELECT w.root_filing, w.root_layer, w.quantity, w.filing, w.layer, w.depth,
           w.factor_low, w.factor_mode, w.factor_high, w.part_of, w.conversion_absent,
           w.conversion_derivation, w.is_cycle,
           w.low, w.mode, w.high, w.unit, w.absent, w.derivation, w.is_fusion
    FROM ( -- layers/summed_quantities.sqlc filed as a derivation, walked through composition/parts.sqlc while the node's figure is derived too.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition.parts
),
figure AS (
    SELECT s.filing, s.layer, s.quantity, s.low, s.mode, s.high, s.unit, s.absent, s.derivation,
           (f.filing IS NOT NULL) AS is_fusion
    FROM      (
        SELECT * FROM layers.summed_quantities
    ) s
    LEFT JOIN (
        SELECT * FROM composition.fusions
    ) f ON f.filing = s.filing AND f.layer = s.layer
),
walk(root_filing, root_layer, quantity, filing, layer, depth,
     factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
     conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion) AS (
        SELECT r.filing, r.layer, r.quantity, p.part_filing, p.part_layer, 1,
               coalesce(p.factor_low, 1), coalesce(p.factor_mode, 1), coalesce(p.factor_high, 1),
               p.factor_state IN ('absent', 'derivation'), p.composed_layer,
               p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      figure r
        JOIN      resolved p ON p.composition = r.filing AND p.composed_layer = r.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = r.quantity
        WHERE r.derivation IS NOT NULL
    UNION ALL
        SELECT w.root_filing, w.root_layer, w.quantity, p.part_filing, p.part_layer, w.depth + 1,
               w.factor_low  * coalesce(p.factor_low,  1),
               w.factor_mode * coalesce(p.factor_mode, 1),
               w.factor_high * coalesce(p.factor_high, 1),
               w.factor_absent OR p.factor_state IN ('absent', 'derivation'),
               p.composed_layer, p.factor_absent, p.factor_derivation,
               n.low, n.mode, n.high, n.unit, n.absent, n.derivation, coalesce(n.is_fusion, false)
        FROM      walk w
        JOIN      resolved p ON p.composition = w.filing AND p.composed_layer = w.layer
        LEFT JOIN figure n   ON n.filing = p.part_filing AND n.layer = p.part_layer
                            AND n.quantity = w.quantity
        WHERE w.derivation IS NOT NULL
) CYCLE filing, layer SET is_cycle USING route
SELECT root_filing, root_layer, quantity, filing, layer, depth,
       factor_low, factor_mode, factor_high, factor_absent, part_of, conversion_absent,
       conversion_derivation, low, mode, high, unit, absent, derivation, is_fusion, is_cycle
FROM walk
 ) w
),
passed AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity, r.filing, r.layer,
           1::numeric AS factor_low, 1::numeric AS factor_mode, 1::numeric AS factor_high,
           false AS below
    FROM root r
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity, n.filing, n.layer,
           n.factor_low, n.factor_mode, n.factor_high, true
    FROM node n
    WHERE n.derivation IS NOT NULL AND n.is_fusion AND NOT n.is_cycle
),
elimination AS (
    SELECT p.root_filing, p.root_layer, p.quantity, p.filing, p.layer, p.below,
           least(   e.low  * p.factor_low, e.low  * p.factor_high) AS e_low,
           e.mode * p.factor_mode                                  AS e_mode,
           greatest(e.high * p.factor_low, e.high * p.factor_high) AS e_high,
           e.absent AS e_absent, e.derivation AS e_derivation,
           es.answer AS searched
    FROM      passed p
    LEFT JOIN ( SELECT * FROM eliminations.filed ) e
           ON e.composition = p.filing AND e.composed_layer = p.layer AND e.quantity = p.quantity
    LEFT JOIN ( SELECT * FROM eliminations.searched ) es
           ON es.composition = p.filing AND es.composed_layer = p.layer
),
unresolved AS MATERIALIZED (
    SELECT DISTINCT u.composition, u.composed_layer
    FROM ( SELECT * FROM composition.unresolved_parts ) u
),
reason AS (
    SELECT r.filing AS root_filing, r.layer AS root_layer, r.quantity,
           format('no fusion here builds `%s`', r.layer) AS why
    FROM root r
    WHERE r.parts = 0
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           CASE WHEN n.is_cycle THEN format('the walk closes a cycle at `%s`', n.layer)
                WHEN n.low IS NULL AND n.derivation IS NULL
                     THEN format('`%s` files its %s %s', n.layer, n.quantity,
                                 coalesce(n.absent::text, 'nowhere'))
                ELSE format('`%s` files its %s as its fusion''s sum and no fusion builds it',
                            n.layer, n.quantity) END
    FROM node n
    WHERE n.is_cycle
       OR (n.low IS NULL AND (n.derivation IS NULL OR NOT n.is_fusion))
    UNION ALL
    SELECT n.root_filing, n.root_layer, n.quantity,
           format('the conversion of `%s` into `%s` is %s', n.layer, n.part_of,
                  coalesce(n.conversion_absent::text,
                           format('filed as `%s`, and no computation of it is wired in',
                                  n.conversion_derivation)))
    FROM node n
    WHERE n.conversion_absent IS NOT NULL OR n.conversion_derivation IS NOT NULL
    UNION ALL
    SELECT e.root_filing, e.root_layer, e.quantity,
           CASE WHEN e.searched = 'unmeasured'
                THEN format('`%s` never searched for double counting', e.layer)
                ELSE format('the %s elimination at `%s` is %s', e.quantity, e.layer,
                            coalesce(e.e_absent::text,
                                     format('filed as `%s`, and no computation of it is wired in',
                                            e.e_derivation))) END
    FROM elimination e
    WHERE e.searched = 'unmeasured' OR e.e_absent IS NOT NULL OR e.e_derivation IS NOT NULL
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('a part of `%s` resolves to no filing here', p.layer)
    FROM passed p
    JOIN unresolved u ON u.composition = p.filing AND u.composed_layer = p.layer
),
level AS (
    SELECT r.filing, r.layer, r.quantity, r.derivation,
           coalesce(st.x_low, 0)  - coalesce(pb.e_low, 0)  AS s_low,
           coalesce(st.x_mode, 0) - coalesce(pb.e_mode, 0) AS s_mode,
           coalesce(st.x_high, 0) - coalesce(pb.e_high, 0) AS s_high,
           coalesce(er.e_low, 0) AS e_low, coalesce(er.e_mode, 0) AS e_mode,
           coalesce(er.e_high, 0) AS e_high,
           st.unit
    FROM root r
    LEFT JOIN (
        SELECT n.root_filing, n.root_layer, n.quantity,
               sum(least(   n.low  * n.factor_low, n.low  * n.factor_high)) AS x_low,
               sum(n.mode * n.factor_mode)                                  AS x_mode,
               sum(greatest(n.high * n.factor_low, n.high * n.factor_high)) AS x_high,
               CASE WHEN count(DISTINCT n.unit) = 1
                         AND bool_and(n.factor_low = 1 AND n.factor_high = 1)
                    THEN min(n.unit) END AS unit
        FROM node n
        WHERE n.low IS NOT NULL
        GROUP BY n.root_filing, n.root_layer, n.quantity
    ) st ON st.root_filing = r.filing AND st.root_layer = r.layer AND st.quantity = r.quantity
    LEFT JOIN (
        SELECT e.root_filing, e.root_layer, e.quantity,
               sum(e.e_low) AS e_low, sum(e.e_mode) AS e_mode, sum(e.e_high) AS e_high
        FROM elimination e
        WHERE e.below
        GROUP BY e.root_filing, e.root_layer, e.quantity
    ) pb ON pb.root_filing = r.filing AND pb.root_layer = r.layer AND pb.quantity = r.quantity
    LEFT JOIN elimination er
           ON er.root_filing = r.filing AND er.root_layer = r.layer AND er.quantity = r.quantity
          AND NOT er.below
),
inverts AS (
    SELECT l.filing, l.layer, l.quantity,
           (l.s_low <= l.s_mode AND l.s_mode <= l.s_high) AS own
    FROM level l
    WHERE NOT (l.s_low - l.e_low <= l.s_mode - l.e_mode AND l.s_mode - l.e_mode <= l.s_high - l.e_high)
),
blocked AS (
    SELECT root_filing, root_layer, quantity, why FROM reason
    UNION ALL
    SELECT i.filing, i.layer, i.quantity,
           CASE WHEN i.own
                THEN format('the %s elimination at `%s` is wider than its sum and inverts it',
                            i.quantity, i.layer)
                ELSE format('an elimination below `%s` inverts the %s sum', i.layer, i.quantity) END
    FROM inverts i
    UNION ALL
    SELECT p.root_filing, p.root_layer, p.quantity,
           format('the %s elimination at `%s` is wider than its sum and inverts it', p.quantity, p.layer)
    FROM passed p
    JOIN inverts i ON i.filing = p.filing AND i.layer = p.layer AND i.quantity = p.quantity
    WHERE p.below
)
SELECT l.filing, l.layer, l.quantity, l.derivation,
       CASE WHEN b.why IS NULL THEN l.s_low  - l.e_low  END AS low,
       CASE WHEN b.why IS NULL THEN l.s_mode - l.e_mode END AS mode,
       CASE WHEN b.why IS NULL THEN l.s_high - l.e_high END AS high,
       CASE WHEN b.why IS NULL THEN l.unit END AS unit,
       b.why AS blocked_because
FROM level l
LEFT JOIN (
    SELECT root_filing, root_layer, quantity, string_agg(DISTINCT why, '; ' ORDER BY why) AS why
    FROM blocked
    GROUP BY root_filing, root_layer, quantity
) b ON b.root_filing = l.filing AND b.root_layer = l.layer AND b.quantity = l.quantity
