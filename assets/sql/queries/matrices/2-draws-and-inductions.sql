-- §2  The operations that both draw and induce, the entries `D-transpose N` would have.
-- entries/cross_layer_edges.sqlc, the join on the shared (filing, operation) index.
SELECT x.operation        AS "operation!",
       x.drawn_from       AS "drawn!",
       x.drawn::float8    AS d_val,
       x.commits          AS "commits!",
       x.committed::float8 AS n_val
FROM (
    -- the shared index is (filing, operation); pm:Operation carries both children.
SELECT d.filing, d.operation,
       d.layer AS drawn_from, d.mode AS drawn,
       n.layer AS commits,    n.mode AS committed,
       coalesce(d.unit, '(unmeasured)') || ' * '
    || coalesce(n.unit, '(unmeasured)') AS the_unit_that_warns_you,
       d.mode * n.mode                    AS the_product_nobody_should_use
FROM      (
    -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

) d
JOIN      (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

) n USING (filing, operation)

) x
