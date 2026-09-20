-- pm:Remainder/sign = clearance against pm:HolderKind customer/unrealised.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT r.filing, r.layer,
           u.kind IS NOT NULL AS violates,
           format('%s holder under a clearance fit', h.kind) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM entries.holders
    ) h USING (filing, layer)
    LEFT JOIN (
        SELECT * FROM entries.unserved_holders
    ) u USING (filing, layer, kind)
    WHERE r.sign = 'clearance'
) p ON true
WHERE r.slug = 'clearance_with_unserved'
