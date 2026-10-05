-- epistemics/derivations.sqlc against epistemics/filed_derivations.sqlc, through identities/roster.sqlc.
WITH algebra_roster AS (
-- the set-algebraic laws this tree's relations claim to obey.
SELECT * FROM (VALUES
  ('decomposition',    '|E| = Σ_filing |E_filing|',  'rank/decomposition',               'partition',  'bag: one edge counted in both scopes'),
  ('compose_decomposition','|N| = Σ_dir |N_dir|, |E| = Σ_dir |E_dir| + crossing', 'rank/compose_decomposition', 'partition', 'set: a template is in exactly one directory'),
  ('cycle_space',      'dim ker B = 0 ⟺ |jagged| = 0','rank/cycle_space',                 'value',      'set: one row, the layer graph against its rule'),
  ('composition_kernel','dim ker F Φ = m − |fusions|','rank/composition_kernel',        'value',      'set: one row, the fusion fold against the layer graph'),
  ('composition_row_space','dim row ⊕ dim ker = parts, per fibre; Σ dim row = rank', 'rank/composition_row_space', 'value', 'set: one row per fusion, folded to two subjects'),
  ('composition_image', '|declared| = rank + dim ker (F Φ)ᵀ, and the left null is empty', 'rank/composition_image', 'value', 'set: one row per composition'),
  ('composition_closure','dim ker Ψ = Σ dim ker over the levels = |leaves| − 1, and Ψ''s own row is positive', 'rank/composition_closure', 'value', 'set: one row per fusion taken as a root'),
  ('dimension_use',    'parents(dimension) ⊆ declared', 'algebra/dimension_use',         'roster',     'set: one row per undeclared parent'),
  ('owed_equality',    '|A| = |A∖B| + |A⋉B|',        'composition/owed_equality',        'difference', 'set'),
  ('leaves',           '|A| = |A∖B| + |A⋉B|',        'composition/leaves',               'difference', 'bag: dedup would be a defect'),
  ('jagged_layers',    '|A| = |A∖B| + |A⋉B|',        'queries/observations/14-jagged-layers','difference','bag: one row per doubled layer'),
  ('composed_quantities','|A| = |A∖B| + |A⋉B|',      'queries/matrices/3b-composed-quantities','difference','set'),
  ('integrity',        '|A| = |A∖B| + |A⋉B|',        'reports/integrity',                'difference', 'bag: dedup intended'),
  ('carried',          '|A| = |A∖B| + |A⋉B|',        'composition/carried',              'difference', 'bag: anti-join preserves it'),
  ('owed_remainder',   '|A| = |A∖B| + |A⋉B|',        'composition/owed_remainder',       'difference', 'set'),
  ('settled_remainders','|A| = |A∖B| + |A⋉B|',       'composition/settled_remainders',   'difference', 'bag: one row per path'),
  ('unresolved_parts', '|A| = |A∖B| + |A⋉B|',        'composition/unresolved_parts',     'difference', 'set: pm.part''s key'),
  ('remainder_in_force','|A| = |A∖B| + |A⋉B|',       'layers/remainder',                 'difference', 'set: one row per layer'),
  ('borne',            'Σall = Σkept + Σremoved',    'entries/borne',                    'additive',   'bag: γ over holders'),
  ('arithmetic_class', 'each candidate in exactly one class', 'arithmetic/all',          'partition',  'set'),
  ('remainder_standing','each remainder in exactly one standing','layers/remainder_scope','partition',  'set'),
  ('exposure_standing', 'each exposed layer in exactly one standing','layers/exposure_scope','partition','set'),
  ('searches',         '|A ⊎ B| = |A| + |B|',        'epistemics/searches',              'union',      'bag: UNION ALL'),
  ('part_regimes',     '|A| = |A∖B| + |A⋉B|',        'checks/part_regime_disagrees',     'difference', 'set: pm.part''s key'),
  ('crossed_remainder','r = [n_low − d_high, n_mode − d_mode, n_high − d_low]', 'layers/remainder', 'value', 'set: one row per remainder'),
  ('exposure',         'exposure = max(−r_low, 0)',  'layers/remainder',                 'value',      'set: one row per remainder'),
  ('remainder_decomposes','r = m·q − (d mod q)',     'layers/decomposed',                'value',      'set: one row per lumpy remainder'),
  ('sawtooth',         'one tooth ⇒ residues ordered', 'layers/decomposed',              'value',      'set: one row per demand inside one tooth'),
  ('composed_quantum', 'g divides the composed nameplate', 'composition/composed_quantum', 'value',     'set: one row per composed layer with a quantum'),
  ('fusion_sum',       'x_composed = F Φ x_parts − e, per quantity', 'composition/fused',   'value',      'set: one row per owed fusion quantity'),
  ('composed_remainder','r = F Φ r_parts − e_n + e_d, inside n − d', 'composition/fused_remainders', 'value', 'set: one row per owed composed remainder'),
  ('derived_quantities','x_derived = F Φ x_parts − e, one level at a time', 'composition/derived_quantities', 'value', 'set: one row per figure filed as its fusion''s sum'),
  ('conforms',         'no loaded document violates a rule', 'checks/all',               'conformance', 'set: one row per rule'),
  ('fit_domain',       'axis ⇔ closure reaches the fit; exercised ⇔ examined > 0', 'reports/fit_coverage', 'roster', 'set: one row per rule'),
  ('absences_filed',   'census(columns) = census(elements), per filing, group and reason', 'epistemics/absences', 'roster', 'set: one row per group of positions'),
  ('derivations_filed', 'census(columns) = census(elements), per filing, position and identity', 'epistemics/derivations', 'roster', 'set: one row per position'),
  ('fusions_have_parts', 'parts → fusions is onto: no fusion names no part; Σ parts = |references|', 'folds/fusion_parts', 'partition', 'set: one row per composition'),
  ('searches_answered', 'each search: entries filed ⇔ no reason typed', 'epistemics/searches', 'partition', 'set: one row per search'),
  ('subject_boxes',    'rows = Σ boxes per subject; Σ rows = |population|', 'folds/contract_subjects', 'partition', 'bag: a population counted into its subjects'),
  ('factor_state',     'each part in the factor state its columns file', 'composition/part_references', 'partition', 'set: pm.part''s key'),
  ('fusion_quantities', '|A| = |A∖B| + |A⋉B|',       'composition/fusion_quantities',    'difference', 'set: one row per layer and quantity'),
  ('part_sums',        'Σ over fusions of Σ parts = Σ parts', 'folds/part_sums',           'additive',   'bag: every part counted'),
  ('suspended_quantities', '|A| = |A∖B| + |A⋉B|',   'composition/suspended_quantities', 'difference', 'set: one row per fusion and quantity'),
  ('unsized_conversions_are_unsettled', 'π(A) ⊆ B: a conversion nobody could size cannot be differenced', 'composition/unsized_conversions', 'containment', 'set: one row per composed layer'),
  ('part_quantities',  '|A| = |A∖B| + |A⋉B|',        'composition/part_quantities',      'difference', 'set: one row per part and quantity'),
  ('figures',          '|D ∪ N| = |D| + |N| − |D ∩ N|', 'layers/figures',                  'union',      'set: one row per layer'),
  ('served_totals',    'Σheld = Σserved + Σunserved, per layer', 'folds/served_totals',     'additive',   'bag: γ over holders'),
  ('layer_units',      'a pin is the whole relation: the payload constant on the key, the pinned value reaching it', 'units/conversions', 'dependency', 'set: one row per condition'),
  ('class_domain',     'every class of every declared codomain stands where its count puts it', 'epistemics/class_domain', 'roster',     'set: one row per condition')
) AS a(slug, law, governs, form, multiplicity)
),
layers_summed_quantities AS (
-- pm:Layer/pm:Demand, pm:Nameplate/pm:amount and pm:Jagged/pm:draw, one row per quantity.
SELECT l.filing, l.layer, 'demand'::pm.summed_quantity AS quantity,
       l.demand_low AS low, l.demand_mode AS mode, l.demand_high AS high, l.demand_unit AS unit,
       l.demand_absent AS absent, l.demand_derivation AS derivation
FROM pm.layer l
UNION ALL
SELECT n.filing, n.layer, 'nameplate'::pm.summed_quantity,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_derivation
FROM pm.nameplate n
UNION ALL
SELECT n.filing, n.layer, 'draw'::pm.summed_quantity,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent, n.draw_derivation
FROM pm.nameplate n
),
layers_filed_remainders AS (
-- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value, l.absorber_absent,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent,
       l.sign_derivation, l.qty_derivation
FROM pm.layer l
WHERE l.remainder_absent IS NULL
),
entries_slacks AS (
-- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names are the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.derivation
FROM pm.slack s
),
entries_holders AS (
-- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of, h.share_derivation
FROM pm.holder h
),
epistemics_claims AS (
-- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.prov_entered_by, c.prov_approved_by, c.prov_note, c.as_of,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent,
       n.derivation   AS narrows_derivation,
       b.derivation   AS origin_derivation
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)
),
epistemics_claim_derivations AS (
-- pm:Claim/pm:boundOrigin and pm:Claim/pm:narrowsWhen taking their pm:derivation branch, at the claim's own position.
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:boundOrigin' AS element,
       c.origin_derivation AS identity
FROM (
    SELECT * FROM epistemics_claims
) c
WHERE c.origin_derivation IS NOT NULL
UNION ALL
SELECT c.filing, c.seq, c.layer, c.owns, 'pm:claim/pm:narrowsWhen', c.narrows_derivation
FROM (
    SELECT * FROM epistemics_claims
) c
WHERE c.narrows_derivation IS NOT NULL
),
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
composition_part_references AS (
-- asrt:Composition/asrt:Fusion/asrt:Part, keyed by pm:ForeignId (notation + id).
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       CASE WHEN p.factor_low        IS NOT NULL THEN 'stated'::public.factor_state
            WHEN p.factor_absent     IS NOT NULL THEN 'absent'::public.factor_state
            WHEN p.factor_derivation IS NOT NULL THEN 'derivation'::public.factor_state
            ELSE                                      'omitted'::public.factor_state END AS factor_state,
       p.part_party, p.part_registration_taxonomy, p.part_registration_value, p.part_version
FROM pm.part p
),
epistemics_derivations AS (
-- every pm:derivation/identity in the schema, from every column that keeps one.
SELECT filing, subject, owns, coalesce(element, owns) AS element, identity FROM (
    SELECT filing, layer AS subject, 'pm:demand/pm:amount' AS owns, NULL::text AS element,
           derivation AS identity FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'pm:nameplate/pm:amount', NULL, derivation FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'pm:jagged/pm:draw', NULL, derivation FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:sign', NULL, sign_derivation FROM (
        SELECT * FROM layers_filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'pm:remainder/pm:quantity', NULL, qty_derivation FROM (
        SELECT * FROM layers_filed_remainders
    ) fr
    UNION ALL SELECT filing, layer || ' / ' || buffer::text,
                     CASE s.buffer WHEN 'time'     THEN 'pm:layer/pm:timeSlack'
                                   WHEN 'capacity' THEN 'pm:nameplate/pm:capacitySlack'
                                   ELSE 'pm:nameplate/pm:inventorySlack' END,
                     NULL, derivation FROM (
        SELECT * FROM entries_slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text, 'pm:holder/pm:share', NULL, share_derivation FROM (
        SELECT * FROM entries_holders
    ) h
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, owns, element, identity FROM (
        SELECT * FROM epistemics_claim_derivations
    ) c
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'asrt:elimination/asrt:quantity', NULL, derivation FROM (
        SELECT * FROM eliminations_filed
    ) e
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'asrt:part/asrt:factor', NULL, factor_derivation FROM (
        SELECT * FROM composition_part_references
    ) pr
) d
WHERE identity IS NOT NULL
),
epistemics_filed_derivations AS (
-- pm:Derivation and its restrictions, every one, with pm:note, pm:asOf and pm:provenance.
SELECT d.filing, d.seq, coalesce(d.claim_owns, d.owns) AS owns, d.owns AS element, d.layer,
       d.identity, d.note, d.as_of,
       d.prov_party, d.prov_entered_by, d.prov_approved_by,
       d.prov_standing_taxonomy, d.prov_standing_value, d.prov_standing_absent, d.prov_note
FROM pm.derivation d
),
identities_roster AS (
-- pm:Identity against every *Derivation restriction in the two schemas, per position and arm.
SELECT * FROM (VALUES
  ('fusionSum',      'pm:demand/pm:amount',            'pm:demand/pm:amount',            'layer',        'demand_derivation', 'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:nameplate/pm:amount',         'nameplate',    'amount_derivation', 'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:jagged/pm:draw',              'nameplate',    'draw_derivation',   'as the search says', 'the composer', 'composition/derived_quantities'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'asrt:elimination/asrt:quantity', 'elimination',  'derivation',        'as the search says', 'the composer', 'eliminations/unsized'),
  ('fusionSum',      'asrt:part/asrt:factor',          'asrt:part/asrt:factor',          'part',         'factor_derivation', 'as the search says', 'the composer', 'composition/unsized_conversions'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:remainder/pm:quantity',       'layer',        'qty_derivation',    'binds',   'the model',    'layers/remainder'),
  ('fit',            'pm:remainder/pm:sign',           'pm:remainder/pm:sign',           'layer',        'sign_derivation',   'binds',   'the model',    'layers/remainder'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:layer/pm:timeSlack',          'slack',        'derivation',        'defines', 'the model',    'arithmetic/time_slack_derived'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:holder/pm:share',             'holder',       'share_derivation',  'binds',   'the model',    'arithmetic/shares_sum'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'asrt:elimination/asrt:quantity', 'elimination',  'derivation',        'binds',   'the model',    'eliminations/unsized'),
  ('conversionPath', 'asrt:part/asrt:factor',          'asrt:part/asrt:factor',          'part',         'factor_derivation', 'binds',   'the model',    'composition/unsized_conversions'),
  ('fusionSum',      'pm:demand/pm:amount',            'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'asrt:part/asrt:factor',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('conversionPath', 'asrt:part/asrt:factor',          'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('amountOrigin',   'pm:nameplate/pm:amount',         'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('quantumOrigin',  'pm:lumpy/pm:size',               'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('quantumOrigin',  'pm:quantum/pm:size',             'pm:claim/pm:boundOrigin',        'bound_origin', 'derivation',        'defines', 'the model',    'epistemics/edges'),
  ('fusionSum',      'pm:demand/pm:amount',            'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'pm:nameplate/pm:amount',         'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'pm:jagged/pm:draw',              'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'asrt:elimination/asrt:quantity', 'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('fusionSum',      'asrt:part/asrt:factor',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('magnitude',      'pm:remainder/pm:quantity',       'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('clearance',      'pm:layer/pm:timeSlack',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('sharesSum',      'pm:holder/pm:share',             'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('sharedParts',    'asrt:elimination/asrt:quantity', 'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths'),
  ('conversionPath', 'asrt:part/asrt:factor',          'pm:claim/pm:narrowsWhen',        'narrowing',    'derivation',        'defines', 'the model',    'epistemics/widths')
) AS r(identity, owns, element, table_name, column_name, binds, origin, handled_by)
)
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    WITH counted AS (
        SELECT c.owns, c.element, c.filing, c.identity, count(*) AS n
        FROM (
            SELECT * FROM epistemics_derivations
        ) c
        GROUP BY c.owns, c.element, c.filing, c.identity
    ),
    filed AS (
        SELECT f.owns, f.element, f.filing, f.identity, count(*) AS n
        FROM (
            SELECT * FROM epistemics_filed_derivations
        ) f
        GROUP BY f.owns, f.element, f.filing, f.identity
    ),
    cells AS (
        SELECT coalesce(c.owns, f.owns) AS owns, coalesce(c.element, f.element) AS element,
               coalesce(c.filing, f.filing) AS filing, coalesce(c.identity, f.identity) AS identity,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.owns = c.owns AND f.element = c.element AND f.filing = c.filing
                         AND f.identity = c.identity
    ),
    positions AS (
        SELECT DISTINCT r.owns, r.element
        FROM (
            SELECT * FROM identities_roster
        ) r
    )
    SELECT CASE WHEN q.element = q.owns THEN q.owns ELSE q.element || ' at ' || q.owns END AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing,
                                                     x.identity, x.filed, x.counted),
                                              '; ' ORDER BY x.filing, x.identity)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM positions q
    LEFT JOIN cells x ON x.owns = q.owns AND x.element = q.element
    GROUP BY q.owns, q.element
    UNION ALL
    SELECT 'pairs the roster does not admit',
           count(*) = 0,
           format('%s derivation(s) at a cell identities/roster.sqlc does not list%s', count(*),
                  coalesce(': ' || string_agg(DISTINCT f.element || ' at ' || f.owns || ' ' || f.identity::text, ', '), ''))
    FROM (
        SELECT * FROM epistemics_filed_derivations
    ) f
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT * FROM identities_roster
        ) r
        WHERE r.owns = f.owns AND r.element = f.element AND r.identity = f.identity::text
    )
) p ON true
WHERE a.slug = 'derivations_filed'
