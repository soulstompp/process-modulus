-- §7  Which buffers the corpus actually sizes, and the one that reads zero.
-- entries/slacks.sqlc at corpus scope.
SELECT s.filing            AS "filing!",
       s.layer             AS "layer!",
       s.buffer::text      AS "buffer!",
       s.sized             AS "sized!",
       s.absent::text      AS "absent"
FROM (
    -- pm:Layer/pm:Buffers; one element per pm:BufferKind.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
JOIN (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) f USING (filing)
ORDER BY s.filing, s.layer, s.buffer
