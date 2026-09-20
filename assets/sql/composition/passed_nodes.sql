-- composition/remainder_frontier.sqlc restricted to the nodes composition/unsettled.sqlc names.
SELECT w.*
FROM      (
    SELECT * FROM composition.remainder_frontier
) w
JOIN      (
    SELECT * FROM composition.unsettled
) u ON u.filing = w.filing AND u.layer = w.layer
