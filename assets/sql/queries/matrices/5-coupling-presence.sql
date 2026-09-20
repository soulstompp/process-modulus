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
    SELECT * FROM scope.corpus
) f
LEFT JOIN (
    SELECT * FROM entries.couplings
) c USING (filing)
LEFT JOIN (
    SELECT * FROM epistemics.coupling_searches
) s ON s.filing = f.filing
GROUP BY f.filing, s.answer

) p
ORDER BY p.filing
