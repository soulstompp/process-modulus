-- §4  The one layer where a conversion factor is correlated with itself.
-- layers/filed_against_derived.sqlc at the one layer with a spread conversion factor.
SELECT r.qty_low::float8      AS "q_low!",
       r.qty_mode::float8     AS "q_mode!",
       r.qty_high::float8     AS "q_high!",
       r.d_low::float8        AS "d_low!",
       r.d_mode::float8       AS "d_mode!",
       r.d_high::float8       AS "d_high!",
       r.n_low::float8        AS "n_low!",
       r.n_mode::float8       AS "n_mode!",
       r.n_high::float8       AS "n_high!"
FROM (
    SELECT * FROM layers.filed_against_derived
) r
WHERE r.filing = 'merge-holding-composition'
  AND r.layer  = 'compute'
