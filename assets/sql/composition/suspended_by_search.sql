-- pm:Fusion/pm:Eliminations with pm:Absent reason="unmeasured".
SELECT es.composition, es.composed_layer,
       'the search was never made' AS suspended_because,
       es.note
FROM pm.elimination_search es
WHERE es.absent = 'unmeasured'
