-- §2  The operations that both draw and induce, the entries `D-transpose N` would have.
-- entries/cross_layer_edges.sqlc, the join on the shared (filing, operation) index.
SELECT x.operation        AS "operation!",
       x.drawn_from       AS "drawn!",
       x.drawn::float8    AS d_val,
       x.commits          AS "commits!",
       x.committed::float8 AS n_val
FROM (
    SELECT * FROM entries.cross_layer_edges
) x
