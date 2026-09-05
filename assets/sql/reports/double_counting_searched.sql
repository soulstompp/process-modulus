-- pm:Fusion/pm:Eliminations/pm:Absent, over the corpus.
SELECT coalesce(s.answer::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN s.answer = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM (
    -- pm:Stack/pm:Couplings and pm:Fusion/pm:Eliminations, each with its pm:Absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.absent AS answer, cs.note
FROM pm.coupling_search cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.absent, es.note
FROM pm.elimination_search es

) s
JOIN (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) c USING (filing)
WHERE s.looked_for = 'double counting across parts'
GROUP BY 1, 3 ORDER BY 2 DESC
