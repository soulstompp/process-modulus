-- pm:Claim/pm:narrowsWhen kinds, over the corpus.
SELECT w.what_the_width_is_made_of, count(*) AS claims
FROM (
    -- pm:Claim/pm:narrowsWhen, wherever a claim appears.
SELECT n.filing, n.seq, n.owns, n.is_a_point, n.low, n.high, n.unit,
       n.narrows_kind AS kind, n.narrows_absent AS absent, n.narrows_condition AS condition,
       CASE
         WHEN n.narrows_kind = 'instrument'      THEN 'ignorance: measure it better'
         WHEN n.narrows_kind = 'intervention'    THEN 'VARIATION: only changing the process helps'
         WHEN n.narrows_kind = 'experiment'      THEN 'unknown, deliberately: an experiment would say'
         WHEN n.narrows_absent = 'none'          THEN 'VARIATION: somebody looked, nothing would narrow it'
         WHEN n.narrows_absent = 'notApplicable' THEN 'no range to narrow (a point value)'
         ELSE 'nobody has said'
       END AS what_the_width_is_made_of
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

) n

) w
JOIN (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) s USING (filing)
GROUP BY 1 ORDER BY 2 DESC
