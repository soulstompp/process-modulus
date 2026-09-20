-- pm:Claim/pm:boundOrigin, over the corpus.
SELECT e.who_owns_the_edge, count(*) AS claims
FROM (
    SELECT * FROM epistemics.edges
) e
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
