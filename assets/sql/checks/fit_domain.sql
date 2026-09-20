-- the declared standing of each rule on checks/fit_axes.sqlc in each cell of its axis.
SELECT * FROM (VALUES
  ('fit_disagrees', 'clearance'::pm.fit, 'exercised'::public.fit_standing, NULL::text),
  ('fit_disagrees', 'transition',   'exercised', NULL),
  ('fit_disagrees', 'interference', 'exercised', NULL),
  ('fit_disagrees', NULL,           'outside',
   'layers/signed.sqlc reads layers/remainder.sqlc, which needs a demand and a nameplate to derive the fit a filed sign is compared with'),

  ('shares_do_not_sum', 'clearance',    'exercised', NULL),
  ('shares_do_not_sum', 'transition',   'open',
   'a transition whose shares sum to the magnitude of its larger side is a legitimate filing; nothing loaded states shares on a transition'),
  ('shares_do_not_sum', 'interference', 'exercised', NULL),
  ('shares_do_not_sum', NULL,           'outside',
   'the magnitude the shares sum to comes from layers/remainder.sqlc, which needs a demand and a nameplate'),

  ('stated_quantity_is_not_the_magnitude', 'clearance',    'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'transition',   'exercised', NULL),
  ('stated_quantity_is_not_the_magnitude', 'interference', 'open',
   'a remainder under interference may state its quantity; nothing loaded does'),
  ('stated_quantity_is_not_the_magnitude', NULL,           'outside',
   'layers/filed_against_derived.sqlc compares against the magnitude layers/remainder.sqlc derives from a demand and a nameplate'),

  ('nobody_named_as_unserved', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none: nothing went unserved'),
  ('nobody_named_as_unserved', 'transition',   'exercised', NULL),
  ('nobody_named_as_unserved', 'interference', 'exercised', NULL),
  ('nobody_named_as_unserved', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('exposure_unaccounted', 'clearance',    'outside',
   'layers/exposure_scope.sqlc keeps a positive exposure, and a clearance has none'),
  ('exposure_unaccounted', 'transition',   'open',
   'refutation/compute reaches it with every buffer empty, and the rule suspends because its unserved share is unmeasured; a transition stating every unserved share would be examined'),
  ('exposure_unaccounted', 'interference', 'exercised', NULL),
  ('exposure_unaccounted', NULL,           'outside',
   'there is no exposure without a remainder to take it from'),

  ('share_exceeds_slack', 'clearance',    'outside',
   'layers/pressed.sqlc keeps a filed interference or transition'),
  ('share_exceeds_slack', 'transition',   'outside',
   'entries/borne.sqlc keeps interference alone: under a transition the shares and the slack bound opposite edges of one buffer'),
  ('share_exceeds_slack', 'interference', 'open',
   'a served share under interference, every served share stated, whose absorbing buffer states its slack; every such layer loaded leaves that slack unsized'),
  ('share_exceeds_slack', NULL,           'outside',
   'layers/pressed.sqlc keeps a filed sign'),

  ('clearance_with_unserved', 'clearance',    'exercised', NULL),
  ('clearance_with_unserved', 'transition',   'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', 'interference', 'outside',
   'its population is a filed clearance'),
  ('clearance_with_unserved', NULL,           'outside',
   'its population is a filed clearance')
) AS d(slug, fit, standing, reason)
