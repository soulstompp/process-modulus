-- information_schema.columns, restricted to schema pm and type pm.absence_reason.
SELECT c.table_name::text  AS table_name,
       c.column_name::text AS column_name
FROM information_schema.columns c
WHERE c.table_schema = 'pm'
  AND c.udt_schema   = 'pm'
  AND c.udt_name     = 'absence_reason'
  AND (c.table_name, c.column_name) <> ('absence', 'reason')
