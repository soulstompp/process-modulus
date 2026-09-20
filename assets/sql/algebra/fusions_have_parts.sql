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
