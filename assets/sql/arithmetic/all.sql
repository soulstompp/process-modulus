-- arithmetic/roster.sqlc joined to each site's own population.
-- composition/resolved_quantities.sqlc's demand against its nameplate, before layers/remainder.sqlc drops either,
-- with composition/figureless_remainders.sqlc for a layer whose n - d is not its remainder.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.low IS NULL OR n.low IS NULL   THEN 'suspended'::public.arithmetic_verdict
                WHEN d.unit IS DISTINCT FROM n.unit   THEN 'not comparable'::public.arithmetic_verdict
                WHEN g.filing IS NOT NULL             THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.low IS NULL AND n.low IS NULL
                     THEN format('demand %s and nameplate %s', d.why, n.why)
                WHEN d.low IS NULL THEN format('demand %s', d.why)
                WHEN n.low IS NULL THEN format('nameplate %s', n.why)
                WHEN d.unit IS DISTINCT FROM n.unit
                     THEN format('%s against %s', d.unit, n.unit)
                WHEN g.filing IS NOT NULL
                     THEN 'a conversion with width scales both totals, and the composed remainder is lifted'
                ELSE format('both in %s', d.unit) END AS detail
    FROM      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition.resolved_quantities ) q
    ) d
    JOIN      (
        SELECT q.*, CASE WHEN q.derivation IS NOT NULL
                         THEN format('`%s` and not computable: %s', q.derivation, q.blocked_because)
                         ELSE q.absent::text END AS why
        FROM ( SELECT * FROM composition.resolved_quantities ) q
    ) n ON n.filing = d.filing AND n.layer = d.layer AND n.quantity = 'nameplate'
    LEFT JOIN (
        SELECT * FROM composition.figureless_remainders
    ) g ON g.filing = d.filing AND g.layer = d.layer
    WHERE d.quantity = 'demand'
) p ON true
WHERE a.slug = 'remainder'
UNION ALL
-- pm:Remainder/pm:holder against the layer the magnitude belongs to.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT r.filing, r.layer,
           CASE WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[r.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('%s holders, %s unstated%s', h.holders, h.unstated,
                  CASE WHEN h.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', h.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers.remainder
    ) r
    JOIN      (
        SELECT * FROM entries.holder_totals
    ) h USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_sum'
UNION ALL
-- the slack named by pm:Remainder/pm:absorber, against the served pm:Remainder/pm:holder under interference.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT s.filing, s.layer,
           CASE WHEN s.mode IS NULL                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.unstated > 0                  THEN 'suspended'::public.arithmetic_verdict
                WHEN h.share_units <> ARRAY[s.unit]  THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN s.mode IS NULL
                     THEN format('the %s buffer is %s', s.buffer, s.absent)
                WHEN h.unstated > 0
                     THEN format('%s of %s shares unstated%s, against a %s slack of %s',
                                 h.unstated, h.holders,
                                 CASE WHEN h.derived > 0
                                      THEN format(' (%s of them filed as `sharesSum`''s output, which nothing here computes)', h.derived)
                                      ELSE '' END,
                                 s.buffer, s.mode)
                ELSE format('%s shares bounded by a %s slack of %s',
                            h.holders, s.buffer, s.mode)
           END AS detail
    FROM      (
        SELECT * FROM entries.absorbing_slack
    ) s
    JOIN      (
        SELECT * FROM folds.served_totals
    ) h USING (filing, layer)
    JOIN      (
        SELECT DISTINCT r.filing, r.layer
        FROM (
            SELECT * FROM layers.pressed
        ) r
        WHERE r.sign = 'interference'
    ) x USING (filing, layer)
) p ON true
WHERE a.slug = 'shares_bounded'
UNION ALL
-- pm:Divisibility/pm:quantum against pm:Nameplate/pm:amount.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.quantum_mode IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN l.quantum_unit IS DISTINCT FROM l.amount_unit     THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.quantum_mode IS NULL THEN format('quantum %s', l.quantum_absent)
                ELSE format('%s of %s against a rating in %s',
                            l.quantum_mode, l.quantum_unit, l.amount_unit) END AS detail
    FROM (
        SELECT * FROM layers.lumpy
    ) l
) p ON true
WHERE a.slug = 'whole_multiple'
UNION ALL
-- pm:Jagged/pm:draw against pm:Nameplate/pm:amount and pm:Nameplate/pm:capacitySlack.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT d.filing, d.layer,
           CASE WHEN d.capacity_slack IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit       THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN d.capacity_slack IS NULL
                     THEN format('the capacity buffer is %s', d.capacity_absent)
                WHEN d.draw_unit IS DISTINCT FROM d.n_unit
                  OR d.capacity_unit IS DISTINCT FROM d.n_unit
                     THEN format('a draw in %s against a rating in %s and a slack in %s',
                                 d.draw_unit, d.n_unit, d.capacity_unit)
                ELSE format('draw, rating and slack all in %s', d.n_unit) END AS detail
    FROM (
        SELECT * FROM layers.drawn
    ) d
) p ON true
WHERE a.slug = 'draw_bounded'
UNION ALL
-- every slack on the layer accounted for and empty, against pm:Remainder/pm:holder of kind customer and unrealised.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT x.filing, x.layer,
           CASE WHEN u.unstated > 0                        THEN 'suspended'::public.arithmetic_verdict
                WHEN u.share_units <> ARRAY[x.unit]        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           format('exposure %s in %s against %s unserved holder(s)%s',
                  round(x.exposure, 3), x.unit, u.holders,
                  CASE WHEN u.derived > 0
                       THEN format(', %s of them filed as `sharesSum`''s output, which nothing here computes', u.derived)
                       ELSE '' END) AS detail
    FROM      (
        SELECT * FROM layers.unabsorbed_exposure
    ) x
    JOIN      (
        SELECT * FROM entries.unserved_totals
    ) u USING (filing, layer)
) p ON true
WHERE a.slug = 'exposure_bounded'
UNION ALL
-- pm:Layer/pm:timeSlack with pm:absent/reason = derived, against the clearance it stands for.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT t.filing, t.layer,
           CASE WHEN r.filing IS NULL                            THEN 'suspended'::public.arithmetic_verdict
                WHEN r.unit IS DISTINCT FROM r.amount_unit        THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN r.filing IS NULL THEN 'no demand and nameplate to take a clearance from'
                WHEN r.unit IS DISTINCT FROM r.amount_unit
                     THEN format('a demand in %s against a nameplate in %s', r.unit, r.amount_unit)
                ELSE format('the clearance [%s, %s, %s] %s is the slack',
                            greatest(r.r_low, 0), greatest(r.r_mode, 0), greatest(r.r_high, 0),
                            r.unit) END AS detail
    FROM      (
        SELECT * FROM entries.derived_time_slacks
    ) t
    LEFT JOIN (
        SELECT * FROM layers.remainder
    ) r USING (filing, layer)
) p ON true
WHERE a.slug = 'time_slack_derived'
UNION ALL
-- pm:Remainder/pm:quantity against the layer's own r = n - d.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT l.filing, l.layer,
           CASE WHEN l.qty_low IS NULL                       THEN 'suspended'::public.arithmetic_verdict
                WHEN l.qty_unit IS DISTINCT FROM l.unit      THEN 'not comparable'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           CASE WHEN l.qty_low IS NULL THEN format('the quantity is %s', l.qty_absent)
                ELSE format('filed %s %s against a derived magnitude %s %s',
                            l.qty_mode, l.qty_unit, round(l.m_mode, 3), l.unit) END AS detail
    FROM      (
        SELECT * FROM layers.filed_against_derived
    ) l
) p ON true
WHERE a.slug = 'filed_remainder'
UNION ALL
-- asrt:Fusion/asrt:Part against asrt:eliminations, via composition/owed_equality.sqlc and composition/derived_quantities.sqlc.
SELECT a.site, p.filing, p.layer, p.verdict, p.detail
FROM      (
    SELECT * FROM arithmetic.roster
) a
LEFT JOIN (
    SELECT f.filing, f.layer,
           CASE WHEN o.owed IS NULL AND d.computed IS NOT TRUE
                THEN 'suspended'::public.arithmetic_verdict
                ELSE 'computable'::public.arithmetic_verdict END AS verdict,
           concat_ws('; ',
                     CASE WHEN o.owed IS NOT NULL THEN format('owed exactly for %s', o.owed) END,
                     d.derived,
                     s.suspended) AS detail
    FROM      (
        SELECT * FROM composition.fusions
    ) f
    LEFT JOIN (
        SELECT o.filing, o.layer, string_agg(o.quantity::text, ', ' ORDER BY o.quantity) AS owed
        FROM (
            SELECT * FROM composition.owed_equality
        ) o
        GROUP BY o.filing, o.layer
    ) o USING (filing, layer)
    LEFT JOIN (
        SELECT g.composition, g.composed_layer,
               string_agg(DISTINCT format('suspended for %s: %s',
                                          coalesce(g.quantity::text, 'every quantity'),
                                          g.suspended_because), '; ') AS suspended
        FROM (
            SELECT * FROM composition.suspension_grounds
        ) g
        GROUP BY g.composition, g.composed_layer
    ) s ON s.composition = f.filing AND s.composed_layer = f.layer
    LEFT JOIN (
        SELECT d.filing, d.layer, bool_or(q.low IS NOT NULL) AS computed,
               string_agg(CASE WHEN q.low IS NOT NULL
                               THEN format('derived for %s: computed [%s, %s, %s]', d.quantity,
                                           q.low, q.mode, q.high)
                               ELSE format('derived for %s, not computable: %s', d.quantity,
                                           q.blocked_because) END,
                          '; ' ORDER BY d.quantity) AS derived
        FROM      (
            SELECT * FROM composition.derived_fusions
        ) d
        JOIN      (
            SELECT * FROM composition.derived_quantities
        ) q ON q.filing = d.filing AND q.layer = d.layer AND q.quantity = d.quantity
        GROUP BY d.filing, d.layer
    ) d ON d.filing = f.filing AND d.layer = f.layer
) p ON true
WHERE a.slug = 'fusion_sum'

