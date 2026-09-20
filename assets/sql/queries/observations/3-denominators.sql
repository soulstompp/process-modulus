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
    SELECT * FROM epistemics.claims
) c
WHERE c.denominator IS NOT NULL
GROUP BY 1, 2

) d
ORDER BY d.kind, d.claims DESC
