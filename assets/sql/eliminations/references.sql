-- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
WITH eliminations_between AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b
)
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b
