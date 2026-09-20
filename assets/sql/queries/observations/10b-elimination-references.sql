-- §10b Every `between` as a cross-document REFERENCE, beside whether it lands on a layer here.
-- eliminations/references.sqlc against eliminations/resolved.sqlc, the whole beside the half.
SELECT a.composition                        AS "composition!",
       a.composed_layer                     AS "composed_layer!",
       a.quantity::text                     AS "quantity!",
       a.party                              AS "party!",
       a.layer                              AS "layer!",
       coalesce(r.resolved_filing, '(outside this corpus)') AS "lands_on!",
       (r.resolved_filing IS NOT NULL)      AS "resolves!"
FROM      (
    SELECT * FROM eliminations.references
) a
LEFT JOIN (
    SELECT * FROM eliminations.resolved
) r USING (composition, composed_layer, quantity, seq)
ORDER BY (r.resolved_filing IS NOT NULL), 1, 2, 3, a.seq
