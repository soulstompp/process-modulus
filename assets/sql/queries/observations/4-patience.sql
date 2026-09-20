-- §4  How long each layer's demand survives being unanswered.
-- layers/patience.sqlc, beside the demand each patience qualifies.
SELECT p.filing                            AS "filing!",
       p.layer                             AS "layer!",
       coalesce(p.patience_absent::text, 'filed') AS "state!",
       p.patience_mode::float8             AS "mode",
       coalesce(p.patience_unit, '')       AS "unit!",
       coalesce(p.demand_unit, '')         AS "demand_unit!"
FROM (
    SELECT * FROM layers.patience
) p
ORDER BY p.patience_absent NULLS FIRST, p.filing, p.layer
