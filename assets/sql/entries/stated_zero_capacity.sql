-- pm:Nameplate/pm:capacitySlack, zero either way.
SELECT z.filing, z.layer, z.high AS zero
FROM (
    -- a slack element with a stated pm:Claim whose bounds are zero.
SELECT s.*
FROM (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
WHERE s.high IS NOT NULL AND s.high = 0

) z
WHERE z.buffer = 'capacity'
