-- folds/contract_subjects.sqlc counted per contract: what each roster declares, and what answers it.
WITH v AS MATERIALIZED (
    SELECT * FROM folds.contract_subjects
)
SELECT v.contract,
       count(*) FILTER (WHERE v.declared)                    AS subjects,
       count(*) FILTER (WHERE v.declared AND v.answered > 0) AS witnessed
FROM v
GROUP BY v.contract
