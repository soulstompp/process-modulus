-- pm:Claim where low <> high, at every element that carries one.
SELECT c.*
FROM (
    SELECT * FROM epistemics.claims
) c
WHERE NOT c.is_a_point
