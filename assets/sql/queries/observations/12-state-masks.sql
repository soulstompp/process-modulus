-- §12  Every absence-bearing question as a four-bit word: n·u·a·d.
WITH layers_summed_quantities AS (
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
epistemics_state_masks AS (
-- epistemics/absences.sqlc folded to one three-bit word per question.
SELECT a.question,
       (CASE WHEN bool_or(a.reason = 'none')          THEN 'n' ELSE '.' END) ||
       (CASE WHEN bool_or(a.reason = 'unmeasured')    THEN 'u' ELSE '.' END) ||
       (CASE WHEN bool_or(a.reason = 'notApplicable') THEN 'a' ELSE '.' END) AS mask,
       count(*)                                                             AS filings,
       count(*) FILTER (WHERE a.reason = 'none')                            AS as_none
FROM (
    SELECT * FROM epistemics_absences
) a
WHERE a.reason IS NOT NULL
GROUP BY a.question
)
SELECT m.question       AS "question!",
       m.mask           AS "mask!",
       m.filings        AS "filings!",
       m.as_none        AS "as_none!"
FROM (
    SELECT * FROM epistemics_state_masks
) m
ORDER BY (m.mask LIKE 'n%') DESC, m.filings DESC, m.question
