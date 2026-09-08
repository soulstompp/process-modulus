-- §6  What the fixtures decline to answer, which is the whole reason they exist.
-- reports/absences_in_the_fixtures.sqlc, given the caller that makes it readable.
SELECT a.question AS "question!", a.reason::text AS "reason!", a.times AS "times!"
FROM (
    -- reports/absence_census.sqlc at fixture scope.
-- epistemics/absences.sqlc, restricted by the caller's @scope.
SELECT a.question, a.reason, count(*) AS times
FROM (
    -- every pm:absent/reason in the schema, from every element that admits one.
SELECT filing, subject, question, reason FROM (
    SELECT filing, layer AS subject, 'demand'              AS question, demand_absent         AS reason FROM pm.layer
    UNION ALL SELECT filing, layer, 'demand narrowsWhen',  demand_narrows_absent FROM pm.layer
    UNION ALL SELECT filing, layer, 'remainder sign',      sign_absent           FROM (
        -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent
FROM pm.layer l
WHERE l.remainder_absent IS NULL

    ) fr
    UNION ALL SELECT filing, layer, 'remainder quantity',  qty_absent            FROM (
        -- pm:Layer/pm:remainder taking the pm:claim branch of pm:StatedRemainder.
SELECT l.filing, l.layer,
       l.sign, l.sign_absent,
       l.absorber_taxonomy, l.absorber_value,
       l.qty_low, l.qty_mode, l.qty_high, l.qty_unit, l.qty_absent
FROM pm.layer l
WHERE l.remainder_absent IS NULL

    ) fr
    UNION ALL SELECT filing, layer, 'nameplate amount',    amount_absent         FROM pm.nameplate
    UNION ALL SELECT filing, layer, 'divisibility',        divisibility_absent   FROM pm.nameplate
    UNION ALL SELECT filing, layer, 'duty-cycle window',   window_absent         FROM (
        -- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_absent,
       n.amount_unit
FROM pm.nameplate n

    ) w
    UNION ALL SELECT filing, layer, 'draw',                draw_absent           FROM pm.nameplate
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'buffer slack',      absent    FROM (
        -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

    ) s
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'who owns the bound', bound_origin_absent FROM (
        -- pm:Layer/pm:timeSlack with pm:Nameplate/pm:capacitySlack and pm:inventorySlack; the element names ARE the kinds.
SELECT s.filing, s.layer, s.buffer,
       s.low, s.mode, s.high, s.unit, s.absent,
       (s.low IS NOT NULL) AS sized,
       s.bound_origin, s.bound_origin_absent
FROM pm.slack s

    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text,   'holder share',      share_absent FROM (
        -- pm:Remainder/pm:holder; kind is pm:HolderKind.
SELECT h.filing, h.layer, h.kind,
       h.share_low, h.share_mode, h.share_high, h.share_unit, h.share_absent,
       h.party, h.as_of
FROM pm.holder h

    ) h
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation draw',       absent    FROM (
        -- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d

    ) d
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation induction',  absent    FROM (
        -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

    ) i
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'narrowsWhen',      narrows_absent FROM (
        -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)

    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'boundOrigin',      origin_absent  FROM (
        -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns, c.layer,
       c.low, c.mode, c.high, c.unit,
       c.denominator, c.denominator_kind, c.denominator_absent,
       c.prov_party, c.prov_standing_taxonomy, c.prov_standing_value, c.prov_standing_absent,
       c.low = c.high AS is_a_point,
       n.condition    AS narrows_condition,
       n.kind         AS narrows_kind,
       n.absent       AS narrows_absent,
       b.origin,
       b.absent       AS origin_absent
FROM pm.claim c
JOIN pm.narrowing    n USING (filing, seq)
JOIN pm.bound_origin b USING (filing, seq)

    ) c
    UNION ALL SELECT filing, '(the stack)',   'how much of the system',           absent    FROM (
        -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

    ) sc
    UNION ALL SELECT filing, '(the stack)',   'did anybody look for couplings',   answer    FROM (
        -- pm:Stack/pm:couplings/pm:absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

    ) cs
    UNION ALL SELECT filing, '(the document)', 'its own notation',                absent    FROM (
        -- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi

    ) n
    UNION ALL SELECT composition, composed_layer, 'did anybody look for double counting', answer FROM (
        -- asrt:Fusion/asrt:eliminations/asrt:absent, one row per composed layer asked.
SELECT es.composition, es.composed_layer, es.absent AS answer, es.note
FROM pm.elimination_search es

    ) es
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'eliminated quantity', absent FROM (
        -- asrt:Fusion/asrt:eliminations/asrt:elimination, per composed layer and quantity.
SELECT e.composition, e.composed_layer, e.quantity,
       e.low, e.mode, e.high, e.unit,
       e.absent, e.reason
FROM pm.elimination e

    ) e
) a
WHERE reason IS NOT NULL

) a
JOIN (
    -- from pm.filing where evidence = 'stipulation'; see assets/fixtures/README.md.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'stipulation'

) s USING (filing)
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2


) a
ORDER BY a.times DESC, a.question
