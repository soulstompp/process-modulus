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
