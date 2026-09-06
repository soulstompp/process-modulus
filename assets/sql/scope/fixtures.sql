-- from pm.filing where evidence = 'stipulation'; see assets/fixtures/README.md.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'stipulation'
