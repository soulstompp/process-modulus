-- entries/absorbing_slack.sqlc against pm:Remainder/pm:holder, each carrying its own unit.
SELECT s.filing, s.layer, s.buffer, h.kind,
       s.unit AS slack_unit, h.share_unit
FROM      (
    -- layers/absorber.sqlc joined to entries/slacks.sqlc on the buffer the layer actually names.
SELECT a.filing, a.layer, a.buffer,
       a.taxonomy, a.term, a.the_readers_warrant,
       s.low, s.mode, s.high, s.unit, s.absent, s.sized,
       s.bound_origin, s.bound_origin_absent
FROM      (
    -- pm:Remainder/absorber, resolved through pm.buffer_term.
SELECT l.filing, l.layer,
       l.absorber_taxonomy AS taxonomy,
       l.absorber_value    AS term,
       bt.buffer,
       bt.note AS the_readers_warrant
FROM pm.layer l
JOIN pm.buffer_term bt ON bt.taxonomy = l.absorber_taxonomy AND bt.value = l.absorber_value

) a
JOIN      (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s USING (filing, layer, buffer)

) s
JOIN      (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL
