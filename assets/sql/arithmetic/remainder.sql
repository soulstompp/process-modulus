-- pm:Demand/pm:claim against pm:Nameplate/pm:amount, before layers/remainder.sqlc drops either.
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
    SELECT l.filing, l.layer,
           CASE WHEN l.demand_low IS NULL OR n.amount_low IS NULL THEN 'suspended'
                WHEN l.demand_unit IS DISTINCT FROM n.amount_unit  THEN 'not comparable'
                ELSE 'computable' END AS verdict,
           CASE WHEN l.demand_low IS NULL AND n.amount_low IS NULL
                     THEN format('demand %s and nameplate %s', l.demand_absent, n.amount_absent)
                WHEN l.demand_low IS NULL THEN format('demand %s', l.demand_absent)
                WHEN n.amount_low IS NULL THEN format('nameplate %s', n.amount_absent)
                WHEN l.demand_unit IS DISTINCT FROM n.amount_unit
                     THEN format('%s against %s', l.demand_unit, n.amount_unit)
                ELSE format('both in %s', l.demand_unit) END AS detail
    FROM pm.layer l
    JOIN pm.nameplate n USING (filing, layer)
) p ON true
WHERE a.slug = 'remainder'
