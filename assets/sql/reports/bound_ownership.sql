-- pm:Claim/pm:boundOrigin, over the corpus.
WITH epistemics_claims AS (
-- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.prov_entered_by, c.prov_approved_by, c.prov_note, c.as_of,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent,
       n.derivation   AS narrows_derivation,
       b.derivation   AS origin_derivation
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)
),
epistemics_edges AS (
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
    SELECT * FROM epistemics_claims
) b
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
)
SELECT e.who_owns_the_edge, count(*) AS claims
FROM (
    SELECT * FROM epistemics_edges
) e
JOIN (
    SELECT * FROM scope_corpus
) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
