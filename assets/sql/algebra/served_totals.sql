-- entries/holder_totals.sqlc against folds/served_totals.sqlc and entries/unserved_totals.sqlc, per layer.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT 'folds/served_totals' AS subject,
           count(*) FILTER (WHERE NOT x.balances) = 0 AS holds,
           format('%s layers with a holder, %s where held = served + unserved%s',
                  count(*), count(*) FILTER (WHERE x.balances),
                  coalesce(': not on ' || string_agg(x.filing || '/' || x.layer, ', ' ORDER BY x.filing, x.layer)
                                           FILTER (WHERE NOT x.balances), '')) AS detail
    FROM (
        SELECT t.filing, t.layer,
               t.holders = coalesce(s.holders, 0) + coalesce(u.holders, 0)
                 AND coalesce(t.shares_mode, 0) = coalesce(s.served_mode, 0) + coalesce(u.unserved_mode, 0)
                   AS balances
        FROM      (
            SELECT * FROM entries.holder_totals
        ) t
        LEFT JOIN (
            SELECT * FROM folds.served_totals
        ) s ON s.filing = t.filing AND s.layer = t.layer
        LEFT JOIN (
            SELECT * FROM entries.unserved_totals
        ) u ON u.filing = t.filing AND u.layer = t.layer
    ) x
) p ON true
WHERE a.slug = 'served_totals'
