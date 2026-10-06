-- pm:Stack/pm:scope over scope/corpus.sqlc; the extent axis is documented on that element.
WITH epistemics_scopes AS (
-- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
)
SELECT CASE
         WHEN sc.extent = 'complete'  THEN 'the whole system is in this stack'
         WHEN sc.extent = 'scoped'    THEN 'a bounded selection: somebody said what is outside'
         WHEN sc.extent = 'unbounded' THEN 'nobody looked at what lies outside'
         ELSE 'not stated: ' || sc.absent
       END      AS how_much_of_the_system,
       count(*) AS stacks
FROM      (
    SELECT * FROM epistemics_scopes
) sc
JOIN      (
    SELECT * FROM scope_corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
