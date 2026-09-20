-- pm:Coupling against asrt:Fusion/asrt:Part pairs that contain both of its ends, over the corpus.
SELECT c.filing,
       c.from_layer || ' -> ' || c.to_layer AS coupling,
       CASE WHEN a.composition IS NULL THEN '(no fusion holds both ends)'
            ELSE a.composition || '/' || a.composed_layer END AS absorbed_into,
       left(regexp_replace(c.observation, '\s+', ' ', 'g'), 56) || '...' AS what_was_observed
FROM (
    SELECT * FROM entries.couplings
) c
LEFT JOIN (
    SELECT DISTINCT sp.part_filing AS filing, sp.from_layer, sp.to_layer,
           sp.composition, sp.composed_layer
    FROM (
        SELECT * FROM composition.sibling_parts
    ) sp
) a USING (filing, from_layer, to_layer)
JOIN      (
    SELECT * FROM scope.corpus
) sc USING (filing)
ORDER BY 1, 2
