-- composition/unsettled.sqlc within composition/suspended_remainders.sqlc.
SELECT o.filing, o.layer
FROM      (
    SELECT * FROM composition.unsettled
) o
JOIN      (
    SELECT * FROM composition.suspended_remainders
) l ON l.composition = o.filing AND l.composed_layer = o.layer
