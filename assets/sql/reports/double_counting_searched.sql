-- asrt:Fusion/asrt:eliminations/pm:absent, over the corpus.
SELECT coalesce(s.answer::text, 'eliminations filed') AS the_search,
       count(*) AS fusions,
       CASE WHEN s.answer = 'unmeasured' THEN 'sum rule SUSPENDED'
            ELSE 'sum rule exact' END AS what_is_owed
FROM (
    SELECT * FROM eliminations.searched
) s
JOIN (
    SELECT * FROM scope.corpus
) c ON c.filing = s.composition
GROUP BY 1, 3 ORDER BY 2 DESC
