-- epistemics/claims.sqlc's narrowsWhen on each ranged demand of layers/ranged_demands.sqlc, over the corpus.
SELECT count(*)                                                   AS ranged_demands,
       count(*) FILTER (WHERE c.narrows_condition IS NULL)        AS say_nothing,
       round(100.0 * count(*) FILTER (WHERE c.narrows_condition IS NULL)
             / nullif(count(*), 0))                               AS pct
FROM (
    -- pm:Claim on pm:Demand where low <> high.
SELECT d.*
FROM (
    SELECT * FROM layers.demand
) d
WHERE NOT d.is_a_point

) r
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
JOIN (
    SELECT * FROM epistemics.claims
) c ON c.filing = r.filing AND c.layer = r.layer AND c.owns = 'pm:demand/pm:amount'
