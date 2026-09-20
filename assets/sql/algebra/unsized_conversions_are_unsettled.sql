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
