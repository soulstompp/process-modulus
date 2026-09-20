-- pm:HolderKind values `booked`, `counterparty` and `people`.
SELECT h.*
FROM (
    SELECT * FROM entries.holders
) h
WHERE h.kind IN ('booked', 'counterparty', 'people')
