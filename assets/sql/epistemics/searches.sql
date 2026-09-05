-- pm:Stack/pm:Couplings and pm:Fusion/pm:Eliminations, each with its pm:Absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.absent AS answer, cs.note
FROM pm.coupling_search cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.absent, es.note
FROM pm.elimination_search es
