-- eliminations/paired.sqlc against epistemics/claims.sqlc at the claim the eliminated quantity is.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit, e.absent, e.reason,
       e.high - e.low AS width,
       e.crossed,
       e.claim_seq,
       c.low  AS claim_low,
       c.mode AS claim_mode,
       c.high AS claim_high,
       c.unit AS claim_unit,
       c.origin, c.origin_absent, c.origin_derivation,
       CASE WHEN e.low IS NULL OR e.high - e.low = 0 THEN NULL ELSE e.crossed END AS isotone,
       CASE WHEN e.low IS NULL THEN NULL
            ELSE c.origin_derivation IS NOT DISTINCT FROM 'sharedParts' END AS licensed,
       CASE WHEN e.low IS NULL      THEN 'no figure, so nothing to read'
            WHEN e.high - e.low = 0 THEN 'a point: both pairings are one arithmetic'
            WHEN e.crossed          THEN 'ISOTONE: a wider elimination widens the composed figure'
            ELSE 'ANTI-ISOTONE: a wider elimination NARROWS the composed figure'
       END AS what_a_wider_elimination_does,
       CASE WHEN e.low IS NULL THEN 'no claim to carry an origin'
            WHEN c.origin_derivation IS NOT DISTINCT FROM 'sharedParts'
                 THEN 'the filer says it is a copy of the part it removes'
            WHEN c.origin_absent IS NOT NULL THEN 'the filer says nothing sets this bound'
            WHEN c.origin IS NOT NULL        THEN 'the filer names who may change this bound'
            ELSE 'nobody said'
       END AS what_the_bound_rests_on
FROM      (
    SELECT * FROM eliminations.paired
) e
LEFT JOIN (
    SELECT * FROM epistemics.claims
) c ON c.filing = e.composition AND c.seq = e.claim_seq
