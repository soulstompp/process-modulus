-- pm:StatedRemainder's absent branch, over the corpus.
WITH layers_every_layer AS (
-- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l
),
scope_corpus AS (
-- from pm.filing where evidence = 'observation' and the kind attests to a world.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'observation'
  AND f.kind IN ('processModulus', 'composition', 'dependence')
),
layers_denied_remainders AS (
-- pm:Layer/pm:remainder taking the pm:absent branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.remainder_absent      AS reason,
       l.remainder_absent_note AS argument
FROM pm.layer l
WHERE l.remainder_absent IS NOT NULL
)
SELECT d.filing, d.layer, d.reason,
       regexp_replace(d.argument, '\s+', ' ', 'g') AS the_counter_example,
       format('%s of %s corpus layers deny having one',
              count(*) OVER (),
              (SELECT count(*) FROM (
                    SELECT * FROM layers_every_layer
                ) l
                JOIN (
                    SELECT * FROM scope_corpus
                ) sc USING (filing))) AS how_common
FROM (
    SELECT * FROM layers_denied_remainders
) d
JOIN (
    SELECT * FROM scope_corpus
) s USING (filing)
ORDER BY d.filing, d.layer
