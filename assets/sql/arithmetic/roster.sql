-- the arithmetic the schemas' prose owes, against the unit rules that exist to make it mean
-- anything.
SELECT * FROM (VALUES
  ('remainder',          'the remainder is the nameplate less the demand',
                         'demand and nameplate',              NULL),
  ('shares_sum',         'the shares add up to the size of the remainder',
                         'holder shares and remainder',       NULL),
  ('shares_bounded',     'the shares add up to no more than the absorbing slack',
                         'holder shares and absorbing slack', 'slack_unit_mismatch'),
  ('whole_multiple',     'the nameplate is a whole number of quanta',
                         'nameplate and quantum',             'quantum_unit_mismatch'),
  ('draw_bounded',       'the draw is no more than the nameplate plus its capacity slack',
                         'draw, nameplate and slack',         NULL),
  ('exposure_bounded',   'the exposure is no more than the unserved shares',
                         'remainder and unserved shares',     NULL),
  ('time_slack_derived', 'the time slack is the nameplate less the demand, never below zero',
                         'demand and nameplate',              NULL),
  ('filed_remainder',    'a filed remainder is the nameplate less the demand',
                         'remainder quantity and remainder',  NULL),
  ('fusion_sum',         'a composed figure is its converted parts added up, less its eliminations',
                         'parts, factors and elimination',    '(forbidden)')
) AS a(slug, site, operands, guarded_by)
