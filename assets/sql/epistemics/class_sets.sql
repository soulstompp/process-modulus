-- the eight classifications, their codomains, the unit each counts in, and whether it is filed.
SELECT * FROM (VALUES
  ('arithmetic/all.sqlc',              'arithmetic_verdict', 'computation', true),
  ('layers/remainder.sqlc',            'fit',                'layer',       true),
  ('layers/remainder_scope.sqlc',      'remainder_standing', 'layer',       true),
  ('layers/exposure_scope.sqlc',       'exposure_standing',  'layer',       true),
  ('layers/quantities.sqlc',           'layer_quantity',     'quantity',    true),
  ('composition/part_references.sqlc', 'factor_state',       'part',        true),
  ('checks/fit_axes.sqlc',             'fit_axis',           'rule',        false),
  ('checks/fit_domain.sqlc',           'fit_standing',       'rule cell',   false)
) AS s(relation, codomain, subject, filed)
