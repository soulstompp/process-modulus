-- §5  The two self-joins of F, and the fibre profile each one's size is fixed by.
-- composition/parts.sqlc grouped by each self-join's key, beside the self-join itself.
SELECT 'composition/sibling_parts.sqlc' AS "relation!", 'ordered, reflexive kept' AS "pairing!",
       f.k AS "k!", count(*) AS "fibres!",
       (SELECT count(*) FROM ( SELECT * FROM composition.sibling_parts ) s) AS "joined!"
FROM ( SELECT count(*) AS k
       FROM ( SELECT * FROM composition.parts ) p
       WHERE p.composition IS NOT NULL AND p.composed_layer IS NOT NULL
         AND p.part_filing IS NOT NULL
       GROUP BY p.composition, p.composed_layer, p.part_filing ) f
GROUP BY f.k
UNION ALL
SELECT 'eliminations/derived.sqlc', 'unordered, reflexive dropped',
       f.k, count(*),
       (SELECT count(*) FROM ( SELECT * FROM eliminations.derived ) d)
FROM ( SELECT count(*) AS k
       FROM ( SELECT * FROM composition.parts ) p
       WHERE p.part_filing IS NOT NULL AND p.part_layer IS NOT NULL
       GROUP BY p.part_filing, p.part_layer ) f
GROUP BY f.k
ORDER BY 1, 3
