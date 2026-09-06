-- §3  Which relations a law governs, the roster, as the example reads it.
-- algebra/roster.sqlc, projected to what the tree-walk needs.
SELECT r.governs      AS "governs!",
       r.form         AS "form!",
       r.multiplicity AS "multiplicity!"
FROM (
    -- the set-algebraic laws this tree's relations claim to obey; see the sql skill's set-algebra.md.
SELECT * FROM (VALUES
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('composed_demand',  '|A| = |A∖B| + |A⋉B|',        'queries/matrices/3b-composed-demand','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL')
) AS a(slug, law, governs, form, multiplicity)

) r
ORDER BY r.governs
