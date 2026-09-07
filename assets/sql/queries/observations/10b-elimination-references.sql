-- §10b Every `between` as a cross-document REFERENCE, beside whether it lands on a layer here.
-- eliminations/references.sqlc against eliminations/resolved.sqlc, the whole beside the half.
SELECT a.composition                        AS "composition!",
       a.composed_layer                     AS "composed_layer!",
       a.quantity                           AS "quantity!",
       a.party                              AS "party!",
       a.layer                              AS "layer!",
       coalesce(r.resolved_filing, '(outside this corpus)') AS "lands_on!",
       (r.resolved_filing IS NOT NULL)      AS "resolves!"
FROM      (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime
FROM pm.elimination_between b

) b

) a
LEFT JOIN (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime
FROM pm.elimination_between b

) b

) b
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = b.notation
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = b.layer

) r USING (composition, composed_layer, quantity, seq)
ORDER BY (r.resolved_filing IS NOT NULL), 1, 2, 3, a.seq
