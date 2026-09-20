-- pm:Demand/pm:patience, beside the demand it qualifies.
SELECT l.filing, l.layer,
       l.patience_low, l.patience_mode, l.patience_high, l.patience_unit,
       l.patience_absent,
       l.demand_unit
FROM pm.layer l
