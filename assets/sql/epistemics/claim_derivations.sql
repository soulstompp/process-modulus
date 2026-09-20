-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking their pm:derivation branch, at the claim's own position.
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:boundOrigin' AS element,
       c.origin_derivation AS identity
FROM (
    SELECT * FROM epistemics.claims
) c
WHERE c.origin_derivation IS NOT NULL
UNION ALL
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:narrowsWhen', c.narrows_derivation
FROM (
    SELECT * FROM epistemics.claims
) c
WHERE c.narrows_derivation IS NOT NULL
