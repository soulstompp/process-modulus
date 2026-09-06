-- §5  Which buffers the corpus sizes, and which of them read zero.
-- reports/slack_census.sqlc over every filing, projected for the example.
SELECT c.buffer         AS "buffer!",
       c.evidence       AS "evidence",
       c.sized          AS "sized!",
       c.sized_at_zero  AS "sized_at_zero!",
       c.absent         AS "absent!",
       c.rows           AS "rows!"
FROM (
    -- entries/slacks.sqlc by buffer, split by evidence, restricted by the caller's @scope.
SELECT s.buffer::text                                          AS buffer,
       f.evidence                                              AS evidence,
       count(*) FILTER (WHERE s.sized)                         AS sized,
       count(*) FILTER (WHERE s.sized AND s.mode = 0)          AS sized_at_zero,
       count(*) FILTER (WHERE NOT s.sized)                     AS absent,
       count(*) FILTER (WHERE s.absent = 'unmeasured')         AS nobody_measured,
       count(*) FILTER (WHERE s.absent = 'notApplicable')      AS not_applicable,
       count(*) FILTER (WHERE s.absent = 'derived')            AS derived,
       count(*)                                                AS rows
FROM      (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s
JOIN      (
    -- from pm.filing, both evidence values.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f

) f USING (filing)
GROUP BY s.buffer, f.evidence
ORDER BY s.buffer, f.evidence

) c
ORDER BY c.buffer, c.evidence
