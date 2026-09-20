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
