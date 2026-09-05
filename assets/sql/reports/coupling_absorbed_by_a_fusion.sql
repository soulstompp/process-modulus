-- pm:Coupling against pm:Fusion/pm:Part pairs that contain both of its ends, over the corpus.
SELECT c.filing,
       c.from_layer || ' -> ' || c.to_layer AS coupling,
       CASE WHEN a.composition IS NULL THEN '(no fusion holds both ends)'
            ELSE a.composition || '/' || a.composed_layer END AS absorbed_into,
       left(regexp_replace(c.observation, '\s+', ' ', 'g'), 56) || '...' AS what_was_observed
FROM (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observation.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
LEFT JOIN (
    SELECT DISTINCT x.part_filing AS filing, x.part_layer AS from_layer,
           y.part_layer AS to_layer, x.composition, x.composed_layer
    FROM (
        -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
JOIN pm.filing_identity fi ON fi.notation = p.part_filing
JOIN pm.layer l ON l.filing = fi.filing AND l.layer = p.part_layer

    ) x
    JOIN (
        -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       p.factor_low, p.factor_mode, p.factor_high
FROM pm.part p

) p
JOIN pm.filing_identity fi ON fi.notation = p.part_filing
JOIN pm.layer l ON l.filing = fi.filing AND l.layer = p.part_layer

    ) y
      ON y.composition = x.composition AND y.composed_layer = x.composed_layer
     AND y.part_filing = x.part_filing
) a USING (filing, from_layer, to_layer)
JOIN      (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) sc USING (filing)
ORDER BY 1, 2
