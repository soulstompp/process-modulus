-- composition/carried.sqlc: the part's figure against the composed layer's, per quantity.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT c.filing, c.layer,
           abs(c.part_low  - c.filed_low)  > 1e-9
        OR abs(c.part_mode - c.filed_mode) > 1e-9
        OR abs(c.part_high - c.filed_high) > 1e-9                    AS violates,
           format('%s carried as [%s, %s, %s] against a part of [%s, %s, %s]',
                  c.quantity, c.filed_low, c.filed_mode, c.filed_high,
                  c.part_low, c.part_mode, c.part_high)              AS detail
    FROM (
        SELECT * FROM composition.carried
    ) c
) p ON true
WHERE r.slug = 'one_part_fusion_alters_its_part'
