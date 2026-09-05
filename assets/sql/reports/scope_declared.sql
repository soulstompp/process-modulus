-- pm:Stack/pm:scope over scope/corpus.sqlc; the extent axis is documented on that element.
SELECT CASE
         WHEN sc.extent = 'complete'  THEN 'the whole system is in this stack'
         WHEN sc.extent = 'scoped'    THEN 'a bounded selection: somebody said what is outside'
         WHEN sc.extent = 'unbounded' THEN 'NOBODY LOOKED at what lies outside'
         ELSE 'not stated: ' || sc.absent
       END      AS how_much_of_the_system,
       count(*) AS stacks
FROM      (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc
JOIN      (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
