-- entries/unserved_holders.sqlc folded to one row per layer.
WITH entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
),
entries_unserved_holders AS (
-- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('customer', 'unrealised')
)
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_high IS NULL)     AS unstated,
       count(*) FILTER (WHERE h.share_derivation IS NOT NULL) AS derived,
       sum(h.share_high)                                AS unserved_high,
       sum(h.share_mode)                                AS unserved_mode,
       array_agg(DISTINCT h.share_unit)                 AS share_units
FROM (
    SELECT * FROM entries_unserved_holders
) h
GROUP BY h.filing, h.layer
