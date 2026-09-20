-- §2  How often a claim says where it came from.
-- epistemics/standing.sqlc, folded to its three verdicts.
SELECT s.what_the_claim_says AS "says!", count(*) AS "claims!"
FROM (
    -- pm:Claim/pm:provenance, with pm:StatedBorrowedTerm at pm:standing.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.prov_party AS party,
       c.prov_standing_taxonomy AS taxonomy,
       c.prov_standing_value    AS standing,
       c.prov_standing_absent   AS standing_absent,
       CASE WHEN c.prov_standing_value  IS NOT NULL THEN 'claimed'
            WHEN c.prov_standing_absent IS NOT NULL THEN 'asked and refused'
            ELSE 'no provenance filed' END AS what_the_claim_says
FROM      (
    SELECT * FROM epistemics.claims
) c

) s
GROUP BY s.what_the_claim_says
ORDER BY count(*) DESC
