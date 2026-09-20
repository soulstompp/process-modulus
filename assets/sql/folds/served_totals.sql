-- entries/served_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_mode IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_low)                                 AS served_low,
       sum(h.share_mode)                                AS served_mode,
       sum(h.share_high)                                AS served_high,
       array_agg(DISTINCT h.share_unit)                 AS share_units,
       string_agg(DISTINCT h.kind::text, ' and ')       AS kinds
FROM (
    SELECT * FROM entries.served_holders
) h
GROUP BY h.filing, h.layer
