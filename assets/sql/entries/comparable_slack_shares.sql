-- pm:Buffer and pm:Holder claims, each carrying its own unit.
SELECT s.filing, s.layer, s.buffer, h.kind,
       s.unit AS slack_unit, h.share_unit
FROM      (
    -- pm:Layer/pm:Buffers; one element per pm:BufferKind.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
JOIN      (
    -- pm:Remainder/pm:Holders; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL
