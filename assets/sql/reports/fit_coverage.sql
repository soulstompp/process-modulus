-- checks/fit_domain.sqlc against checks/fit_cells.sqlc.
SELECT d.slug, a.axis, d.fit, d.standing, d.reason, count(o.layer) AS examined
FROM      (
    SELECT * FROM checks.fit_domain
) d
JOIN      (
    SELECT * FROM checks.fit_axes
) a ON a.slug = d.slug
LEFT JOIN (
    -- checks/all.sqlc per checks/fit_axes.sqlc against layers/filed_remainders.sqlc and layers/remainder.sqlc.
SELECT a.slug, a.axis, c.filing, c.layer,
       CASE WHEN a.axis = 'filed sign' THEN f.sign ELSE x.derived_fit END AS fit
FROM      (
    SELECT * FROM checks.all
) c
JOIN      (
    SELECT * FROM checks.roster
) r ON r.rule = c.rule
JOIN      (
    SELECT * FROM checks.fit_axes
) a ON a.slug = r.slug
LEFT JOIN (
    SELECT * FROM layers.filed_remainders
) f ON f.filing = c.filing AND f.layer = c.layer
LEFT JOIN (
    SELECT * FROM layers.remainder
) x ON x.filing = c.filing AND x.layer = c.layer
WHERE c.violates IS NOT NULL
  AND a.axis <> 'not read'

) o ON o.slug = d.slug AND o.fit IS NOT DISTINCT FROM d.fit
GROUP BY d.slug, a.axis, d.fit, d.standing, d.reason
