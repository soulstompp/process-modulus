-- pm:Stack/pm:scope over scope/corpus.sqlc; the extent axis is documented on that element.
SELECT CASE
         WHEN sc.extent = 'complete'  THEN 'the whole system is in this stack'
         WHEN sc.extent = 'scoped'    THEN 'a bounded selection: somebody said what is outside'
         WHEN sc.extent = 'unbounded' THEN 'NOBODY LOOKED at what lies outside'
         ELSE 'not stated: ' || sc.absent
       END      AS how_much_of_the_system,
       count(*) AS stacks
FROM      (
    SELECT * FROM epistemics.scopes
) sc
JOIN      (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
