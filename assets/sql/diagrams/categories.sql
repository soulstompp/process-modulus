-- pm:Operation/pm:Induction projected to the layers it reaches; BPMN 2.0 tCategoryValue.
WITH
inductions AS NOT MATERIALIZED (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

)
SELECT DISTINCT i.filing, i.layer
FROM (
    SELECT * FROM inductions
) i
