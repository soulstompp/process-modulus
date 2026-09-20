-- pm:Nameplate/amount against pm:LumpyQuantum/size.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT d.filing, d.layer,
           abs(d.n_low  - d.quantum_mode * round(d.n_low  / d.quantum_mode)) > 1e-9
           OR abs(d.n_mode - d.quantum_mode * round(d.n_mode / d.quantum_mode)) > 1e-9
           OR abs(d.n_high - d.quantum_mode * round(d.n_high / d.quantum_mode)) > 1e-9 AS violates,
           format('a quantum of %s against a nameplate of [%s, %s, %s]',
                  d.quantum_mode, d.n_low, d.n_mode, d.n_high) AS detail
    FROM (
        -- pm:LumpyQuantum/size, strictly positive.
SELECT l.*
FROM (
    SELECT * FROM layers.lumpy
) l
WHERE l.quantum_mode > 0

    ) d
) p ON true
WHERE r.slug = 'nameplate_not_a_multiple'
