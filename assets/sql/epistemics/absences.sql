-- every pm:absent/reason in the schema, from every element that admits one.
SELECT filing, subject, question, reason FROM (
    SELECT filing, layer AS subject, 'demand'              AS question, absent                AS reason FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'demand'
    UNION ALL SELECT filing, layer, 'remainder sign',      sign_absent           FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder quantity',  qty_absent            FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'remainder absorber',  absorber_absent       FROM (
        SELECT * FROM layers.filed_remainders
    ) fr
    UNION ALL SELECT filing, layer, 'nameplate amount',    absent                FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'nameplate'
    UNION ALL SELECT filing, layer, 'divisibility',        divisibility_absent   FROM (
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

    ) f
    UNION ALL SELECT filing, layer, 'who committed the amount', amount_origin_absent FROM (
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

    ) f
    UNION ALL SELECT filing, layer, 'lump size',           quantum_absent        FROM (
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

    ) f
    UNION ALL SELECT filing, layer, 'measurement basis',   measurement_basis_absent FROM (
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

    ) f
    UNION ALL SELECT filing, layer, 'duty-cycle window',   window_absent         FROM (
        SELECT * FROM layers.windows
    ) w
    UNION ALL SELECT filing, layer, 'duty-cycle period',   window_size_absent    FROM (
        SELECT * FROM layers.windows
    ) w
    UNION ALL SELECT filing, layer, 'draw',                absent                FROM (
        SELECT * FROM layers.summed_quantities
    ) sq WHERE sq.quantity = 'draw'
    UNION ALL SELECT filing, layer || ' / ' || buffer::text, 'buffer slack',      absent    FROM (
        SELECT * FROM entries.slacks
    ) s
    UNION ALL SELECT filing, layer || ' / ' || kind::text,   'holder share',      share_absent FROM (
        SELECT * FROM entries.holders
    ) h
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation draw',       absent    FROM (
        SELECT * FROM entries.draws
    ) d
    UNION ALL SELECT filing, operation || ' / ' || layer, 'operation induction',  absent    FROM (
        SELECT * FROM entries.inductions
    ) i
    UNION ALL SELECT filing, label, 'where the operation is in a notation',
                     foreign_absent::pm.absence_reason FROM (
        SELECT * FROM entries.operations
    ) o
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'narrowsWhen',      narrows_absent FROM (
        SELECT * FROM epistemics.claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'boundOrigin',      origin_absent  FROM (
        SELECT * FROM epistemics.claims
    ) c
    UNION ALL SELECT filing, '(the stack)',   'how much of the system',           absent    FROM (
        SELECT * FROM epistemics.scopes
    ) sc
    UNION ALL SELECT filing, '(the stack)',   'did anybody look for couplings',   answer    FROM (
        SELECT * FROM epistemics.coupling_searches
    ) cs
    UNION ALL SELECT filing, '(the document)', 'its own notation',                absent    FROM (
        SELECT * FROM composition.notations
    ) n
    UNION ALL SELECT composition, composed_layer, 'did anybody look for double counting', answer FROM (
        SELECT * FROM eliminations.searched
    ) es
    UNION ALL SELECT composition, composed_layer || ' / ' || quantity, 'eliminated quantity', absent FROM (
        SELECT * FROM eliminations.filed
    ) e
    UNION ALL SELECT filing, layer, 'remainder',                        reason           FROM (
        SELECT * FROM layers.denied_remainders
    ) dr
    UNION ALL SELECT filing, layer, 'patience',                         patience_absent  FROM (
        SELECT * FROM layers.patience
    ) pa
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'denominator',         denominator_absent   FROM (
        SELECT * FROM epistemics.claims
    ) c
    UNION ALL SELECT filing, owns || ' claim ' || seq::text, 'provenance standing', prov_standing_absent FROM (
        SELECT * FROM epistemics.claims
    ) c
    UNION ALL SELECT filing, owns || ' absence ' || seq::text, 'provenance standing, on an absence',
                     prov_standing_absent FROM (
        SELECT * FROM epistemics.filed_absences
    ) fa
    UNION ALL SELECT filing, owns || ' derivation ' || seq::text,
                     'provenance standing, on a derivation', prov_standing_absent FROM (
        SELECT * FROM epistemics.filed_derivations
    ) fd
    UNION ALL SELECT filing, from_layer || ' -> ' || to_layer, 'coupling strength', strength_absent FROM (
        SELECT * FROM entries.couplings
    ) cp
    UNION ALL SELECT composition, composed_layer || ' / ' || part_filing || ' ' || part_layer,
                     'part factor', factor_absent FROM (
        SELECT * FROM composition.part_references
    ) pr
    UNION ALL SELECT filing,      'regime ' || id,      'regime framework',      framework_absent FROM (
        SELECT * FROM composition.regimes
    ) r
    UNION ALL SELECT filing,      'regime ' || id,      'regime chart',          chart_absent     FROM (
        SELECT * FROM composition.regimes
    ) r
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime framework', framework_absent FROM (
        SELECT * FROM composition.composer_regimes
    ) cr
    UNION ALL SELECT composition, 'part regime ' || id, 'part regime chart',     chart_absent     FROM (
        SELECT * FROM composition.composer_regimes
    ) cr
    UNION ALL SELECT filing,      '(the document)',     'what it is evidence for', evidence_absent FROM (
        SELECT * FROM scope.every_filing
    ) f
    UNION ALL SELECT filing,      '(the document)',     'assertion standing',    prov_standing_absent FROM (
        SELECT * FROM scope.every_filing
    ) f
) a
WHERE reason IS NOT NULL
