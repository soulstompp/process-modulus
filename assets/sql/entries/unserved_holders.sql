-- pm:HolderKind values `customer` and `unrealised`.
SELECT h.*
FROM (
    SELECT * FROM entries.holders
) h
WHERE h.kind IN ('customer', 'unrealised')
