-- layers/remainder.sqlc against layers/remainder_scope.sqlc.
SELECT a.law, p.subject, p.holds, p.detail
FROM      (
    -- the set-algebraic laws this tree's relations claim to obey.
SELECT * FROM (VALUES
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('jagged_layers',    '|A| = |A∖B| + |A⋉B|',        'queries/observations/14-jagged-layers','difference','bag: one row per doubled layer'),
  ('composed_demand',  '|A| = |A∖B| + |A⋉B|',        'queries/matrices/3b-composed-demand','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('exposure_standing', 'each exposed layer in exactly one standing','layers/exposure_scope','partition','set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL'),
  ('part_regimes',     '|A| = |A∖B| + |A⋉B|',        'checks/part_regime_disagrees',     'difference', 'set: pm.part''s key')
) AS a(slug, law, governs, form, multiplicity)

) a
LEFT JOIN (
    SELECT 'layers/remainder_scope' AS subject,
           x.computable = x.classified AND x.doubled = 0 AS holds,
           format('%s computable remainders, %s classified, %s classified twice',
                  x.computable, x.classified, x.doubled) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( -- from pm.layer and pm.nameplate; pm:Layer/pm:Remainder/sign carries the filed classification.
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
 ) r)       AS computable,
             (SELECT count(*) FROM ( -- layers/remainder.sqlc against pm:Stack/pm:scope, pm:Couplings/pm:absent and entries/spillovers.sqlc.
SELECT r.filing, r.layer,
       sc.extent,
       cs.answer AS search,
       sp.observed_in AS spilled_from,
       CASE WHEN sp.observed_in IS NOT NULL THEN 'takes a spillover'
            WHEN sc.extent = 'unbounded'    THEN 'nobody bounded the set'
            WHEN cs.answer  = 'unmeasured'  THEN 'set bounded, pairs untested'
            ELSE 'bounded and the pairs answered' END AS standing
FROM      (
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
LEFT JOIN (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc ON sc.filing = r.filing
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) cs ON cs.filing = r.filing
LEFT JOIN ( SELECT DISTINCT borne_by, from_layer, observed_in FROM (
    -- pm:Couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s  ON s.filing = b.filing
LEFT JOIN (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc ON sc.filing = b.filing

) x ) sp ON sp.borne_by = r.filing AND sp.from_layer = r.layer
 ) z) AS classified,
             (SELECT count(*) FROM ( SELECT filing, layer FROM ( -- layers/remainder.sqlc against pm:Stack/pm:scope, pm:Couplings/pm:absent and entries/spillovers.sqlc.
SELECT r.filing, r.layer,
       sc.extent,
       cs.answer AS search,
       sp.observed_in AS spilled_from,
       CASE WHEN sp.observed_in IS NOT NULL THEN 'takes a spillover'
            WHEN sc.extent = 'unbounded'    THEN 'nobody bounded the set'
            WHEN cs.answer  = 'unmeasured'  THEN 'set bounded, pairs untested'
            ELSE 'bounded and the pairs answered' END AS standing
FROM      (
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
LEFT JOIN (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc ON sc.filing = r.filing
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) cs ON cs.filing = r.filing
LEFT JOIN ( SELECT DISTINCT borne_by, from_layer, observed_in FROM (
    -- pm:Couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s  ON s.filing = b.filing
LEFT JOIN (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc ON sc.filing = b.filing

) x ) sp ON sp.borne_by = r.filing AND sp.from_layer = r.layer
 ) z
                                     GROUP BY filing, layer HAVING count(*) > 1 ) d) AS doubled
         ) x
) p ON true
WHERE a.slug = 'remainder_standing'
