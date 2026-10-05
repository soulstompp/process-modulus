-- eliminations/filed.sqlc wherever asrt:quantity takes its pm:absent or pm:derivation branch, per quantity.
WITH eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
)
SELECT e.composition, e.composed_layer, e.quantity,
       CASE WHEN e.derivation IS NOT NULL
            THEN format('the elimination is filed as `%s`, and no computation of it is wired into '
                        'the sum', e.derivation)
            ELSE 'the overlap was found and could not be sized' END AS suspended_because,
       e.reason AS note
FROM (
    SELECT * FROM eliminations_filed
) e
WHERE e.absent IS NOT NULL OR e.derivation IS NOT NULL
