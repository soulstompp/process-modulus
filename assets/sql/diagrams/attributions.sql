-- eliminations/resolved.sqlc projected to the two ends of the relationship.
WITH
notations AS NOT MATERIALIZED (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

),
eliminations_between AS NOT MATERIALIZED (
    -- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b

),
eliminations_references AS NOT MATERIALIZED (
    -- asrt:Elimination/asrt:between, typed asrt:FiledLayer, whose filing is a pm:ForeignId.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.regime
FROM (
    SELECT * FROM eliminations_between
) b

),
resolved AS NOT MATERIALIZED (
    -- eliminations/references.sqlc joined through pm.filing_identity to pm.layer.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, fi.filing AS resolved_filing, b.layer, b.regime
FROM      (
    SELECT * FROM eliminations_references
) b
JOIN      (
    SELECT * FROM notations
) fi ON fi.notation = b.notation
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = b.layer

)
SELECT b.composition, b.composed_layer, b.notation, b.resolved_filing, b.layer
FROM (
    SELECT * FROM resolved
) b
