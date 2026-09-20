-- epistemics/searches.sqlc against the two relations it unions.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'epistemics/searches' AS subject,
           x.whole = x.couplings + x.eliminations AS holds,
           format('%s searches = %s coupling + %s double-counting',
                  x.whole, x.couplings, x.eliminations) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( SELECT * FROM epistemics.searches ) s)              AS whole,
             (SELECT count(*) FROM ( SELECT * FROM epistemics.coupling_searches ) c)     AS couplings,
             (SELECT count(*) FROM ( SELECT * FROM eliminations.searched ) e)  AS eliminations
         ) x
) p ON true
WHERE a.slug = 'searches'
