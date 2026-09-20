-- pm:Stack/pm:couplings and asrt:Fusion/asrt:eliminations, each with its pm:absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.answer, cs.note
FROM (
    SELECT * FROM epistemics.coupling_searches
) cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.answer, es.note
FROM (
    SELECT * FROM eliminations.searched
) es
