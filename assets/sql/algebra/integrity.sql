-- every fold in folds/ whose population does not reach algebra/all.sqlc, against its roster and its population by EXCEPT.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.contract AS subject,
           x.roster = x.missing + x.produced
             AND x.declared = x.roster
             AND x.unproduced = x.missing
             AND x.undeclared = x.stray AS holds,
           format('%s declared = %s unproduced + %s produced, %s undeclared; by EXCEPT, %s on the roster, %s unproduced, %s undeclared',
                  x.declared, x.unproduced, x.produced, x.undeclared, x.roster, x.missing, x.stray) AS detail
    FROM (
        SELECT 'rules' AS contract,
               (SELECT count(DISTINCT r.rule) FROM ( SELECT * FROM checks.roster ) r) AS roster,
               (SELECT count(*) FROM ( SELECT r.rule FROM ( SELECT * FROM checks.roster ) r
                                       EXCEPT
                                       SELECT c.rule FROM ( SELECT * FROM checks.all ) c ) x) AS missing,
               (SELECT count(*) FROM ( SELECT c.rule FROM ( SELECT * FROM checks.all ) c
                                       EXCEPT
                                       SELECT r.rule FROM ( SELECT * FROM checks.roster ) r ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.rule_subjects ) s ) f
        UNION ALL
        SELECT 'arithmetic',
               (SELECT count(DISTINCT a.site) FROM ( SELECT * FROM arithmetic.roster ) a) AS roster,
               (SELECT count(*) FROM ( SELECT a.site FROM ( SELECT * FROM arithmetic.roster ) a
                                       EXCEPT
                                       SELECT z.site FROM ( SELECT * FROM arithmetic.all ) z ) x) AS missing,
               (SELECT count(*) FROM ( SELECT z.site FROM ( SELECT * FROM arithmetic.all ) z
                                       EXCEPT
                                       SELECT a.site FROM ( SELECT * FROM arithmetic.roster ) a ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.site_subjects ) s ) f
        UNION ALL
        SELECT 'diagrams',
               (SELECT count(DISTINCT d.object) FROM ( SELECT * FROM diagrams.domain_objects ) d) AS roster,
               (SELECT count(*) FROM ( SELECT d.object FROM ( SELECT * FROM diagrams.domain_objects ) d
                                       EXCEPT
                                       SELECT k.object FROM ( SELECT * FROM diagrams.catalogue ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.object FROM ( SELECT * FROM diagrams.catalogue ) k
                                       EXCEPT
                                       SELECT d.object FROM ( SELECT * FROM diagrams.domain_objects ) d ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.object_subjects ) s ) f
        UNION ALL
        SELECT 'diagram laws',
               (SELECT count(DISTINCT l.slug) FROM ( SELECT * FROM diagrams.roster ) l) AS roster,
               (SELECT count(*) FROM ( SELECT l.slug FROM ( SELECT * FROM diagrams.roster ) l
                                       EXCEPT
                                       SELECT e.slug FROM ( SELECT * FROM diagrams.expected ) e ) x) AS missing,
               (SELECT count(*) FROM ( SELECT e.slug FROM ( SELECT * FROM diagrams.expected ) e
                                       EXCEPT
                                       SELECT l.slug FROM ( SELECT * FROM diagrams.roster ) l ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.diagram_law_subjects ) s ) f
        UNION ALL
        SELECT 'absences',
               (SELECT count(DISTINCT q.table_name || '.' || q.column_name) FROM ( SELECT * FROM epistemics.absence_questions ) q) AS roster,
               (SELECT count(*) FROM ( SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM epistemics.absence_questions ) q
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.absence_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.absence_columns ) k
                                       EXCEPT
                                       SELECT q.table_name || '.' || q.column_name FROM ( SELECT * FROM epistemics.absence_questions ) q ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.absence_subjects ) s ) f
        UNION ALL
        SELECT 'derivations',
               (SELECT count(DISTINCT i.table_name || '.' || i.column_name) FROM ( SELECT * FROM identities.roster ) i) AS roster,
               (SELECT count(*) FROM ( SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities.roster ) i
                                       EXCEPT
                                       SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.derivation_columns ) k ) x) AS missing,
               (SELECT count(*) FROM ( SELECT k.table_name || '.' || k.column_name FROM ( SELECT * FROM epistemics.derivation_columns ) k
                                       EXCEPT
                                       SELECT i.table_name || '.' || i.column_name FROM ( SELECT * FROM identities.roster ) i ) x) AS stray,
               f.declared, f.unproduced, f.produced, f.undeclared
        FROM ( SELECT count(*) FILTER (WHERE s.declared)                AS declared,
                      count(*) FILTER (WHERE s.declared AND s.rows = 0) AS unproduced,
                      count(*) FILTER (WHERE s.declared AND s.rows > 0) AS produced,
                      count(*) FILTER (WHERE NOT s.declared)            AS undeclared
               FROM ( SELECT * FROM folds.derivation_subjects ) s ) f
    ) x
) p ON true
WHERE a.slug = 'integrity'
