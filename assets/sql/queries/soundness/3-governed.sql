-- §3  Which relations a law governs, the roster, as the example reads it.
-- algebra/roster.sqlc, projected to what the tree-walk needs.
SELECT r.governs      AS "governs!",
       r.form         AS "form!",
       r.multiplicity AS "multiplicity!"
FROM (
    SELECT * FROM algebra.roster
) r
WHERE r.form NOT IN ('value', 'conformance')
ORDER BY r.governs
