-- pm:Claim/pm:boundOrigin, wherever a claim appears.
SELECT b.filing, b.seq, b.owns, b.origin, b.origin_absent AS absent,
       CASE
         WHEN b.origin IS NOT NULL   THEN 'somebody owns it: ' || b.origin::text
         WHEN b.origin_absent = 'derived'   THEN 'stated in a sibling element (amountOrigin, quantum origin)'
         WHEN b.origin_absent = 'none'      THEN 'NOTHING sets it -- the range is where the measurements fell'
         WHEN b.origin_absent = 'unmeasured' THEN 'nobody has asked'
         ELSE 'not a bound on a committed quantity'
       END AS who_owns_the_edge
FROM (
    -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns,
       c.low, c.mode, c.high, c.unit,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)

) b
