-- pm:Stack/pm:couplings/pm:absent, over the corpus.
WITH epistemics_coupling_searches AS (
-- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
)
SELECT CASE
         WHEN s.answer IS NULL              THEN 'somebody looked and the layers move together'
         WHEN s.answer = 'none'             THEN 'somebody looked and found independence'
         WHEN s.answer = 'notApplicable'    THEN 'one layer; no pair to couple'
         ELSE 'nobody looked'
       END AS the_independence_assumption,
       count(*) AS stacks
FROM (
    SELECT * FROM epistemics_coupling_searches
) s
JOIN (
    SELECT * FROM scope_corpus
) c USING (filing)
GROUP BY 1 ORDER BY 2 DESC
