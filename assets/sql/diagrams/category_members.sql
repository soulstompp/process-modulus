-- pm:Operation/pm:Induction as which layer, never how much; BPMN 2.0
-- tFlowElement/categoryValueRef.
WITH entries_inductions AS (
-- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n
)
SELECT i.filing, i.operation, i.layer
FROM (
    SELECT * FROM entries_inductions
) i
