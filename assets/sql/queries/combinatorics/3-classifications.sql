-- §3  Every classification this tree makes, against the set of classes it declares.
-- public.* and pm.fit, each member against the relation whose classes it declares.
SELECT u.relation AS "relation!", u.codomain AS "codomain!", u.class AS "class!",
       u.balls AS "balls!"
FROM (
    SELECT 'arithmetic/all.sqlc' AS relation, pg_typeof(c.class)::text AS codomain,
           c.class::text AS class, count(z.site) AS balls, c.ord
    FROM unnest(enum_range(NULL::public.arithmetic_verdict)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM arithmetic.all
    ) z ON z.verdict = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'layers/remainder_scope.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.layer), c.ord
    FROM unnest(enum_range(NULL::public.remainder_standing)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM layers.remainder_scope
    ) z ON z.standing = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'layers/exposure_scope.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.layer), c.ord
    FROM unnest(enum_range(NULL::public.exposure_standing)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM layers.exposure_scope
    ) z ON z.standing = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'layers/remainder.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.layer), c.ord
    FROM unnest(enum_range(NULL::pm.fit)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM layers.remainder
    ) z ON z.derived_fit = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'checks/fit_axes.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.slug), c.ord
    FROM unnest(enum_range(NULL::public.fit_axis)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM checks.fit_axes
    ) z ON z.axis = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'checks/fit_domain.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.slug), c.ord
    FROM unnest(enum_range(NULL::public.fit_standing)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM checks.fit_domain
    ) z ON z.standing = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'composition/part_references.sqlc', pg_typeof(c.class)::text, c.class::text,
           count(z.part_layer), c.ord
    FROM unnest(enum_range(NULL::public.factor_state)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM composition.part_references
    ) z ON z.factor_state = c.class
    GROUP BY c.class, c.ord
    UNION ALL
    SELECT 'layers/quantities.sqlc', pg_typeof(c.class)::text, c.class::text, count(z.layer), c.ord
    FROM unnest(enum_range(NULL::public.layer_quantity)) WITH ORDINALITY AS c(class, ord)
    LEFT JOIN (
        SELECT * FROM layers.quantities
    ) z ON z.quantity = c.class
    GROUP BY c.class, c.ord
) u
ORDER BY u.relation, u.ord
