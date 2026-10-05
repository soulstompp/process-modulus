-- the shared index is (filing, operation); pm:Operation carries both children.
WITH entries_draws AS (
-- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d
),
entries_inductions AS (
-- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n
)
SELECT d.filing, d.operation,
       d.layer AS drawn_from, d.mode AS drawn,
       n.layer AS commits,    n.mode AS committed,
       coalesce(d.unit, '(unmeasured)') || ' * '
    || coalesce(n.unit, '(unmeasured)') AS the_unit_that_warns_you,
       d.mode * n.mode                    AS the_product_nobody_should_use
FROM      (
    SELECT * FROM entries_draws
) d
JOIN      (
    SELECT * FROM entries_inductions
) n USING (filing, operation)
