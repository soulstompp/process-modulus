-- §10b Every `between` as a reference to another document, beside whether it lands on a layer here.
-- eliminations/references.sqlc against eliminations/resolved.sqlc, the whole beside the half.
WITH eliminations_between AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b
),
eliminations_references AS (
-- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
eliminations_resolved AS (
-- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer
)
SELECT a.composition                        AS "composition!",
       a.composed_layer                     AS "composed_layer!",
       a.quantity::text                     AS "quantity!",
       a.party                              AS "party!",
       a.layer                              AS "layer!",
       coalesce(r.resolved_filing, '(outside this corpus)') AS "lands_on!",
       (r.resolved_filing IS NOT NULL)      AS "resolves!"
FROM      (
    SELECT * FROM eliminations_references
) a
LEFT JOIN (
    SELECT * FROM eliminations_resolved
) r USING (composition, composed_layer, quantity, seq)
ORDER BY (r.resolved_filing IS NOT NULL), 1, 2, 3, a.seq
