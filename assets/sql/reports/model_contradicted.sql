-- pm:StatedRemainder's absent branch, over the corpus.
SELECT d.filing, d.layer, d.reason,
       regexp_replace(d.argument, '\s+', ' ', 'g') AS the_counter_example,
       format('%s of %s corpus layers deny having one',
              count(*) OVER (),
              (SELECT count(*) FROM (
                    SELECT * FROM layers.every_layer
                ) l
                JOIN (
                    SELECT * FROM scope.corpus
                ) sc USING (filing))) AS how_common
FROM (
    SELECT * FROM layers.denied_remainders
) d
JOIN (
    SELECT * FROM scope.corpus
) s USING (filing)
ORDER BY d.filing, d.layer
