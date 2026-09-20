-- pm:Stack/pm:couplings/pm:absent, over the corpus.
SELECT CASE
         WHEN s.answer IS NULL              THEN 'somebody looked and the layers MOVE TOGETHER'
         WHEN s.answer = 'none'             THEN 'somebody looked and found independence'
         WHEN s.answer = 'notApplicable'    THEN 'one layer; no pair to couple'
         ELSE 'NOBODY LOOKED'
       END AS the_independence_assumption,
       count(*) AS stacks
FROM (
    SELECT * FROM epistemics.coupling_searches
) s
JOIN (
    SELECT * FROM scope.corpus
) c USING (filing)
GROUP BY 1 ORDER BY 2 DESC
