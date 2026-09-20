-- composition/parts.sqlc against layers/lumpy.sqlc, converted by asrt:factor and folded by gcd, over every part in composition/part_references.sqlc.
WITH RECURSIVE base AS (
    SELECT p.composition, p.composed_layer,
           CASE WHEN p.factor_state = 'stated' THEN c.n_unit ELSE l.quantum_unit END AS quantum_unit,
           CASE WHEN p.factor_state IN ('omitted', 'stated')
                THEN l.quantum_mode * coalesce(p.factor_mode, 1) END             AS quantum_mode,
           coalesce(p.factor_low <> p.factor_high, false)                         AS spread,
           p.factor_absent, p.factor_derivation
    FROM      (
        SELECT * FROM composition.parts
    ) p
    JOIN      (
        SELECT * FROM layers.lumpy
    ) l ON l.filing = p.part_filing AND l.layer = p.part_layer
    LEFT JOIN (
        SELECT * FROM layers.nameplate
    ) c ON c.filing = p.composition AND c.layer = p.composed_layer
    WHERE l.quantum_mode > 0
),
every_part AS (
    SELECT p.composition, p.composed_layer, p.parts
    FROM (
        SELECT * FROM folds.fusion_parts
    ) p
),
shape AS (
    SELECT composition, composed_layer,
           count(*)                                         AS lumpy_parts,
           count(quantum_mode)                              AS sized,
           count(DISTINCT quantum_unit)                     AS units,
           min(quantum_unit)                                AS unit,
           bool_or(spread)                                  AS spread,
           min(factor_absent)                               AS unsized,
           min(factor_derivation)                           AS unsized_by
    FROM base GROUP BY composition, composed_layer
),
ordered AS (
    SELECT b.*, row_number() OVER (PARTITION BY b.composition, b.composed_layer
                                   ORDER BY b.quantum_unit, b.quantum_mode) AS i
    FROM base b
    WHERE b.quantum_mode IS NOT NULL
),
fold AS (
    SELECT composition, composed_layer, i, quantum_mode AS g FROM ordered WHERE i = 1
  UNION ALL
    SELECT o.composition, o.composed_layer, o.i, gcd(f.g, o.quantum_mode)
    FROM fold f
    JOIN ordered o ON o.composition    = f.composition
                  AND o.composed_layer = f.composed_layer
                  AND o.i              = f.i + 1
)
SELECT s.composition, s.composed_layer, e.parts, s.units, s.spread,
       CASE WHEN s.unsized IS NULL AND s.unsized_by IS NULL AND s.units = 1 THEN s.unit END
           AS unit,
       CASE WHEN s.unsized IS NULL AND s.unsized_by IS NULL AND s.units = 1 THEN f.g END
           AS composed_quantum,
       CASE WHEN s.unsized IS NOT NULL THEN s.unsized
            WHEN s.unsized_by IS NULL AND s.units > 1 THEN 'notApplicable'::pm.absence_reason END
           AS absent,
       s.unsized_by AS factor_derivation
FROM      shape      s
JOIN      every_part e ON e.composition = s.composition
                      AND e.composed_layer = s.composed_layer
                      AND e.parts = s.lumpy_parts
LEFT JOIN fold       f ON f.composition = s.composition
                      AND f.composed_layer = s.composed_layer
                      AND f.i = s.sized
