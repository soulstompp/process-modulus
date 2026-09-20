-- §1  The remainder and its fit, read off the ranges rather than off a point.
-- layers/signed.sqlc, with the evidence axis from pm.filing.
SELECT s.filing              AS "filing!",
       s.layer               AS "layer!",
       s.d_low::float8       AS "d_low!",
       s.d_mode::float8      AS "d_mode!",
       s.d_high::float8      AS "d_high!",
       s.n_low::float8       AS "n_low!",
       s.n_mode::float8      AS "n_mode!",
       s.n_high::float8      AS "n_high!",
       s.sign::text          AS "sign!",
       f.evidence            AS "evidence!",
       (u.filing IS NULL)    AS "differenceable!"
FROM (
    SELECT * FROM layers.signed
) s
JOIN (
    SELECT * FROM scope.every_filing
) f USING (filing)
LEFT JOIN (
    SELECT * FROM composition.unsettled
) u ON u.filing = s.filing AND u.layer = s.layer
ORDER BY s.filing, s.layer
