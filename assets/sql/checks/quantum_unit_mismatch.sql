-- pm:LumpyQuantum/size unit against pm:Nameplate/amount unit.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT l.filing, l.layer,
           l.quantum_unit IS DISTINCT FROM l.amount_unit AS violates,
           format('quantum in %s, nameplate in %s', l.quantum_unit, l.amount_unit) AS detail
    FROM (
        SELECT * FROM layers.lumpy
    ) l
    WHERE l.quantum_low IS NOT NULL
) p ON true
WHERE r.slug = 'quantum_unit_mismatch'
