-- every pm:Absent/@reason in the schema, from every element that admits one.
SELECT filing, subject, question, reason FROM (
    SELECT filing, layer AS subject, 'demand'              AS question, demand_absent         AS reason FROM pm.layer
    UNION ALL SELECT filing, layer, 'demand narrowsWhen',  demand_narrows_absent FROM pm.layer
    UNION ALL SELECT filing, layer, 'remainder sign',      sign_absent           FROM pm.layer
    UNION ALL SELECT filing, layer, 'remainder quantity',  qty_absent            FROM pm.layer
    UNION ALL SELECT filing, layer, 'nameplate amount',    amount_absent         FROM pm.nameplate
    UNION ALL SELECT filing, layer, 'divisibility',        divisibility_absent   FROM pm.nameplate
    UNION ALL SELECT filing, layer, 'duty-cycle window',   window_absent         FROM pm.nameplate
    UNION ALL SELECT filing, layer, 'draw',                draw_absent           FROM pm.nameplate
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'buffer slack',      absent    FROM pm.slack
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'who owns the bound', bound_origin_absent FROM pm.slack
    UNION ALL SELECT filing, layer || ' / ' || kind::text,   'holder share',      share_absent FROM pm.holder
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation draw',       absent    FROM pm.draw
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation induction',  absent    FROM pm.induction
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'narrowsWhen',      narrows_absent FROM (
        -- pm:Claim, with its required pm:narrowsWhen and pm:boundOrigin, joined on the claim.
SELECT c.filing, c.seq, c.owns,
       c.low, c.mode, c.high, c.unit,
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
SELECT c.filing, c.seq, c.owns,
       c.low, c.mode, c.high, c.unit,
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
    UNION ALL SELECT filing, '(the stack)',   'how much of the system',           absent    FROM pm.stack_scope
    UNION ALL SELECT filing, '(the stack)',   'did anybody look for couplings',   absent    FROM pm.coupling_search
    UNION ALL SELECT filing, '(the document)', 'its own notation',                absent    FROM pm.filing_identity
    UNION ALL SELECT composition, composed_layer, 'did anybody look for double counting', absent FROM pm.elimination_search
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'eliminated quantity', absent FROM pm.elimination
) a
WHERE reason IS NOT NULL
