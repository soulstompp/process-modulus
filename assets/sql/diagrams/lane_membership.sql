-- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
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
    SELECT * FROM entries.draws
) d

) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM diagrams.foreign_calls
) c
