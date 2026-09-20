-- asrt:Part/asrt:factor applied to each quantity the part layer states.
SELECT p.composition, p.composed_layer, p.part_filing, p.part_layer, s.quantity,
       least(   s.low  * coalesce(p.factor_low, 1), s.low  * coalesce(p.factor_high, 1)) AS low,
       s.mode * coalesce(p.factor_mode, 1)                                               AS mode,
       greatest(s.high * coalesce(p.factor_low, 1), s.high * coalesce(p.factor_high, 1)) AS high
FROM      (
    SELECT * FROM composition.parts
) p
JOIN      (
    SELECT * FROM composition.resolved_quantities
) s
       ON s.filing = p.part_filing AND s.layer = p.part_layer
  AND s.low IS NOT NULL
  AND p.factor_state IN ('omitted', 'stated')
