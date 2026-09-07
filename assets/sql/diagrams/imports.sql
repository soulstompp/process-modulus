-- composition/notations.sqlc projected to the resolution alone; one import per notation.
SELECT n.notation, n.filing
FROM (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) n
