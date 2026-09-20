-- each incidence and each magnitude, counted against layers/every_layer.sqlc as the denominator.
SELECT x.relation, x.kind, x.reaches,
       (SELECT count(*) FROM ( SELECT * FROM layers.every_layer ) l) AS of_layers
FROM      (
    SELECT 'D draw'      AS relation, 'incidence' AS kind, count(DISTINCT (d.filing, d.layer)) AS reaches
    FROM ( SELECT * FROM entries.draws ) d
    UNION ALL
    SELECT 'N induction', 'incidence', count(DISTINCT (n.filing, n.layer))
    FROM ( SELECT * FROM entries.inductions ) n
    UNION ALL
    SELECT 'C coupling',  'incidence', count(DISTINCT (c.filing, c.from_layer))
    FROM ( SELECT * FROM entries.couplings ) c
    UNION ALL
    SELECT 'F part',      'incidence', count(DISTINCT (p.composition, p.composed_layer))
    FROM ( SELECT * FROM composition.parts ) p
    UNION ALL
    SELECT 'nameplate',   'magnitude', count(DISTINCT (n.filing, n.layer))
    FROM ( SELECT * FROM layers.nameplate ) n
    UNION ALL
    SELECT 'slack',       'magnitude', count(DISTINCT (s.filing, s.layer))
    FROM ( SELECT * FROM entries.slacks ) s
) x
