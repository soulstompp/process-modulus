-- every fold in folds/ whose population does not reach algebra/all.sqlc, its boxes against its rows and its rows against its population.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.unbalanced = 0 AND x.counted = x.population AS holds,
           format('%s rows over %s subjects, %s in the population; %s subjects whose boxes do not add up',
                  x.counted, x.subjects, x.population, x.unbalanced) AS detail
    FROM (
        SELECT 'rules' AS contract, f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM checks.all ) c) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.violated + s.passed) AS unbalanced
               FROM ( SELECT * FROM folds.rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM arithmetic.all ) z) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      count(*) FILTER (WHERE s.rows <> s.answered + s.silent + s.vacuous
                                         OR s.answered <> s.computable + s.suspended + s.not_comparable) AS unbalanced
               FROM ( SELECT * FROM folds.site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM diagrams.catalogue ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM diagrams.expected ) e) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM epistemics.absence_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations', f.subjects, f.counted, f.unbalanced,
               (SELECT count(*) FROM ( SELECT * FROM epistemics.derivation_columns ) k) AS population
        FROM ( SELECT count(*) AS subjects, sum(s.rows) AS counted,
                      0::bigint AS unbalanced
               FROM ( SELECT * FROM folds.derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'subject_boxes'
