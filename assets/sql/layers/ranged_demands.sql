-- pm:Claim on pm:Demand where low <> high.
SELECT d.*
FROM (
    SELECT * FROM layers.demand
) d
WHERE NOT d.is_a_point
