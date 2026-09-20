-- pm:Claim/pm:boundOrigin with pm:absent/reason = none on a claim where low = high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.origin_absent IS NOT DISTINCT FROM 'none' AS violates,
           format('%s claim %s: %s %s exactly, and nothing is said to set it',
                  c.owns, c.seq, c.mode, c.unit) AS detail
    FROM (
        SELECT * FROM epistemics.point_claims
    ) c
) p ON true
WHERE r.slug = 'bound_fell_with_no_range'
