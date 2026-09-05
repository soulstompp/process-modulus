-- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observation.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c
