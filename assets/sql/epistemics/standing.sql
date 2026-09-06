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
    -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)

) c
