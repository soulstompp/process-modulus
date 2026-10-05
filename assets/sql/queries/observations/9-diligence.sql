-- §9  Across every kind of search this model defines, how often did somebody actually look?
-- epistemics/searches.sqlc, folded by question and answer.
WITH epistemics_coupling_searches AS (
-- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
),
eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
),
epistemics_searches AS (
-- pm:Stack/pm:couplings and asrt:Fusion/asrt:eliminations, each with its pm:absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.answer, cs.note
FROM (
    SELECT * FROM epistemics_coupling_searches
) cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.answer, es.note
FROM (
    SELECT * FROM eliminations_searched
) es
)
SELECT s.looked_for                                   AS "looked_for!",
       coalesce(s.answer::text, 'filed the thing')    AS "answer!",
       count(*)                                       AS "times!"
FROM (
    SELECT * FROM epistemics_searches
) s
GROUP BY s.looked_for, s.answer
ORDER BY s.looked_for, count(*) DESC, 2
