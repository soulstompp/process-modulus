-- epistemics/searches.sqlc against the two relations it unions.
SELECT a.law, p.subject, p.holds, p.detail
FROM      (
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

) a
LEFT JOIN (
    SELECT 'epistemics/searches' AS subject,
           x.whole = x.couplings + x.eliminations AS holds,
           format('%s searches = %s coupling + %s double-counting',
                  x.whole, x.couplings, x.eliminations) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( -- pm:Stack/pm:Couplings and pm:Fusion/pm:Eliminations, each with its pm:Absent.
SELECT cs.filing, 'couplings between layers' AS looked_for, '(the stack)' AS about,
       cs.answer, cs.note
FROM (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) cs
UNION ALL
SELECT es.composition, 'double counting across parts', es.composed_layer,
       es.answer, es.note
FROM (
    -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

) es
 ) s)              AS whole,
             (SELECT count(*) FROM ( -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
 ) c)     AS couplings,
             (SELECT count(*) FROM ( -- asrt:Fusion/asrt:Eliminations/asrt:Absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
 ) e)  AS eliminations
         ) x
) p ON true
WHERE a.slug = 'searches'
