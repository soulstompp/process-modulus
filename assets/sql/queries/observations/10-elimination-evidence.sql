-- §10  What each filed elimination says it is between, which is the evidence for the number.
-- eliminations/filed.sqlc with eliminations/between.sqlc folded per elimination.
WITH eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
eliminations_between AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination/asrt:between, one row each.
SELECT b.composition, b.composed_layer, b.quantity, b.seq,
       b.party, b.notation, b.layer, b.version, b.regime,
       b.registration_taxonomy, b.registration_value
FROM pm.elimination_between b
)
SELECT e.composition                              AS "composition!",
       e.composed_layer                           AS "composed_layer!",
       e.quantity::text                           AS "quantity!",
       -- Three arms: `pm:StatedEliminatedQuantity` admits a figure, a typed absence or a
       -- derivation, and the column is declared NOT NULL, so all three are read.
       -- `every-derived-elimination` files the third.
       coalesce(e.mode::text,
                '(' || e.absent || ')',
                '(computed: ' || e.derivation || ')')  AS "size!",
       count(b.seq)                               AS "named!",
       coalesce(string_agg(b.party || '/' || b.layer, ', ' ORDER BY b.seq), '(none named)')
                                                  AS "between!"
FROM (
    SELECT * FROM eliminations_filed
) e
LEFT JOIN (
    SELECT * FROM eliminations_between
) b USING (composition, composed_layer, quantity)
GROUP BY e.composition, e.composed_layer, e.quantity, e.mode, e.absent, e.derivation
ORDER BY count(b.seq) DESC, 1, 2, 3
