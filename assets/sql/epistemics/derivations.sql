-- every pm:derivation/identity in the schema, from every column that keeps one.
SELECT filing, subject, owns, coalesce(element, owns) AS element, identity FROM (
    SELECT filing, layer AS subject, 'pm:demand/pm:amount' AS owns, NULL::text AS element,
           derivation AS identity FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'pm:nameplate/pm:amount', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'pm:jagged/pm:draw', NULL, derivation FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:sign', NULL, sign_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer || ' / ' || buffer::text,
                     CASE s.buffer WHEN 'time'     THEN 'pm:layer/pm:timeSlack'
                                   WHEN 'capacity' THEN 'pm:nameplate/pm:capacitySlack'
                                   ELSE 'pm:nameplate/pm:inventorySlack' END,
                     NULL, derivation FROM (
        SELECT * FROM entries.slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text, 'pm:holder/pm:share', NULL, share_derivation FROM (
        SELECT * FROM entries.holders
    ) h
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, owns, element, identity FROM (
        SELECT * FROM epistemics.claim_derivations
    ) c
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'asrt:elimination/asrt:quantity', NULL, derivation FROM (
        SELECT * FROM eliminations.filed
    ) e
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'asrt:part/asrt:factor', NULL, factor_derivation FROM (
        SELECT * FROM composition.part_references
    ) pr
) d
WHERE identity IS NOT NULL
