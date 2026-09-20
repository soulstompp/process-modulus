-- the shared index is (filing, operation); pm:Operation carries both children.
SELECT d.filing, d.operation,
       d.layer AS drawn_from, d.mode AS drawn,
       n.layer AS commits,    n.mode AS committed,
       coalesce(d.unit, '(unmeasured)') || ' * '
    || coalesce(n.unit, '(unmeasured)') AS the_unit_that_warns_you,
       d.mode * n.mode                    AS the_product_nobody_should_use
FROM      (
    SELECT * FROM entries.draws
) d
JOIN      (
    SELECT * FROM entries.inductions
) n USING (filing, operation)
