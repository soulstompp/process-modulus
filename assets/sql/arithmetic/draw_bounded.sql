-- pm:Supply/pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    -- the arithmetic the schemas' prose owes, against the unit rules that exist to make it mean anything.
SELECT * FROM (VALUES
  ('remainder',          'r = n - d',                    'demand x nameplate',              NULL),
  ('shares_sum',         'sum of shares = |r|',          'holder shares x remainder',       NULL),
  ('shares_bounded',     'sum of shares <= S',           'holder shares x absorbing slack', 'slack_unit_mismatch'),
  ('whole_multiple',     'n mod q = 0',                  'nameplate x quantum',             'quantum_unit_mismatch'),
  ('draw_bounded',       'draw <= n + capacity slack',   'draw x nameplate x slack',        NULL),
  ('exposure_bounded',   'exposure <= unserved shares',  'remainder x unserved shares',     NULL),
  ('time_slack_derived', 'time slack = q / clearance',   'quantum x remainder',             NULL),
  ('filed_remainder',    'filed r = n - d',              'remainder quantity x remainder',  NULL),
  ('fusion_sum',         'x_composed = F.Phi.x - e',     'parts x factors x elimination',   '(forbidden)')
) AS a(slug, site, operands, guarded_by)

) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.capacity_slack IS NULL                       THEN 'suspended'
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit          THEN 'not comparable'
                ELSE 'computable' END AS verdict,
           CASE WHEN d.capacity_slack IS NULL
                     THEN format('the capacity buffer is %s', d.capacity_absent)
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                     THEN format('a draw in %s against a rating in %s', d.draw_unit, d.n_unit)
                ELSE format('draw, rating and slack all in %s', d.n_unit) END AS detail
    FROM (
        -- pm:Supply/pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT n.filing, n.layer,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       s.mode   AS capacity_slack,
       s.absent AS capacity_absent
FROM pm.nameplate n
LEFT JOIN (
    -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

) s ON s.filing = n.filing AND s.layer = n.layer AND s.buffer = 'capacity'
WHERE n.draw_mode   IS NOT NULL
  AND n.amount_mode IS NOT NULL

    ) d
) p ON true
WHERE a.slug = 'draw_bounded'
