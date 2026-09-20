-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       CASE WHEN e.derivation IS NOT NULL
            THEN format('the elimination is filed as `%s`, and no computation of it is wired into '
                        'the sum', e.derivation)
            ELSE 'the overlap was found and could not be sized' END AS suspended_because,
       e.reason AS note
FROM (
    SELECT * FROM eliminations.filed
) e
WHERE e.absent IS NOT NULL OR e.derivation IS NOT NULL
