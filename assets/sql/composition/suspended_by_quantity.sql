-- pm:Eliminations/pm:Elimination quantity="demand" with pm:Absent reason="unmeasured".
SELECT e.composition, e.composed_layer,
       'the overlap was found and could not be sized' AS suspended_because,
       e.reason AS note
FROM pm.elimination e
WHERE e.quantity = 'demand' AND e.absent = 'unmeasured'
