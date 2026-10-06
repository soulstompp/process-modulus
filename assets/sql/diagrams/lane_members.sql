-- entries/draws.sqlc reduced to which operation draws from which layer; one flowNodeRef per entry.
WITH entries_draws AS (
-- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d
)
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM entries_draws
) d
