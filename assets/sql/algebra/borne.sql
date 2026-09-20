-- entries/served_holders.sqlc and entries/unserved_holders.sqlc against pm:Remainder/pm:holder.
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra.roster
) a
LEFT JOIN (
    SELECT x.filing || ' / ' || x.layer AS subject,
           abs(x.held - x.served - x.unserved) < 1e-9 AS holds,
           format('%s held = %s absorbed + %s unserved', x.held, x.served, x.unserved) AS detail
    FROM (
        SELECT h.filing, h.layer,
               sum(h.share_mode)                                            AS held,
               coalesce((SELECT sum(v.share_mode) FROM (
                   SELECT * FROM entries.served_holders
               ) v WHERE v.filing = h.filing AND v.layer = h.layer), 0)      AS served,
               coalesce((SELECT sum(u.share_mode) FROM (
                   SELECT * FROM entries.unserved_holders
               ) u WHERE u.filing = h.filing AND u.layer = h.layer), 0)      AS unserved
        FROM (
            SELECT * FROM entries.holders
        ) h
        WHERE h.share_mode IS NOT NULL
        GROUP BY h.filing, h.layer
    ) x
) p ON true
WHERE a.slug = 'borne'
