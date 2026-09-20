-- §7  Which buffers the corpus actually sizes, and the one that reads zero.
-- entries/slacks.sqlc at corpus scope.
SELECT s.filing            AS "filing!",
       s.layer             AS "layer!",
       s.buffer::text      AS "buffer!",
       s.sized             AS "sized!",
       s.absent::text      AS "absent"
FROM (
    SELECT * FROM entries.slacks
) s
JOIN (
    SELECT * FROM scope.corpus
) f USING (filing)
ORDER BY s.filing, s.layer, s.buffer
