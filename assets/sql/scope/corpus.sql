-- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'
