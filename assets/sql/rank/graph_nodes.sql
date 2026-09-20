-- rank/graph_edges.sqlc's endpoints, with evaluation_order and layer_reach joined at (filing, layer).
SELECT 'layers' AS graph,
       e.filing || '/' || e.layer AS node,
       r.rank                     AS rank,
       c.examined_by              AS examined_by,
       c.violated                 AS violated
FROM (
    SELECT p.composition AS filing, p.composed_layer AS layer
    FROM ( SELECT * FROM composition.parts ) p
    UNION
    SELECT p.part_filing, p.part_layer
    FROM ( SELECT * FROM composition.parts ) p
) e
LEFT JOIN (
    -- composition/descent.sqlc aggregated to the deepest arrival under each layer.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
part_references AS NOT MATERIALIZED (
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
parts AS NOT MATERIALIZED (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition.part_references
) p
JOIN      (
    SELECT * FROM composition.notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

),
descent AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:Part followed transitively through pm.filing_identity.
WITH RECURSIVE
resolved AS (
    SELECT * FROM composition.parts
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

),
every_layer AS NOT MATERIALIZED (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

)
SELECT l.filing, l.layer,
       CASE WHEN coalesce(bool_or(d.is_cycle), false) THEN NULL
            ELSE coalesce(max(d.depth), 0) END AS rank,
       count(d.filing)           AS arrivals
FROM      (
    SELECT * FROM layers.every_layer
) l
LEFT JOIN (
    SELECT * FROM composition.descent
) d ON d.root_filing = l.filing AND d.root_layer = l.layer
GROUP BY l.filing, l.layer

) r ON r.filing = e.filing AND r.layer = e.layer
LEFT JOIN (
    SELECT * FROM rank.layer_reach
) c ON c.filing = e.filing AND c.layer = e.layer
UNION ALL
SELECT 'units', u.unit, NULL, NULL, NULL
FROM (
    SELECT c.from_unit AS unit FROM ( SELECT * FROM units.conversions ) c
    UNION
    SELECT c.to_unit        FROM ( SELECT * FROM units.conversions ) c
) u
