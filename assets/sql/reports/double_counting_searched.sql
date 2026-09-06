-- pm:Fusion/pm:Eliminations/pm:Absent, over the corpus.
SELECT coalesce(s.answer::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN s.answer = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) s
JOIN (
    -- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')

) c ON c.filing = s.composition
GROUP BY 1, 3 ORDER BY 2 DESC
