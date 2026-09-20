-- pm:Claim/pm:narrowsWhen, wherever a claim appears.
SELECT n.filing, n.seq, n.owns, n.is_a_point, n.low, n.high, n.unit,
       n.narrows_kind AS kind, n.narrows_absent AS absent, n.narrows_condition AS condition,
       CASE
         WHEN n.narrows_kind = 'instrument'      THEN 'ignorance: measure it better'
         WHEN n.narrows_kind = 'intervention'    THEN 'VARIATION: only changing the process helps'
         WHEN n.narrows_kind = 'experiment'      THEN 'unknown, deliberately: an experiment would say'
         WHEN n.narrows_absent = 'none'          THEN 'VARIATION: somebody looked, nothing would narrow it'
         WHEN n.narrows_absent = 'notApplicable' THEN 'no range to narrow (a point value)'
         WHEN n.narrows_derivation IS NOT NULL
              THEN format('computed: it narrows as the terms of `%s` do', n.narrows_derivation)
         ELSE 'nobody has said'
       END AS what_the_width_is_made_of,
       n.narrows_derivation AS derivation
FROM (
    SELECT * FROM epistemics.claims
) n
