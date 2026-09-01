-- §2  The operations that both draw and induce — the entries `D-transpose N` would have.
--
-- An operation consumes from one layer and commits on another, so an operation appearing
-- in both tables is a cross-layer edge. This is the incidence half of `DᵀN`.
--
-- ⭐ THE RESULT IS THE FINDING. In this corpus exactly one operation qualifies and its
-- draw is UNMEASURED, so the product cannot be computed at all. The matrix that would show
-- cross-layer structure is empty precisely because the interesting quantity has no
-- instrument, which is what the model exists to say. `d_val` NULL is that.
SELECT d.operation      AS "operation!",
       d.layer          AS "drawn!",
       d.mode::float8   AS d_val,
       n.layer          AS "commits!",
       n.mode::float8   AS n_val
FROM pm.draw d
JOIN pm.induction n
  ON n.filing = d.filing
 AND n.operation = d.operation
