-- identities/roster.sqlc's columns against epistemics/derivation_columns.sqlc, one row per column.
SELECT coalesce(r.table_name, k.table_name) || '.' || coalesce(r.column_name, k.column_name)
                                            AS subject,
       r.column_name IS NOT NULL            AS declared,
       count(k.column_name)                 AS rows
FROM      (
    SELECT DISTINCT i.table_name, i.column_name
    FROM (
        SELECT * FROM identities.roster
    ) i
) r
FULL JOIN (
    SELECT * FROM epistemics.derivation_columns
) k ON k.table_name = r.table_name AND k.column_name = r.column_name
GROUP BY r.table_name, r.column_name, k.table_name, k.column_name
