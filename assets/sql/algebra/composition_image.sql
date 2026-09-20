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
