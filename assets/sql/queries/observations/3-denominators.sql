-- §3  Every denominator the corpus leans on, and what it sits under.
-- units/denominators.sqlc, the census over every claim carrying one.
SELECT d.kind          AS "kind!",
       d.denominator   AS "denominator!",
       d.claims        AS "claims!",
       d.filed_on      AS "filed_on!"
FROM (
    -- pm:Claim/pm:denominator, across every position that files one.
SELECT c.denominator_kind AS kind,
       c.denominator,
       count(*)               AS claims,
       count(DISTINCT c.owns) AS positions,
       string_agg(DISTINCT c.owns, ', ' ORDER BY c.owns) AS filed_on
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
WHERE c.denominator IS NOT NULL
GROUP BY 1, 2

) d
ORDER BY d.kind, d.claims DESC
