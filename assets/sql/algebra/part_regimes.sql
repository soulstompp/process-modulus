-- composition/part_regimes.sqlc partitioned by whether both sides state a framework.
SELECT a.law, p.subject, p.holds, p.detail
FROM      (
    -- the set-algebraic laws this tree's relations claim to obey.
SELECT * FROM (VALUES
  ('decomposition',    '|E| = Σ_filing |E_filing|',  'rank/decomposition',               'partition',  'bag: one edge counted in both scopes'),
  -- ⭐⭐⭐ NOT A SET IDENTITY, AND IT IS THE FIRST ROW HERE THAT IS NOT. Every other law on this
  --    roster is a cardinality identity over relations. This one is about the compose DAG: which
  --    templates may compose the layer DIMENSION. A dimension reaches every layer by
  --    construction, so a relation composing it hands the whole dimension to every consumer, and
  --    any downstream bound of the form *this reach is inside that reach* goes vacuous. Measured:
  --    one edge put the dimension into 20 of 29 rules' closures.
  ('dimension_use',    'parents(dimension) ⊆ declared', 'algebra/dimension_use',         'roster',     'set: one row per undeclared parent'),
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('jagged_layers',    '|A| = |A∖B| + |A⋉B|',        'queries/observations/14-jagged-layers','difference','bag: one row per doubled layer'),
  ('composed_demand',  '|A| = |A∖B| + |A⋉B|',        'queries/matrices/3b-composed-demand','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('carried',          '|A| = |A∖B| + |A⋉B|',        'composition/carried',              'difference', 'bag: anti-join preserves it'),
  ('owed_remainder',   '|A| = |A∖B| + |A⋉B|',        'composition/owed_remainder',       'difference', 'set'),
  ('settled_remainders','|A| = |A∖B| + |A⋉B|',       'composition/settled_remainders',   'difference', 'bag: one row per path'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('exposure_standing', 'each exposed layer in exactly one standing','layers/exposure_scope','partition','set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL'),
  ('part_regimes',     '|A| = |A∖B| + |A⋉B|',        'checks/part_regime_disagrees',     'difference', 'set: pm.part''s key')
) AS a(slug, law, governs, form, multiplicity)

) a
LEFT JOIN (
    SELECT 'composition/part_regimes' AS subject,
           x.total = x.askable + x.unaskable AS holds,
           format('%s parts with a regime handle = %s askable + %s where a typed absence or an unstated filing makes the question not arise',
                  x.total, x.askable, x.unaskable) AS detail
    FROM ( SELECT
             (SELECT count(*) FROM ( -- pm.part's regime handle resolved into pm.composition_regime, against the part filing's own pm.regime.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_taxonomy IS NOT NULL AND EXISTS (
            SELECT 1 FROM pm.regime r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*) FROM pm.regime r WHERE r.filing = p.part_filing
          AND r.framework_taxonomy IS NOT NULL)                          AS frameworks_the_filing_states
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN pm.composition_regime cr
  ON cr.composition = p.composition AND cr.id = p.part_regime
 ) r) AS total,
             (SELECT count(*) FROM ( -- pm.part's regime handle resolved into pm.composition_regime, against the part filing's own pm.regime.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_taxonomy IS NOT NULL AND EXISTS (
            SELECT 1 FROM pm.regime r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*) FROM pm.regime r WHERE r.filing = p.part_filing
          AND r.framework_taxonomy IS NOT NULL)                          AS frameworks_the_filing_states
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN pm.composition_regime cr
  ON cr.composition = p.composition AND cr.id = p.part_regime
 ) r
               WHERE r.composer_absent IS NULL AND r.frameworks_the_filing_states > 0) AS askable,
             (SELECT count(*) FROM ( -- pm.part's regime handle resolved into pm.composition_regime, against the part filing's own pm.regime.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       cr.framework_taxonomy AS composer_taxonomy,
       cr.framework_value    AS composer_value,
       cr.framework_absent   AS composer_absent,
       (cr.framework_taxonomy IS NOT NULL AND EXISTS (
            SELECT 1 FROM pm.regime r
            WHERE r.filing = p.part_filing
              AND r.framework_taxonomy = cr.framework_taxonomy
              AND r.framework_value    = cr.framework_value))            AS agrees,
       (SELECT count(*) FROM pm.regime r WHERE r.filing = p.part_filing
          AND r.framework_taxonomy IS NOT NULL)                          AS frameworks_the_filing_states
FROM      (
    -- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM      (
    -- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent
FROM pm.part p

) p
JOIN      (
    -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

) fi ON fi.notation = p.part_filing
-- ⛔⛔⛔ `pm.layer` DIRECTLY, AND NOT `layers/every_layer.sqlc`, WHICH IS THE WHOLE POINT OF THIS
--    LINE. This is a MEMBERSHIP test: does the layer this reference names exist. That relation is
--    the layer DIMENSION, reserved for denominators, and composing it here dragged the entire
--    dimension into the transitive closure of two thirds of the checker. Measured: 20 of 29 rules
--    reached `every_layer` through this one edge, and 1 does without it. ⛔ Any reach-containment
--    law over a rule is vacuous the moment the dimension is inside its closure, because the
--    dimension reaches everything by construction. `layers/every_layer.sqlc`'s own header now
--    carries the rule and `algebra/dimension_use.sqlc` enforces it over the compose DAG.
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer

) p
JOIN pm.composition_regime cr
  ON cr.composition = p.composition AND cr.id = p.part_regime
 ) r
               WHERE r.composer_absent IS NOT NULL OR r.frameworks_the_filing_states = 0) AS unaskable
         ) x
) p ON true
WHERE a.slug = 'part_regimes'
