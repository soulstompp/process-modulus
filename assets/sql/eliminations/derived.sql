-- composition/parts.sqlc crossed with itself on the part each side names, with that part's own figures.
SELECT a.part_filing, a.part_layer,
       a.composition    AS composition_a, a.composed_layer AS composed_a,
       b.composition    AS composition_b, b.composed_layer AS composed_b,
       (a.composition = b.composition) AS within_one_filing,
       f.d_mode         AS would_double_count_demand,
       f.n_mode         AS would_double_count_nameplate,
       f.d_unit         AS unit
FROM      (
    SELECT * FROM composition.parts
) a
JOIN      (
    SELECT * FROM composition.parts
) b ON  b.part_filing = a.part_filing
    AND b.part_layer  = a.part_layer
    AND (a.composition, a.composed_layer) < (b.composition, b.composed_layer)
LEFT JOIN (
    SELECT * FROM layers.figures
) f ON f.filing = a.part_filing AND f.layer = a.part_layer
