-- §5  What each filing says about couplings, and whether it says anything at all.
-- entries/coupling_presence.sqlc over scope/corpus.sqlc.
SELECT p.filing            AS "filing!",
       p.couplings_filed   AS "n!",
       p.search_answer::text AS why
FROM (
    -- pm:Stack/pm:couplings against pm:couplings/pm:absent, over a scope the caller names.
SELECT f.filing,
       count(c.filing) AS couplings_filed,
       s.answer        AS search_answer
FROM      (
    -- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')

) f
LEFT JOIN (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c USING (filing)
LEFT JOIN (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s ON s.filing = f.filing
GROUP BY f.filing, s.answer

) p
ORDER BY p.filing
