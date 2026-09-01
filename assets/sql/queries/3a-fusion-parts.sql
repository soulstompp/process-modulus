-- §3  The parts going into each composed layer, with their conversion factors.
--
-- This is `F` and `Φ` in one result set: each row is an incidence entry (this part composes
-- into that layer) carrying the factor that puts it in the composed layer's unit. A part
-- with no factor converts by one, which is what the `coalesce` says.
--
-- ⛔ ABSENT MEANS ONE, EXACTLY, AND NEVER "UNKNOWN" — see `asrt:Part`. A conversion nobody
-- measured is a typed absence inside the claim, which is a different document from a part
-- with no factor at all, and `coalesce` here is reading the second.
SELECT p.composition                   AS "composition!",
       p.composed_layer                AS "composed!",
       coalesce(p.factor_low, 1)::float8  AS "f_low!",
       coalesce(p.factor_mode, 1)::float8 AS "f_mode!",
       coalesce(p.factor_high, 1)::float8 AS "f_high!",
       l.demand_low::float8            AS "d_low!",
       l.demand_mode::float8           AS "d_mode!",
       l.demand_high::float8           AS "d_high!"
FROM pm.part p
JOIN pm.filing_identity fi ON fi.notation = p.part_filing
JOIN pm.layer l ON l.filing = fi.filing AND l.layer = p.part_layer
WHERE l.demand_low IS NOT NULL
ORDER BY p.composition, p.composed_layer, p.part_layer
