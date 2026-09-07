-- pg_constraint, for the foreign keys into pm.layer; the grain the lane mapping rests on.
SELECT c.conrelid::regclass::text                       AS referrer,
       pg_get_constraintdef(c.oid)                      AS reference,
       cardinality(c.confkey) = 2                       AS whole
FROM pg_constraint c
WHERE c.contype = 'f' AND c.confrelid = 'pm.layer'::regclass
