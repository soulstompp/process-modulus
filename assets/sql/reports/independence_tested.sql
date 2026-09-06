-- pm:Stack/pm:Couplings/pm:Absent, over the corpus.
SELECT CASE
         WHEN s.answer IS NULL              THEN 'somebody looked and the layers MOVE TOGETHER'
         WHEN s.answer = 'none'             THEN 'somebody looked and found independence'
         WHEN s.answer = 'notApplicable'    THEN 'one layer; no pair to couple'
         ELSE 'NOBODY LOOKED'
       END AS the_independence_assumption,
       count(*) AS stacks
FROM (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s
JOIN (
    -- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')

) c USING (filing)
GROUP BY 1 ORDER BY 2 DESC
