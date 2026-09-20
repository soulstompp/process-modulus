-- composition/notations.sqlc projected to the resolution alone; one import per notation.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

)
SELECT n.notation, n.filing
FROM (
    SELECT * FROM notations
) n
