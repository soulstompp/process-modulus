-- asrt:Fusion/asrt:eliminations/pm:absent, over the corpus.
WITH eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
)
SELECT coalesce(s.answer::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN s.answer = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM (
    SELECT * FROM eliminations_searched
) s
JOIN (
    SELECT * FROM scope_corpus
) c ON c.filing = s.composition
GROUP BY 1, 3 ORDER BY 2 DESC
