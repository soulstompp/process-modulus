-- layers/absorber.sqlc joined to entries/slacks.sqlc on the buffer the layer actually names.
SELECT a.filing, a.layer, a.buffer,
       a.taxonomy, a.term, a.the_readers_warrant,
       s.low, s.mode, s.high, s.unit, s.absent, s.sized
FROM      (
    SELECT * FROM layers.absorber
) a
JOIN      (
    SELECT * FROM entries.slacks
) s USING (filing, layer, buffer)
