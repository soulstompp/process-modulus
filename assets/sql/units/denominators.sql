-- pm:Claim/pm:denominator, across every position that files one.
SELECT c.denominator_kind AS kind,
       c.denominator,
       count(*)               AS claims,
       count(DISTINCT c.owns) AS positions,
       string_agg(DISTINCT c.owns, ', ' ORDER BY c.owns) AS filed_on
FROM      (
    SELECT * FROM epistemics.claims
) c
WHERE c.denominator IS NOT NULL
GROUP BY 1, 2
