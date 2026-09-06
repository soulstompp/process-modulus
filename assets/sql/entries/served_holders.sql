-- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

) h
WHERE h.kind IN ('booked', 'counterparty', 'people')
