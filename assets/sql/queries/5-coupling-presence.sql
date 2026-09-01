-- §5  What each filing says about couplings — and whether it says anything at all.
--
-- One row per corpus filing: how many couplings it states, and what its coupling SEARCH
-- reported if it states none. Those are two different facts and an empty table carries only
-- the first.
--
-- ⛔⛔ CORPUS ONLY, AND THIS IS A REPORT RATHER THAN A RULE, WHICH IS THE WHOLE REASON THE
-- DISTINCTION EXISTS. "No filing asserts independence" is a fact about THE EVIDENCE; a
-- stipulation that asserts it makes the finding a lie. `assets/fixtures/every-absence.xml`
-- files exactly that, on purpose, to prove the branch works — and it must not be counted
-- here. Rules run on fixtures; reports about the world do not.
-- See `assets/fixtures/README.md`.
SELECT f.name           AS "filing!",
       count(c.*)       AS "n!",
       cs.absent::text  AS why
FROM pm.filing f
LEFT JOIN pm.coupling c ON c.filing = f.name
LEFT JOIN pm.coupling_search cs ON cs.filing = f.name
WHERE f.evidence = 'corpus'
GROUP BY f.name, cs.absent
ORDER BY f.name
