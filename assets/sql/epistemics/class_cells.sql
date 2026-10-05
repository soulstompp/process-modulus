-- every declared class of eight codomains, LEFT JOINed to the rows that landed in it.
SELECT 'arithmetic/all.sqlc' AS relation, (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)) AS codomain,
       c.class::text AS class, c.ord,
       z.site || ' / ' || z.filing || ' / ' || z.layer AS ball,
       z.filing AS filing
FROM unnest(enum_range(NULL::public.arithmetic_verdict)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM arithmetic.all
) z ON z.verdict = c.class
UNION ALL
SELECT 'layers/remainder_scope.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::public.remainder_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers.remainder_scope
) z ON z.standing = c.class
UNION ALL
SELECT 'layers/exposure_scope.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::public.exposure_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers.exposure_scope
) z ON z.standing = c.class
UNION ALL
SELECT 'layers/remainder.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer, z.filing
FROM unnest(enum_range(NULL::pm.fit)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers.remainder
) z ON z.derived_fit = c.class
UNION ALL
SELECT 'checks/fit_axes.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.slug, NULL
FROM unnest(enum_range(NULL::public.fit_axis)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM checks.fit_axes
) z ON z.axis = c.class
UNION ALL
SELECT 'checks/fit_domain.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.slug || ' / ' || coalesce(z.fit::text, 'no fit'), NULL
FROM unnest(enum_range(NULL::public.fit_standing)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM checks.fit_domain
) z ON z.standing = c.class
UNION ALL
SELECT 'composition/part_references.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.composition || ' / ' || z.composed_layer || ' / ' || z.part_filing || ' / ' || z.part_layer,
       z.composition
FROM unnest(enum_range(NULL::public.factor_state)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM composition.part_references
) z ON z.factor_state = c.class
UNION ALL
SELECT 'layers/quantities.sqlc', (SELECT t.typname::text FROM pg_type t WHERE t.oid = pg_typeof(c.class)), c.class::text, c.ord,
       z.filing || ' / ' || z.layer || ' / ' || z.quantity::text, z.filing
FROM unnest(enum_range(NULL::public.layer_quantity)) WITH ORDINALITY AS c(class, ord)
LEFT JOIN (
    SELECT * FROM layers.quantities
) z ON z.quantity = c.class
