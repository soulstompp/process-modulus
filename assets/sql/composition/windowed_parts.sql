-- asrt:Part's own pm:Divisibility/window against the composed pm:Layer's.
WITH composition_part_references AS (
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
layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
)
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
    SELECT * FROM composition_parts
) p
JOIN      (
    SELECT * FROM layers_windows
) pw
       ON pw.filing = p.part_filing  AND pw.layer = p.part_layer
JOIN      (
    SELECT * FROM layers_windows
) cw
       ON cw.filing = p.composition  AND cw.layer = p.composed_layer
WHERE pw.window_low IS NOT NULL
