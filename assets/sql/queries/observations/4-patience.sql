-- §4  How long each layer's demand survives being unanswered.
-- layers/patience.sqlc, beside the demand each patience qualifies.
SELECT p.filing                            AS "filing!",
       p.layer                             AS "layer!",
       coalesce(p.patience_absent::text, 'filed') AS "state!",
       p.patience_mode::float8             AS "mode",
       coalesce(p.patience_unit, '')       AS "unit!",
       coalesce(p.demand_unit, '')         AS "demand_unit!"
FROM (
    -- pm:Demand/pm:patience, beside the demand it qualifies.
SELECT l.filing, l.layer,
       l.patience_low, l.patience_mode, l.patience_high, l.patience_unit,
       l.patience_origin, l.patience_absent,
       l.demand_unit
FROM pm.layer l

) p
ORDER BY p.patience_absent NULLS FIRST, p.filing, p.layer
