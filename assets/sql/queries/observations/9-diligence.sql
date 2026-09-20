-- §9  Across every kind of search this model defines, how often did somebody actually look?
-- epistemics/searches.sqlc, folded by question and answer.
SELECT s.looked_for                                   AS "looked_for!",
       coalesce(s.answer::text, 'filed the thing')    AS "answer!",
       count(*)                                       AS "times!"
FROM (
    SELECT * FROM epistemics.searches
) s
GROUP BY s.looked_for, s.answer
ORDER BY s.looked_for, count(*) DESC, 2
