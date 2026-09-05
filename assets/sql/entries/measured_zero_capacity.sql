-- pm:Buffers/pm:Buffer kind="capacity", zero either way.
SELECT z.filing, z.layer, z.absent AS spelled_as_absent, z.high AS spelled_as_claim
FROM (
    -- pm:Buffer with pm:Absent reason="none".
SELECT s.*
FROM (
    -- pm:Layer/pm:Buffers; one element per pm:BufferKind.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.absent = 'none'
UNION ALL
-- pm:Buffer with a stated pm:Claim whose bounds are zero.
SELECT s.*
FROM (
    -- pm:Layer/pm:Buffers; one element per pm:BufferKind.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.high IS NOT NULL AND s.high = 0

) z
WHERE z.buffer = 'capacity'
