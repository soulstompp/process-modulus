-- layers/every_layer.sqlc against diagrams/lane_membership.sqlc; every lane, occupied or not.
WITH layers_every_layer AS (
-- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l
),
entries_draws AS (
-- pm:Operation/pm:Draw.
SELECT d.filing, d.operation, d.layer,
       d.low, d.mode, d.high, d.unit, d.absent
FROM pm.draw d
),
diagrams_lane_members AS (
-- entries/draws.sqlc projected to D's incidence alone; one flowNodeRef per entry.
SELECT d.filing, d.operation, d.layer
FROM (
    SELECT * FROM entries_draws
) d
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
composition_notations AS (
-- pm:processModulus/pm:notation: uri -> filing, with the party that asserted the identity.
SELECT fi.notation, fi.filing, fi.asserted_by, fi.absent
FROM pm.filing_identity fi
),
composition_parts AS (
-- pm.part joined through pm.filing_identity to pm.layer.
SELECT p.composition, p.composed_layer,
       p.part_filing AS part_notation,
       fi.filing     AS part_filing,
       p.part_layer,
       p.part_regime,
       p.factor_low, p.factor_mode, p.factor_high, p.factor_absent, p.factor_derivation,
       p.factor_state
FROM      (
    SELECT * FROM composition_part_references
) p
JOIN      (
    SELECT * FROM composition_notations
) fi ON fi.notation = p.part_filing
JOIN pm.layer l  ON l.filing = fi.filing AND l.layer = p.part_layer
),
diagrams_calls AS (
-- composition/parts.sqlc projected to F alone, with Phi dropped; one call activity per part.
SELECT p.composition, p.composed_layer, p.part_notation, p.part_filing, p.part_layer,
       (p.part_filing = p.composition) AS is_local
FROM (
    SELECT * FROM composition_parts
) p
),
diagrams_foreign_calls AS (
-- diagrams/calls.sqlc pinned to the parts that leave their own document.
SELECT c.composition, c.composed_layer, c.part_notation, c.part_filing, c.part_layer
FROM (
    SELECT * FROM diagrams_calls
) c
WHERE NOT c.is_local
),
diagrams_lane_membership AS (
-- entries/draws.sqlc and diagrams/foreign_calls.sqlc, each projected onto the lane it belongs to.
SELECT 'draw' AS node_kind, d.filing, d.layer
FROM (
    SELECT * FROM diagrams_lane_members
) d
UNION ALL
SELECT 'part', c.composition, c.composed_layer
FROM (
    SELECT * FROM diagrams_foreign_calls
) c
)
SELECT l.filing,
       l.layer,
       count(m.node_kind) > 0 AS occupied
FROM      (
    SELECT * FROM layers_every_layer
) l
LEFT JOIN (
    SELECT * FROM diagrams_lane_membership
) m ON m.filing = l.filing AND m.layer = l.layer
GROUP BY l.filing, l.layer
