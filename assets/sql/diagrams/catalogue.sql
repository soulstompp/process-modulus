-- information_schema.tables restricted to the schema this model owns.
SELECT t.table_name::text AS object
FROM information_schema.tables t
WHERE t.table_schema = 'pm' AND t.table_type = 'BASE TABLE'
