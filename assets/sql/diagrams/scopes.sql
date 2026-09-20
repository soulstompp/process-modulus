-- pm:Stack/pm:StatedScope; carried as the laneSet's own documentation beside the coupling search.
WITH
scopes AS NOT MATERIALIZED (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

)
SELECT s.filing, s.extent, s.basis
FROM (
    SELECT * FROM scopes
) s
