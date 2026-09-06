-- entries/unserved_holders.sqlc folded to one row per layer.
SELECT h.filing, h.layer,
       count(*)                                        AS holders,
       count(*) FILTER (WHERE h.share_high IS NULL)     AS unstated,
       sum(h.share_high)                                AS unserved_high,
       sum(h.share_mode)                                AS unserved_mode,
       array_agg(DISTINCT h.share_unit)                 AS share_units
FROM (
    -- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
WHERE h.kind IN ('customer', 'unrealised')

) h
GROUP BY h.filing, h.layer
