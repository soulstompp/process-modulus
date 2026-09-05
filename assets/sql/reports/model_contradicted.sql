--
-- pm:StatedRemainder's absent branch, over the corpus.
SELECT d.filing, d.layer, d.reason,
       regexp_replace(d.argument, '\s+', ' ', 'g') AS the_counter_example,
       format('%s of %s corpus layers deny having one',
              count(*) OVER (),
              (SELECT count(*) FROM pm.layer l
                JOIN (
                    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

                ) sc USING (filing))) AS how_common
FROM (
    -- pm:Layer/pm:remainder taking the pm:absent branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.remainder_absent      AS reason,
       l.remainder_absent_note AS argument
FROM pm.layer l
WHERE l.remainder_absent IS NOT NULL

) d
JOIN (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) s USING (filing)
ORDER BY d.filing, d.layer
