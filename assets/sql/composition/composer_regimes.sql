-- asrt:regime at the root of an asrt:composition, one row per declaration in document order.
SELECT r.composition, r.seq, r.id, r.jurisdiction,
       r.framework_taxonomy, r.framework_value, r.framework_absent,
       r.chart_taxonomy, r.chart_value, r.chart_absent
FROM pm.composition_regime r
