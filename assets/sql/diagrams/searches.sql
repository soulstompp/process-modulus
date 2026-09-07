-- pm:Stack/pm:Couplings/pm:Absent; carried as the laneSet's own documentation, because the
-- laneSet IS the partition the search is about.
SELECT s.filing,
       coalesce(s.answer::text, 'stated') AS answer
FROM (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s
