-- every class of every type on epistemics/class_sets.sqlc, with its standing and reason.
SELECT * FROM (VALUES
  ('arithmetic/all.sqlc', 'suspended', 'exercised'::public.fit_standing, NULL::text, NULL::text),
  ('arithmetic/all.sqlc', 'not comparable', 'open',
   'every pair of magnitudes this corpus puts together shares a unit, and a unit is a property of a claim rather than of a layer, so nothing in the schema stops the pair from disagreeing',
   'algebra/layer_units'),
  ('arithmetic/all.sqlc', 'computable', 'exercised', NULL, NULL),

  ('layers/remainder.sqlc', 'clearance',    'exercised', NULL, NULL),
  ('layers/remainder.sqlc', 'transition',   'exercised', NULL, NULL),
  ('layers/remainder.sqlc', 'interference', 'exercised', NULL, NULL),

  ('layers/remainder_scope.sqlc', 'takes a spillover',              'exercised', NULL, NULL),
  ('layers/remainder_scope.sqlc', 'nobody bounded the set',         'exercised', NULL, NULL),
  ('layers/remainder_scope.sqlc', 'set bounded, pairs untested',    'exercised', NULL, NULL),
  ('layers/remainder_scope.sqlc', 'bounded and the pairs answered', 'exercised', NULL, NULL),

  ('layers/exposure_scope.sqlc', 'a buffer nobody sized', 'exercised', NULL, NULL),
  ('layers/exposure_scope.sqlc', 'a buffer with room in it', 'open',
   'no layer sizes every buffer and has room in one: ignorance outranks room, so every layer '
   'that does have room sits under a buffer nobody sized',
   NULL),
  ('layers/exposure_scope.sqlc', 'every buffer sized and empty', 'exercised', NULL, NULL),

  ('layers/quantities.sqlc', 'demand',         'exercised', NULL, NULL),
  ('layers/quantities.sqlc', 'nameplate',      'exercised', NULL, NULL),
  ('layers/quantities.sqlc', 'inventorySlack', 'exercised', NULL, NULL),
  ('layers/quantities.sqlc', 'capacitySlack',  'exercised', NULL, NULL),
  ('layers/quantities.sqlc', 'timeSlack',      'exercised', NULL, NULL),

  ('checks/fit_axes.sqlc', 'filed sign',            'exercised', NULL, NULL),
  ('checks/fit_axes.sqlc', 'derived fit',           'exercised', NULL, NULL),
  ('checks/fit_axes.sqlc', 'filed against derived', 'exercised', NULL, NULL),
  ('checks/fit_axes.sqlc', 'not read',              'exercised', NULL, NULL),

  ('checks/fit_domain.sqlc', 'exercised', 'exercised', NULL, NULL),
  ('checks/fit_domain.sqlc', 'outside',   'exercised', NULL, NULL),
  ('checks/fit_domain.sqlc', 'open',      'exercised', NULL, NULL),

  ('composition/part_references.sqlc', 'omitted', 'exercised', NULL, NULL),
  ('composition/part_references.sqlc', 'stated',  'exercised', NULL, NULL),
  ('composition/part_references.sqlc', 'absent',  'exercised', NULL, NULL),
  ('composition/part_references.sqlc', 'derivation', 'open',
   'nothing computes a factor from the unit graph or from the fusion sum, so a part filing one would be naming an output no receiver produces; identities/roster.sqlc declares fusionSum and conversionPath for the position and neither is implemented',
   NULL)
) AS d(relation, class, standing, reason, held_by)
