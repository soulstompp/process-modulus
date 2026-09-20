-- the seven contracts' folds, each labelled with the contract it counts.
SELECT 'rules' AS contract, f.subject, f.declared, f.rows, f.answered, f.silent, f.vacuous
FROM ( SELECT * FROM folds.rule_subjects ) f
UNION ALL
SELECT 'arithmetic', f.subject, f.declared, f.rows, f.answered, f.silent, f.vacuous
FROM ( SELECT * FROM folds.site_subjects ) f
UNION ALL
SELECT 'algebra', f.subject, f.declared, f.rows, f.answered, f.silent, f.vacuous
FROM ( SELECT * FROM folds.law_subjects ) f
UNION ALL
SELECT 'diagrams', f.subject, f.declared, f.rows, f.rows, 0::bigint, 0::bigint
FROM ( SELECT * FROM folds.object_subjects ) f
UNION ALL
SELECT 'diagram laws', f.subject, f.declared, f.rows, f.rows, 0::bigint, 0::bigint
FROM ( SELECT * FROM folds.diagram_law_subjects ) f
UNION ALL
SELECT 'absences', f.subject, f.declared, f.rows, f.rows, 0::bigint, 0::bigint
FROM ( SELECT * FROM folds.absence_subjects ) f
UNION ALL
SELECT 'derivations', f.subject, f.declared, f.rows, f.rows, 0::bigint, 0::bigint
FROM ( SELECT * FROM folds.derivation_subjects ) f
