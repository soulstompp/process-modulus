-- pm:Jagged/pm:draw from composition/resolved_quantities.sqlc, against layers/nameplate.sqlc and entries/slacks.sqlc's capacity slack.
SELECT dr.filing, dr.layer,
       dr.low  AS draw_low,
       dr.mode AS draw_mode,
       dr.high AS draw_high,
       dr.unit AS draw_unit,
       n.low   AS n_low,
       n.mode  AS n_mode,
       n.high  AS n_high,
       n.unit  AS n_unit,
       s.low    AS capacity_low,
       s.mode   AS capacity_slack,
       s.high   AS capacity_high,
       s.unit   AS capacity_unit,
       s.absent AS capacity_absent
FROM      (
    SELECT q.filing, q.layer, q.low, q.mode, q.high, q.unit
    FROM ( SELECT * FROM composition.resolved_quantities ) q
    WHERE q.quantity = 'draw'
      AND q.low IS NOT NULL
) dr
JOIN      (
    SELECT n.filing, n.layer, n.n_low AS low, n.n_mode AS mode, n.n_high AS high, n.n_unit AS unit
    FROM ( SELECT * FROM layers.nameplate ) n
) n ON n.filing = dr.filing AND n.layer = dr.layer
LEFT JOIN (
    SELECT * FROM entries.slacks
) s ON s.filing = dr.filing AND s.layer = dr.layer AND s.buffer = 'capacity'
