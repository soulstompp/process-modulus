-- epistemics/widths.sqlc against epistemics/edges.sqlc, joined on the claim they share.
SELECT w.what_the_width_is_made_of AS what_would_narrow_it,
       e.who_owns_the_edge         AS who_owns_the_edge,
       count(*)                    AS claims
FROM      (
    SELECT * FROM epistemics.widths
) w
JOIN      (
    SELECT * FROM epistemics.edges
) e USING (filing, seq)
JOIN      (
    SELECT * FROM scope.corpus
) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2
