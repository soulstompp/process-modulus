-- pm:Remainder/sign in {interference, transition}.
SELECT r.*
FROM (
    SELECT * FROM layers.remainder
) r
WHERE r.sign IN ('interference', 'transition')
