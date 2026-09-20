-- pm:Claim/pm:narrowsWhen with pm:absent/reason = notApplicable on any claim where low <> high.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           c.narrows_absent IS NOT DISTINCT FROM 'notApplicable' AS violates,
           format('%s claim %s: spans %s to %s %s, yet says there is no range to narrow',
                  c.owns, c.seq, c.low, c.high, c.unit) AS detail
    FROM (
        -- pm:Claim where low <> high, at every element that carries one.
SELECT c.*
FROM (
    SELECT * FROM epistemics.claims
) c
WHERE NOT c.is_a_point

    ) c
) p ON true
WHERE r.slug = 'range_says_no_range'
