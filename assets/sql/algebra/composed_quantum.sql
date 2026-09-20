-- composition/composed_quantum.sqlc against layers/nameplate.sqlc and eliminations/filed.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT c.composition || ' / ' || c.composed_layer AS subject,
           abs(n.n_mode - c.composed_quantum * round(n.n_mode / c.composed_quantum)) < 1e-9
           AND (e.mode IS NULL
                OR abs(e.mode - c.composed_quantum * round(e.mode / c.composed_quantum)) < 1e-9)
           AS holds,
           format('quantum %s %s%s against a nameplate of %s%s',
                  c.composed_quantum, c.unit,
                  CASE WHEN c.spread THEN ', read at a factor''s mode' ELSE '' END,
                  n.n_mode,
                  CASE WHEN e.mode IS NULL THEN ''
                       ELSE format(' and an elimination of %s', e.mode) END) AS detail
    FROM      (
        SELECT * FROM composition.composed_quantum
    ) c
    JOIN      (
        SELECT * FROM layers.nameplate
    ) n ON n.filing = c.composition AND n.layer = c.composed_layer
    LEFT JOIN (
        SELECT * FROM eliminations.filed
    ) e ON e.composition = c.composition AND e.composed_layer = c.composed_layer
       AND e.quantity = 'nameplate'
    WHERE c.composed_quantum IS NOT NULL
) p ON true
WHERE a.slug = 'composed_quantum'
