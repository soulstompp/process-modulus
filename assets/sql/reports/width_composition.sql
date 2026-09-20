-- pm:Claim/pm:narrowsWhen kinds, over the corpus.
SELECT w.what_the_width_is_made_of, count(*) AS claims
FROM (
    SELECT * FROM epistemics.widths
) w
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
