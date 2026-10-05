-- entries/absorbing_slack.sqlc against pm:Remainder/pm:holder, each carrying its own unit.
WITH layers_absorber AS (
-- pm:Remainder/absorber, resolved through pm.buffer_term.
SELECT l.filing, l.layer,
       l.absorber_taxonomy AS taxonomy,
       l.absorber_value    AS term,
       bt.buffer,
       bt.note AS the_readers_warrant
FROM pm.layer l
JOIN pm.buffer_term bt ON bt.taxonomy = l.absorber_taxonomy AND bt.value = l.absorber_value
),
entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
),
entries_absorbing_slack AS (
-- layers/absorber.sqlc joined to entries/slacks.sqlc on the buffer the layer actually names.
SELECT a.filing, a.layer, a.buffer,
       a.taxonomy, a.term, a.the_readers_warrant,
       s.low, s.mode, s.high, s.unit, s.absent, s.sized
FROM      (
    SELECT * FROM layers_absorber
) a
JOIN      (
    SELECT * FROM entries_slacks
) s USING (filing, layer, buffer)
),
entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
)
SELECT s.filing, s.layer, s.buffer, h.kind,
       s.unit AS slack_unit, h.share_unit
FROM      (
    SELECT * FROM entries_absorbing_slack
) s
JOIN      (
    SELECT * FROM entries_holders
) h USING (filing, layer)
WHERE s.unit IS NOT NULL AND h.share_unit IS NOT NULL
