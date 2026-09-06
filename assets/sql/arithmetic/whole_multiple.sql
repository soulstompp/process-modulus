-- pm:Divisibility/pm:quantum against pm:Nameplate/pm:amount.
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
           CASE WHEN l.quantum_mode IS NULL                            THEN 'suspended'
                WHEN l.quantum_unit IS DISTINCT FROM l.amount_unit     THEN 'not comparable'
                ELSE 'computable' END AS verdict,
           CASE WHEN l.quantum_mode IS NULL THEN 'no quantum stated'
                ELSE format('%s of %s against a rating in %s',
                            l.quantum_mode, l.quantum_unit, l.amount_unit) END AS detail
    FROM (
        -- pm:Nameplate/pm:Divisibility with a pm:LumpyQuantum.
SELECT r.*
FROM (
    -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
SELECT d.filing, d.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       d.d_low, d.d_mode, d.d_high, d.d_unit AS unit,
       n.n_low, n.n_mode, n.n_high, n.n_unit AS amount_unit,
       n.n_low  - d.d_high AS r_low,   -- crossed: the low of n − d pairs n.low with d.HIGH
       n.n_mode - d.d_mode AS r_mode,
       n.n_high - d.d_low  AS r_high,
       CASE WHEN n.n_low  - d.d_high >= 0 THEN 'clearance'
            WHEN n.n_high - d.d_low  <= 0 THEN 'interference'
            ELSE 'transition' END AS derived_fit,
       greatest(d.d_high - n.n_low, 0) AS exposure,
       n.lumpy, n.quantum_mode, n.quantum_unit
FROM      (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
JOIN      (
    -- from pm.nameplate; pm:Layer/pm:Nameplate, its Divisibility and its window.
SELECT n.filing, n.layer,
       n.amount_low  AS n_low,
       n.amount_mode AS n_mode,
       n.amount_high AS n_high,
       n.amount_unit AS n_unit,
       n.amount_origin,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent
FROM pm.nameplate n
WHERE n.amount_low IS NOT NULL

) n USING (filing, layer)
JOIN pm.layer l USING (filing, layer)

) r
WHERE r.lumpy

    ) l
) p ON true
WHERE a.slug = 'whole_multiple'
