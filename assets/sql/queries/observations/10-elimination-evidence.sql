-- §10  What each filed elimination says it is BETWEEN, which is the evidence for the number.
-- eliminations/filed.sqlc with eliminations/between.sqlc folded per elimination.
SELECT e.composition                              AS "composition!",
       e.composed_layer                           AS "composed_layer!",
       e.quantity                                 AS "quantity!",
       coalesce(e.mode::text, '(' || e.absent || ')') AS "size!",
       count(b.seq)                               AS "named!",
       coalesce(string_agg(b.party || '/' || b.layer, ', ' ORDER BY b.seq), '(none named)')
                                                  AS "between!"
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

) e
LEFT JOIN (
    -- asrt:Fusion/asrt:Eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime
FROM pm.elimination_between b

) b USING (composition, composed_layer, quantity)
GROUP BY e.composition, e.composed_layer, e.quantity, e.mode, e.absent
ORDER BY count(b.seq) DESC, 1, 2, 3
