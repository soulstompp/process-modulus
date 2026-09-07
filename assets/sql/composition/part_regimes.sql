-- pm.part's regime handle resolved into pm.composition_regime, against the part filing's own pm.regime.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_taxonomy IS NOT NULL AND EXISTS (
            SELECT 1 FROM pm.regime r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*) FROM pm.regime r WHERE r.filing = p.part_filing
          AND r.framework_taxonomy IS NOT NULL)                          AS frameworks_the_filing_states
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- pm:Composition/pm:Fusion/pm:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN pm.composition_regime cr
  ON cr.composition = p.composition AND cr.id = p.part_regime
