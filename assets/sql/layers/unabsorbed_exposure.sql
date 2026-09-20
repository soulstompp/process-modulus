-- layers/exposure_scope.sqlc, restricted to the standing that licenses a conclusion.
SELECT s.*
FROM (
    SELECT * FROM layers.exposure_scope
) s
WHERE s.standing = 'every buffer sized and empty'
