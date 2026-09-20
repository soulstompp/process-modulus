-- epistemics/absences.sqlc folded to one three-bit word per question.
SELECT a.question,
       (CASE WHEN bool_or(a.reason = 'none')          THEN 'n' ELSE '.' END) ||
       (CASE WHEN bool_or(a.reason = 'unmeasured')    THEN 'u' ELSE '.' END) ||
       (CASE WHEN bool_or(a.reason = 'notApplicable') THEN 'a' ELSE '.' END) AS mask,
       count(*)                                                             AS filings,
       count(*) FILTER (WHERE a.reason = 'none')                            AS as_none
FROM (
    SELECT * FROM epistemics.absences
) a
WHERE a.reason IS NOT NULL
GROUP BY a.question
