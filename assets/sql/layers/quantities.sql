-- pm:Layer's own quantities: demand, nameplate and the three buffer slacks, keyed by element.
SELECT d.filing, d.layer, 'demand'::public.layer_quantity AS quantity,
       d.d_low AS low, d.d_mode AS mode, d.d_high AS high, d.d_unit AS unit
FROM (
    SELECT * FROM layers.demand
) d
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::public.layer_quantity,
       n.n_low, n.n_mode, n.n_high, n.n_unit
FROM (
    SELECT * FROM layers.nameplate
) n
UNION ALL
SELECT s.filing, s.layer, (s.buffer || 'Slack')::public.layer_quantity,
       s.low, s.mode, s.high, s.unit
FROM (
    SELECT * FROM entries.slacks
) s
WHERE s.low IS NOT NULL
