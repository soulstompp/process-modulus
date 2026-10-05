-- entries/served_holders.sqlc folded to one row per layer.
WITH entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
),
entries_served_holders AS (
-- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('booked', 'counterparty', 'people')
)
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
    SELECT * FROM entries_served_holders
) h
GROUP BY h.filing, h.layer
