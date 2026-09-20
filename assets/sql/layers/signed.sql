-- pm:Remainder/sign, stated rather than absent.
SELECT r.*
FROM (
    SELECT * FROM layers.remainder
) r
WHERE r.sign IS NOT NULL
