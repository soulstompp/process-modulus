-- pm:Stack/pm:Coupling projected to its two ends; BPMN 2.0 tAssociation sourceRef/targetRef.
WITH
couplings AS NOT MATERIALIZED (
    -- pm:Stack/pm:couplings/pm:coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.strength_absent, c.observation
FROM pm.coupling c

)
SELECT c.filing, c.from_layer, c.to_layer
FROM (
    SELECT * FROM couplings
) c
