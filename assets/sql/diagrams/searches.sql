-- pm:Stack/pm:couplings/pm:absent; carried as the laneSet's own documentation.
WITH
coupling_searches AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

)
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    SELECT * FROM coupling_searches
) s
