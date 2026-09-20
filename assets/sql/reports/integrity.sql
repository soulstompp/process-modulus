-- folds/contract_subjects.sqlc crossed with the problems a contract can have, kept where one is found.
SELECT v.contract, p.problem, v.subject
FROM (
    SELECT * FROM folds.contract_subjects
) v
CROSS JOIN LATERAL (
    VALUES ('declared, but nothing produces it',      v.declared AND v.rows = 0),
           ('produced, but nothing declares it',      NOT v.declared),
           ('examined a row and returned no verdict', v.silent > 0)
) p(problem, found)
WHERE p.found
