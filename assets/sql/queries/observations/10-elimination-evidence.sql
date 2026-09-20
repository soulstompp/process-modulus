-- §10  What each filed elimination says it is BETWEEN, which is the evidence for the number.
-- eliminations/filed.sqlc with eliminations/between.sqlc folded per elimination.
SELECT e.composition                              AS "composition!",
       e.composed_layer                           AS "composed_layer!",
       e.quantity::text                           AS "quantity!",
       -- ⛔ THREE ARMS, NOT TWO. `pm:StatedEliminatedQuantity` admits a figure, a typed absence AND
       -- a derivation, and reading only the first two returned NULL for the third against a column
       -- declared NOT NULL. No document could reach it until `every-derived-elimination` filed one,
       -- so the omission was invisible rather than harmless.
       coalesce(e.mode::text,
                '(' || e.absent || ')',
                '(computed: ' || e.derivation || ')')  AS "size!",
       count(b.seq)                               AS "named!",
       coalesce(string_agg(b.party || '/' || b.layer, ', ' ORDER BY b.seq), '(none named)')
                                                  AS "between!"
FROM (
    SELECT * FROM eliminations.filed
) e
LEFT JOIN (
    SELECT * FROM eliminations.between
) b USING (composition, composed_layer, quantity)
GROUP BY e.composition, e.composed_layer, e.quantity, e.mode, e.absent, e.derivation
ORDER BY count(b.seq) DESC, 1, 2, 3
