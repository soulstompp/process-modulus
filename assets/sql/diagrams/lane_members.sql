-- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
WITH
draws AS NOT MATERIALIZED (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM draws
) d
