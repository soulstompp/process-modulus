-- checks/fit_axes.sqlc and checks/fit_domain.sqlc against rank/rule_closure.sqlc and reports/fit_coverage.sqlc.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT s.slug AS subject,
           r.slug IS NOT NULL
           AND coalesce(x.axes, 0) = 1
           AND (x.axis = 'not read') = NOT coalesce(h.reaches, false)
           AND CASE WHEN x.axis = 'not read' THEN coalesce(k.cells, 0) = 0
                    ELSE coalesce(k.cells, 0) = 4 AND k.distinct_cells = 4 END
           AND coalesce(k.disagreeing, 0) = 0                             AS holds,
           format('%s; its closure %s the fit; %s cells, %s disagreeing with what it examined%s',
                  coalesce(x.axis::text, 'no axis declared'),
                  CASE WHEN coalesce(h.reaches, false) THEN 'reaches' ELSE 'does not reach' END,
                  coalesce(k.cells, 0), coalesce(k.disagreeing, 0),
                  coalesce(': ' || k.cells_read, ''))                     AS detail
    FROM (
        SELECT slug FROM ( SELECT * FROM checks.roster ) r0
        UNION
        SELECT slug FROM ( SELECT * FROM checks.fit_axes ) a0
        UNION
        SELECT slug FROM ( SELECT * FROM checks.fit_domain ) d0
    ) s
    LEFT JOIN (
        SELECT * FROM checks.roster
    ) r ON r.slug = s.slug
    LEFT JOIN (
        SELECT f.slug, count(*) AS axes, min(f.axis) AS axis
        FROM ( SELECT * FROM checks.fit_axes ) f
        GROUP BY f.slug
    ) x ON x.slug = s.slug
    LEFT JOIN (
        SELECT c.slug, true AS reaches
        FROM ( -- rank/compose_edges.sqlc walked from each rule on checks/roster.sqlc.
WITH RECURSIVE closure(slug, template) AS (
    SELECT r.slug, 'checks/' || r.slug || '.sqlc'
    FROM (
        SELECT * FROM checks.roster
    ) r
    UNION
    SELECT c.slug, e.child
    FROM closure c
    JOIN (
        SELECT * FROM rank.compose_edges
    ) e ON e.parent = c.template
)
SELECT slug, template FROM closure
 ) c
        WHERE c.template IN ('layers/remainder.sqlc', 'layers/filed_remainders.sqlc')
        GROUP BY c.slug
    ) h ON h.slug = s.slug
    LEFT JOIN (
        SELECT v.slug,
               count(*)                                                        AS cells,
               count(DISTINCT coalesce(v.fit::text, 'no fit'))                 AS distinct_cells,
               count(*) FILTER (WHERE (v.standing = 'exercised') <> (v.examined > 0)) AS disagreeing,
               string_agg(coalesce(v.fit::text, 'no fit') || ' ' || v.standing || ' ' || v.examined,
                          ', ' ORDER BY v.fit NULLS LAST)                      AS cells_read
        FROM ( SELECT * FROM reports.fit_coverage ) v
        GROUP BY v.slug
    ) k ON k.slug = s.slug
) p ON true
WHERE a.slug = 'fit_domain'
