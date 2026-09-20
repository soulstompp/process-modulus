-- pm:Claim/pm:boundOrigin, wherever a claim appears.
SELECT b.filing, b.seq, b.owns, b.origin, b.origin_absent AS absent,
       CASE
         WHEN b.origin IS NOT NULL   THEN 'somebody owns it: ' || b.origin::text
         WHEN b.origin_derivation IN ('amountOrigin', 'quantumOrigin')
              THEN format('stated in a sibling element (`%s`)', b.origin_derivation)
         WHEN b.origin_derivation IS NOT NULL
              THEN format('the edge of the terms `%s` computes the claim from', b.origin_derivation)
         WHEN b.origin_absent = 'none'      THEN 'NOTHING sets it -- the range is where the measurements fell'
         WHEN b.origin_absent = 'unmeasured' THEN 'nobody has asked'
         ELSE 'not a bound on a committed quantity'
       END AS who_owns_the_edge,
       b.origin_derivation AS derivation
FROM (
    SELECT * FROM epistemics.claims
) b
