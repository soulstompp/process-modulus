-- epistemics/absences.sqlc against epistemics/filed_absences.sqlc, through epistemics/absence_positions.sqlc.
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
epistemics_absence_positions AS (
-- The XSD's Stated* wrapper positions in the documents ingest loads, against epistemics/absences.sqlc's questions.
SELECT * FROM (VALUES
  ('pm:processModulus/pm:notation',     'its own notation',                       NULL::text),
  ('pm:processModulus/pm:evidence',     'what it is evidence for',                NULL),
  ('pm:stack/pm:scope',                 'how much of the system',                 NULL),
  ('pm:stack/pm:couplings',             'did anybody look for couplings',         NULL),
  ('pm:regime/pm:framework',            'regime framework',                       NULL),
  ('pm:regime/pm:chart',                'regime chart',                           NULL),
  ('asrt:regime/pm:framework',          'part regime framework',                  NULL),
  ('asrt:regime/pm:chart',              'part regime chart',                      NULL),
  ('asrt:provenance/pm:standing',       'assertion standing',                     NULL),
  ('pm:provenance/pm:standing',         'provenance standing',                    NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on an absence',     NULL),
  ('pm:provenance/pm:standing',         'provenance standing, on a derivation',   NULL),
  ('pm:claim/pm:narrowsWhen',           'narrowsWhen',                            NULL),
  ('pm:claim/pm:boundOrigin',           'boundOrigin',                            NULL),
  ('pm:claim/pm:denominator',           'denominator',                            NULL),
  ('pm:coupling/pm:strength',           'coupling strength',                      NULL),
  ('pm:operation/pm:notationPosition',  'where the operation is in a notation',   NULL),
  ('pm:draw/pm:quantity',               'operation draw',                         NULL),
  ('pm:induces/pm:commitment',          'operation induction',                    NULL),
  ('pm:demand/pm:amount',               'demand',                                 NULL),
  ('pm:demand/pm:patience',             'patience',                               NULL),
  ('pm:layer/pm:timeSlack',             'buffer slack',                           NULL),
  ('pm:nameplate/pm:capacitySlack',     'buffer slack',                           NULL),
  ('pm:nameplate/pm:inventorySlack',    'buffer slack',                           NULL),
  ('pm:layer/pm:remainder',             'remainder',                              NULL),
  ('pm:remainder/pm:sign',              'remainder sign',                         NULL),
  ('pm:remainder/pm:absorber',          'remainder absorber',                     NULL),
  ('pm:remainder/pm:quantity',          'remainder quantity',                     NULL),
  ('pm:holder/pm:share',                'holder share',                           NULL),
  ('pm:nameplate/pm:amount',            'nameplate amount',                       NULL),
  ('pm:nameplate/pm:amountOrigin',      'who committed the amount',               NULL),
  ('pm:nameplate/pm:divisibility',      'divisibility',                           NULL),
  ('pm:divisibility/pm:window',         'duty-cycle window',                      NULL),
  ('pm:lumpy/pm:size',                  'lump size',                              NULL),
  ('pm:quantum/pm:size',                'duty-cycle period',                      NULL),
  ('pm:jagged/pm:draw',                 'draw',                                   NULL),
  ('pm:jagged/pm:measurementBasis',     'measurement basis',                      NULL),
  ('asrt:fusion/asrt:eliminations',     'did anybody look for double counting',   NULL),
  ('asrt:elimination/asrt:quantity',    'eliminated quantity',                    NULL),
  ('asrt:part/asrt:factor',             'part factor',                            NULL),
  ('pm:continuous/pm:premium',          NULL,
   'a premium is a claim nothing reads, so it has no columns of its own: its value is in claim and its absence here alone'),
  ('pm:remainder/pm:holder',            NULL,
   'a holder that is typed absent has no row in holder, whose rows are the holders that bear a share')
) AS p(owns, question, why_no_column)
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
layers_facilities AS (
-- pm:Layer/pm:supply, pm:Facility with its pm:Nameplate and pm:Jagged, one row per layer.
SELECT n.filing, n.layer, n.facility_label,
       n.amount_low, n.amount_mode, n.amount_high, n.amount_unit, n.amount_absent,
       n.amount_origin, n.amount_origin_absent,
       n.lumpy, n.divisibility_absent,
       n.quantum_low, n.quantum_mode, n.quantum_high, n.quantum_unit, n.quantum_absent,
       n.quantum_origin,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_origin, n.window_absent,
       n.draw_low, n.draw_mode, n.draw_high, n.draw_unit, n.draw_absent,
       n.measurement_basis_contributed, n.measurement_basis_taxonomy, n.measurement_basis_value,
       n.measurement_basis_absent
FROM pm.nameplate n
),
layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
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
entries_draws AS (
-- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d
),
entries_inductions AS (
-- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n
),
entries_operations AS (
-- pm:Operation, keyed (filing, label), with the notation position or the reason there is none.
SELECT o.filing, o.label, o.foreign_notation, o.foreign_id, o.foreign_absent::text AS foreign_absent
FROM pm.operation o
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
epistemics_scopes AS (
-- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss
),
epistemics_coupling_searches AS (
-- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs
),
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
eliminations_searched AS (
-- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es
),
eliminations_filed AS (
-- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.derivation, e.reason, e.claim_seq
FROM pm.elimination e
),
layers_denied_remainders AS (
-- pm:Layer/pm:remainder taking the pm:absent branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.remainder_absent      AS reason,
       l.remainder_absent_note AS argument
FROM pm.layer l
WHERE l.remainder_absent IS NOT NULL
),
layers_patience AS (
-- pm:Demand/pm:patience, beside the demand it qualifies.
SELECT l.filing, l.layer,
       l.patience_low, l.patience_mode, l.patience_high, l.patience_unit,
       l.patience_absent,
       l.demand_unit
FROM pm.layer l
),
epistemics_filed_absences AS (
-- pm:Absence and pm:ClaimAbsence, every one, with pm:note, pm:asOf and pm:provenance.
SELECT a.filing, a.seq, a.owns, a.layer, a.reason, a.note, a.as_of,
       a.prov_party, a.prov_entered_by, a.prov_approved_by,
       a.prov_standing_taxonomy, a.prov_standing_value, a.prov_standing_absent, a.prov_note
FROM pm.absence a
),
epistemics_filed_derivations AS (
-- pm:Derivation and its restrictions, every one, with pm:note, pm:asOf and pm:provenance.
SELECT d.filing, d.seq, coalesce(d.claim_owns, d.owns) AS owns, d.owns AS element, d.layer,
       d.identity, d.note, d.as_of,
       d.prov_party, d.prov_entered_by, d.prov_approved_by,
       d.prov_standing_taxonomy, d.prov_standing_value, d.prov_standing_absent, d.prov_note
FROM pm.derivation d
),
entries_couplings AS (
-- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c
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
composition_regimes AS (
-- pm:Regime, one row per declaration in document order.
SELECT r.filing, r.seq, r.id, r.jurisdiction,
       r.framework_taxonomy, r.framework_value, r.framework_absent,
       r.chart_taxonomy, r.chart_value, r.chart_absent
FROM pm.regime r
),
composition_composer_regimes AS (
-- asrt:regime at the root of an asrt:composition, one row per declaration in document order.
SELECT r.composition, r.seq, r.id, r.jurisdiction,
       r.framework_taxonomy, r.framework_value, r.framework_absent,
       r.chart_taxonomy, r.chart_value, r.chart_absent
FROM pm.composition_regime r
),
scope_every_filing AS (
-- from pm.filing: both evidence values, the typed reason a document gives neither, and an assertion's provenance.
SELECT f.name AS filing, f.kind, f.evidence, f.evidence_absent,
       f.prov_party, f.prov_entered_by, f.prov_approved_by,
       f.prov_standing_taxonomy, f.prov_standing_value, f.prov_standing_absent, f.prov_note
FROM pm.filing f
),
epistemics_absences AS (
-- every pm:absent/reason in the schema, from every element that admits one.
SELECT filing, subject, question, reason FROM (
    SELECT filing, layer AS subject, 'demand'              AS question, absent                AS reason FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'remainder sign',      sign_absent           FROM (
        SELECT * FROM layers_filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder quantity',  qty_absent            FROM (
        SELECT * FROM layers_filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder absorber',  absorber_absent       FROM (
        SELECT * FROM layers_filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'nameplate amount',    absent                FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'divisibility',        divisibility_absent   FROM (
        SELECT * FROM layers_facilities
    ) f
    UNION ALL SELECT filing, layer, 'who committed the amount', amount_origin_absent FROM (
        SELECT * FROM layers_facilities
    ) f
    UNION ALL SELECT filing, layer, 'lump size',           quantum_absent        FROM (
        SELECT * FROM layers_facilities
    ) f
    UNION ALL SELECT filing, layer, 'measurement basis',   measurement_basis_absent FROM (
        SELECT * FROM layers_facilities
    ) f
    UNION ALL SELECT filing, layer, 'duty-cycle window',   window_absent         FROM (
        SELECT * FROM layers_windows
    ) w
    UNION ALL SELECT filing, layer, 'duty-cycle period',   window_size_absent    FROM (
        SELECT * FROM layers_windows
    ) w
    UNION ALL SELECT filing, layer, 'draw',                absent                FROM (
        SELECT * FROM layers_summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'buffer slack',      absent    FROM (
        SELECT * FROM entries_slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text,   'holder share',      share_absent FROM (
        SELECT * FROM entries_holders
    ) h
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation draw',       absent    FROM (
        SELECT * FROM entries_draws
    ) d
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation induction',  absent    FROM (
        SELECT * FROM entries_inductions
    ) i
    UNION ALL SELECT filing, label, 'where the operation is in a notation',
                     foreign_absent::pm.absence_reason FROM (
        SELECT * FROM entries_operations
    ) o
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'narrowsWhen',      narrows_absent FROM (
        SELECT * FROM epistemics_claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'boundOrigin',      origin_absent  FROM (
        SELECT * FROM epistemics_claims
    ) c
    UNION ALL SELECT filing, '(the stack)',   'how much of the system',           absent    FROM (
        SELECT * FROM epistemics_scopes
    ) sc
    UNION ALL SELECT filing, '(the stack)',   'did anybody look for couplings',   answer    FROM (
        SELECT * FROM epistemics_coupling_searches
    ) cs
    UNION ALL SELECT filing, '(the document)', 'its own notation',                absent    FROM (
        SELECT * FROM composition_notations
    ) n
    UNION ALL SELECT composition, composed_layer, 'did anybody look for double counting', answer FROM (
        SELECT * FROM eliminations_searched
    ) es
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'eliminated quantity', absent FROM (
        SELECT * FROM eliminations_filed
    ) e
    UNION ALL SELECT filing, layer, 'remainder',                        reason           FROM (
        SELECT * FROM layers_denied_remainders
    ) dr
    UNION ALL SELECT filing, layer, 'patience',                         patience_absent  FROM (
        SELECT * FROM layers_patience
    ) pa
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'denominator',         denominator_absent   FROM (
        SELECT * FROM epistemics_claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'provenance standing', prov_standing_absent FROM (
        SELECT * FROM epistemics_claims
    ) c
    UNION ALL SELECT filing, owns || ' absence ' || seq::text, 'provenance standing, on an absence',
                     prov_standing_absent FROM (
        SELECT * FROM epistemics_filed_absences
    ) fa
    UNION ALL SELECT filing, owns || ' derivation ' || seq::text,
                     'provenance standing, on a derivation', prov_standing_absent FROM (
        SELECT * FROM epistemics_filed_derivations
    ) fd
    UNION ALL SELECT filing, from_layer || ' -> ' || to_layer, 'coupling strength', strength_absent FROM (
        SELECT * FROM entries_couplings
    ) cp
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'part factor', factor_absent FROM (
        SELECT * FROM composition_part_references
    ) pr
    UNION ALL SELECT filing,      'regime ' || id,      'regime framework',      framework_absent FROM (
        SELECT * FROM composition_regimes
    ) r
    UNION ALL SELECT filing,      'regime ' || id,      'regime chart',          chart_absent     FROM (
        SELECT * FROM composition_regimes
    ) r
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime framework', framework_absent FROM (
        SELECT * FROM composition_composer_regimes
    ) cr
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime chart',     chart_absent     FROM (
        SELECT * FROM composition_composer_regimes
    ) cr
    UNION ALL SELECT filing,      '(the document)',     'what it is evidence for', evidence_absent FROM (
        SELECT * FROM scope_every_filing
    ) f
    UNION ALL SELECT filing,      '(the document)',     'assertion standing',    prov_standing_absent FROM (
        SELECT * FROM scope_every_filing
    ) f
) a
WHERE reason IS NOT NULL
),
epistemics_absence_questions AS (
-- epistemics/absences.sqlc's arms, each against the pm column of type absence_reason it reads.
SELECT * FROM (VALUES
  ('demand',                               'layer',              'demand_absent'),
  ('remainder',                            'layer',              'remainder_absent'),
  ('remainder sign',                       'layer',              'sign_absent'),
  ('remainder quantity',                   'layer',              'qty_absent'),
  ('remainder absorber',                   'layer',              'absorber_absent'),
  ('patience',                             'layer',              'patience_absent'),
  ('nameplate amount',                     'nameplate',          'amount_absent'),
  ('divisibility',                         'nameplate',          'divisibility_absent'),
  ('lump size',                            'nameplate',          'quantum_absent'),
  ('duty-cycle period',                    'nameplate',          'window_size_absent'),
  ('measurement basis',                    'nameplate',          'measurement_basis_absent'),
  ('who committed the amount',             'nameplate',          'amount_origin_absent'),
  ('duty-cycle window',                    'nameplate',          'window_absent'),
  ('draw',                                 'nameplate',          'draw_absent'),
  ('buffer slack',                         'slack',              'absent'),
  ('holder share',                         'holder',             'share_absent'),
  ('operation draw',                       'draw',               'absent'),
  ('operation induction',                  'induction',          'absent'),
  ('where the operation is in a notation', 'operation',          'foreign_absent'),
  ('narrowsWhen',                          'narrowing',          'absent'),
  ('boundOrigin',                          'bound_origin',       'absent'),
  ('denominator',                          'claim',              'denominator_absent'),
  ('provenance standing',                  'claim',              'prov_standing_absent'),
  ('provenance standing, on an absence',   'absence',            'prov_standing_absent'),
  ('provenance standing, on a derivation', 'derivation',         'prov_standing_absent'),
  ('how much of the system',               'stack_scope',        'absent'),
  ('did anybody look for couplings',       'coupling_search',    'absent'),
  ('coupling strength',                    'coupling',           'strength_absent'),
  ('its own notation',                     'filing_identity',    'absent'),
  ('what it is evidence for',              'filing',             'evidence_absent'),
  ('assertion standing',                   'filing',             'prov_standing_absent'),
  ('did anybody look for double counting', 'elimination_search', 'absent'),
  ('eliminated quantity',                  'elimination',        'absent'),
  ('part factor',                          'part',               'factor_absent'),
  ('regime framework',                     'regime',             'framework_absent'),
  ('regime chart',                         'regime',             'chart_absent'),
  ('part regime framework',                'composition_regime', 'framework_absent'),
  ('part regime chart',                    'composition_regime', 'chart_absent')
) AS q(question, table_name, column_name)
)
SELECT a.slug AS law, p.subject, p.holds, p.detail
FROM      (
    SELECT * FROM algebra_roster
) a
LEFT JOIN (
    WITH positions AS (
        SELECT * FROM (
            SELECT * FROM epistemics_absence_positions
        ) r
    ),
    by_owns AS (
        SELECT owns, min(question) AS g FROM positions WHERE question IS NOT NULL GROUP BY owns
    ),
    by_question AS (
        SELECT p.question, min(o.g) AS g
        FROM positions p JOIN by_owns o USING (owns)
        WHERE p.question IS NOT NULL
        GROUP BY p.question
    ),
    owns_group AS (
        SELECT p.owns, min(q.g) AS g
        FROM positions p JOIN by_question q USING (question)
        GROUP BY p.owns
    ),
    counted AS (
        SELECT q.g, c.filing, c.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics_absences
        ) c
        JOIN by_question q USING (question)
        GROUP BY q.g, c.filing, c.reason
    ),
    filed AS (
        SELECT o.g, f.filing, f.reason, count(*) AS n
        FROM (
            SELECT * FROM epistemics_filed_absences
        ) f
        JOIN owns_group o USING (owns)
        GROUP BY o.g, f.filing, f.reason
    ),
    cells AS (
        SELECT coalesce(c.g, f.g) AS g, coalesce(c.filing, f.filing) AS filing,
               coalesce(c.reason, f.reason) AS reason,
               coalesce(c.n, 0) AS counted, coalesce(f.n, 0) AS filed
        FROM counted c
        FULL JOIN filed f ON f.g = c.g AND f.filing = c.filing AND f.reason = c.reason
    )
    SELECT q.g AS subject,
           coalesce(bool_and(x.counted = x.filed), true) AS holds,
           format('%s filed, %s counted%s', coalesce(sum(x.filed), 0), coalesce(sum(x.counted), 0),
                  coalesce(': ' || string_agg(format('%s %s filed %s, counted %s', x.filing, x.reason,
                                                     x.filed, x.counted), '; ' ORDER BY x.filing, x.reason)
                                   FILTER (WHERE x.counted <> x.filed), '')) AS detail
    FROM (SELECT DISTINCT g FROM by_question) q
    LEFT JOIN cells x ON x.g = q.g
    GROUP BY q.g
    UNION ALL
    SELECT 'positions the roster does not name',
           count(*) FILTER (WHERE p.owns IS NULL) = 0,
           format('%s absences at %s undeclared position(s)%s; %s at positions no column answers',
                  count(*) FILTER (WHERE p.owns IS NULL),
                  count(DISTINCT f.owns) FILTER (WHERE p.owns IS NULL),
                  coalesce(': ' || string_agg(DISTINCT f.owns, ', ') FILTER (WHERE p.owns IS NULL), ''),
                  count(*) FILTER (WHERE p.owns IS NOT NULL AND p.question IS NULL))
    FROM (
        SELECT * FROM epistemics_filed_absences
    ) f
    LEFT JOIN (SELECT owns, min(question) AS question FROM positions GROUP BY owns) p USING (owns)
    UNION ALL
    SELECT 'questions no position holds',
           count(*) = 0,
           format('%s question(s) on the census with no position%s', count(*),
                  coalesce(': ' || string_agg(q.question, ', '), ''))
    FROM (
        SELECT * FROM epistemics_absence_questions
    ) q
    WHERE q.question NOT IN (SELECT question FROM positions WHERE question IS NOT NULL)
) p ON true
WHERE a.slug = 'absences_filed'
