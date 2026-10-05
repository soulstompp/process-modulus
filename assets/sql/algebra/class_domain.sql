-- algebra/roster.sqlc against class_sets ⟗ class_domain ⟗ classes, read six ways.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    WITH census AS (
        SELECT * FROM epistemics.classes
    ),
    sets AS (
        SELECT * FROM epistemics.class_sets
    ),
    cells AS (
        SELECT * FROM epistemics.class_domain
    ),
    joined AS (
        SELECT c.relation   AS census_relation,
               c.class      AS census_class,
               c.balls      AS balls,
               d.relation   AS cell_relation,
               d.class      AS cell_class,
               d.standing   AS standing
        FROM      census c
        FULL JOIN cells  d ON d.relation = c.relation AND d.class = c.class
    ),
    per_set AS (
        SELECT coalesce(s.relation, g.relation)          AS relation,
               s.relation IS NOT NULL                    AS declared,
               g.relation IS NOT NULL                    AS produced,
               s.codomain                                AS declared_codomain,
               g.codomain                                AS produced_codomain,
               s.filed                                   AS filed,
               coalesce(g.filed_balls, 0) > 0            AS any_filed
        FROM      sets s
        FULL JOIN (
            SELECT relation, min(codomain) AS codomain, sum(filed_balls) AS filed_balls
            FROM census GROUP BY relation
        ) g ON g.relation = s.relation
    )
    SELECT 'a class the roster does not name' AS subject,
           count(*) FILTER (WHERE cell_relation IS NULL) = 0                      AS holds,
           format('%s class(es) of a declared codomain with no cell: %s',
                  count(*) FILTER (WHERE cell_relation IS NULL),
                  coalesce(string_agg(census_relation || ' ' || census_class, ', '
                                      ORDER BY census_relation, census_class)
                           FILTER (WHERE cell_relation IS NULL), '(none)'))       AS detail
    FROM joined
    UNION ALL
    SELECT 'a roster row naming no class',
           count(*) FILTER (WHERE census_relation IS NULL) = 0,
           format('%s cell(s) naming a class their codomain does not have: %s',
                  count(*) FILTER (WHERE census_relation IS NULL),
                  coalesce(string_agg(cell_relation || ' ' || cell_class, ', '
                                      ORDER BY cell_relation, cell_class)
                           FILTER (WHERE census_relation IS NULL), '(none)'))
    FROM joined
    UNION ALL
    SELECT 'a class declared twice',
           count(*) = 0,
           format('%s class(es) with more than one cell: %s',
                  count(*),
                  coalesce(string_agg(relation || ' ' || class || ' (' || n || ')', ', '
                                      ORDER BY relation, class), '(none)'))
    FROM (
        SELECT d.relation, d.class, count(*) AS n
        FROM cells d GROUP BY d.relation, d.class HAVING count(*) > 1
    ) dup
    UNION ALL
    SELECT 'a standing that disagrees with the count',
           count(*) FILTER (WHERE census_relation IS NOT NULL AND cell_relation IS NOT NULL
                              AND (standing = 'exercised') <> (balls > 0)) = 0,
           format('%s class(es) whose standing and count disagree: %s',
                  count(*) FILTER (WHERE census_relation IS NOT NULL AND cell_relation IS NOT NULL
                                     AND (standing = 'exercised') <> (balls > 0)),
                  coalesce(string_agg(cell_relation || ' ' || cell_class
                                      || ' ' || standing || ' with ' || balls, ', '
                                      ORDER BY cell_relation, cell_class)
                           FILTER (WHERE census_relation IS NOT NULL AND cell_relation IS NOT NULL
                                     AND (standing = 'exercised') <> (balls > 0)), '(none)'))
    FROM joined
    UNION ALL
    SELECT 'a classification nobody declared',
           count(*) FILTER (WHERE NOT declared OR NOT produced
                              OR declared_codomain IS DISTINCT FROM produced_codomain) = 0,
           format('%s classification(s) the two rosters disagree on: %s',
                  count(*) FILTER (WHERE NOT declared OR NOT produced
                                     OR declared_codomain IS DISTINCT FROM produced_codomain),
                  coalesce(string_agg(relation || ' declared '
                                      || coalesce(declared_codomain, '(nothing)') || ', produces '
                                      || coalesce(produced_codomain, '(nothing)'), ', '
                                      ORDER BY relation)
                           FILTER (WHERE NOT declared OR NOT produced
                                     OR declared_codomain IS DISTINCT FROM produced_codomain),
                           '(none)'))
    FROM per_set
    UNION ALL
    SELECT 'a filed flag that disagrees with the balls',
           count(*) FILTER (WHERE declared AND produced AND filed <> any_filed) = 0,
           format('%s classification(s) whose filed flag is wrong: %s',
                  count(*) FILTER (WHERE declared AND produced AND filed <> any_filed),
                  coalesce(string_agg(relation || ' declared ' || filed, ', ' ORDER BY relation)
                           FILTER (WHERE declared AND produced AND filed <> any_filed), '(none)'))
    FROM per_set
) p ON true
WHERE a.slug = 'class_domain'
