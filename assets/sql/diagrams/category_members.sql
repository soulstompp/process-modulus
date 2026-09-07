-- pm:Operation/pm:Induction as incidence; BPMN 2.0 tFlowElement/categoryValueRef.
SELECT i.filing, i.operation, i.layer
FROM (
    -- pm:Operation/pm:Induction, carrying pm:decidedBy.
SELECT n.filing, n.operation, n.layer,
       n.low, n.mode, n.high, n.unit, n.absent, n.decider
FROM pm.induction n

) i
