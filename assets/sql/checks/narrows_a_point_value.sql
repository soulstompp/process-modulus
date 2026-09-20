-- pm:Claim/pm:narrowsWhen on any pm:Claim where low = high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.narrows_absent IS DISTINCT FROM 'notApplicable' AS violates,
           format('%s claim %s: %s exactly, and it still answers %s', c.owns, c.seq, c.mode,
                  coalesce(c.narrows_kind::text, 'absent: ' || c.narrows_absent)) AS detail
    FROM (
        SELECT * FROM epistemics.point_claims
    ) c
) p ON true
WHERE r.slug = 'narrows_a_point_value'
