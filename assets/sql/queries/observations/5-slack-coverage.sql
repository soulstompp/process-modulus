-- §5  Which buffers the corpus sizes, and which of them read zero.
-- reports/slack_census.sqlc over every filing, projected for the example.
WITH entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
),
scope_every_filing AS (
-- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f
)
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
       count(*) FILTER (WHERE s.sized AND s.high = 0)          AS sized_at_zero,
       count(*) FILTER (WHERE s.absent IS NOT NULL)            AS absent,
       count(*) FILTER (WHERE s.absent = 'unmeasured')         AS nobody_measured,
       count(*) FILTER (WHERE s.absent = 'notApplicable')      AS not_applicable,
       count(*) FILTER (WHERE s.derivation IS NOT NULL)        AS derived,
       count(*)                                                AS rows
FROM      (
    SELECT * FROM entries_slacks
) s
JOIN      (
    SELECT * FROM scope_every_filing
) f USING (filing)
GROUP BY s.buffer, f.evidence
ORDER BY s.buffer, f.evidence

) c
ORDER BY c.buffer, c.evidence
