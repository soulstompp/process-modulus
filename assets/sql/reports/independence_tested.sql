-- pm:Stack/pm:Couplings/pm:Absent, over the corpus.
SELECT CASE
         WHEN s.answer IS NULL              THEN 'somebody looked and the layers MOVE TOGETHER'
         WHEN s.answer = 'none'             THEN 'somebody looked and found independence'
         WHEN s.answer = 'notApplicable'    THEN 'one layer; no pair to couple'
         ELSE 'NOBODY LOOKED'
       END AS the_independence_assumption,
       count(*) AS stacks
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
WHERE s.looked_for = 'couplings between layers'
GROUP BY 1 ORDER BY 2 DESC
