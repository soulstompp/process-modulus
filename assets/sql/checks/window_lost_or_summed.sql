-- asrt:Part's pm:Divisibility/window against the composed pm:Layer's.
SELECT r.rule, p.filing, p.layer, p.violates, p.detail
FROM      (
    SELECT * FROM checks.roster
) r
LEFT JOIN (
    SELECT w.composition AS filing, w.composed_layer AS layer,
           (w.composed_window_low IS NULL
            OR w.composed_window_low  <> w.window_low
            OR w.composed_window_mode <> w.window_mode
            OR w.composed_window_high <> w.window_high
            OR (w.units_agree AND w.composed_window_unit <> w.window_unit)) AS violates,
           CASE WHEN w.composed_window_low IS NULL
                THEN format('the part %s/%s files a %s-%s duty cycle and the composed '
                            'layer files `%s`', w.part_filing, w.part_layer, w.window_low,
                            w.window_unit, w.composed_window_absent)
                ELSE format('composed window [%s, %s, %s] %s against a part''s [%s, %s, %s] %s, '
                            'carried and never summed',
                            w.composed_window_low, w.composed_window_mode, w.composed_window_high,
                            w.composed_window_unit, w.window_low, w.window_mode, w.window_high,
                            w.window_unit)
           END AS detail
    FROM (
        -- asrt:Part's own pm:Divisibility/window against the composed pm:Layer's.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer,
       pw.window_low, pw.window_mode, pw.window_high, pw.window_unit,
       cw.window_low    AS composed_window_low,
       cw.window_mode   AS composed_window_mode,
       cw.window_high   AS composed_window_high,
       cw.window_unit   AS composed_window_unit,
       cw.window_absent AS composed_window_absent,
       (p.factor_state = 'omitted')
           AS units_agree
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM layers.windows
) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    SELECT * FROM layers.windows
) cw
       ON cw.filing = p.composition  AND cw.layer = p.composed_layer
WHERE pw.window_low IS NOT NULL

    ) w
) p ON true
WHERE r.slug = 'window_lost_or_summed'
