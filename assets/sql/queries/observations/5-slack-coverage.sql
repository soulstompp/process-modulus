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
       count(*) FILTER (WHERE s.sized AND s.high = 0)          AS sized_at_zero,
       count(*) FILTER (WHERE s.absent IS NOT NULL)            AS absent,
       count(*) FILTER (WHERE s.absent = 'unmeasured')         AS nobody_measured,
       count(*) FILTER (WHERE s.absent = 'notApplicable')      AS not_applicable,
       count(*) FILTER (WHERE s.derivation IS NOT NULL)        AS derived,
       count(*)                                                AS rows
FROM      (
    SELECT * FROM entries.slacks
) s
JOIN      (
    SELECT * FROM scope.every_filing
) f USING (filing)
GROUP BY s.buffer, f.evidence
ORDER BY s.buffer, f.evidence

) c
ORDER BY c.buffer, c.evidence
