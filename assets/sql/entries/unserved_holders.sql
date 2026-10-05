-- pm:HolderKind values `customer` and `unrealised`.
WITH entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
)
SELECT h.*
FROM (
    SELECT * FROM entries_holders
) h
WHERE h.kind IN ('customer', 'unrealised')
