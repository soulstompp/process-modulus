-- §7b  How many remainders the arithmetic can reach at all, which is §7's denominator.
-- layers/remainder.sqlc, counted.
SELECT count(*) AS "computable!"
FROM (
    SELECT * FROM layers.remainder
) r
