-- §2  Every computation this corpus declines to perform, and what stopped it.
-- arithmetic/all.sqlc restricted to the rows no site could compute.
SELECT z.site                    AS "site!",
       z.filing                  AS "filing!",
       z.layer                   AS "layer!",
       z.detail                  AS "detail!"
FROM (
    SELECT * FROM arithmetic.all
) z
WHERE z.verdict = 'suspended'
ORDER BY z.site, z.filing, z.layer
