-- pm:Nameplate/amount unit, English or Portuguese edition.
SELECT n.filing, n.layer, n.amount_unit AS unit
FROM pm.nameplate n
WHERE n.amount_unit LIKE '% per %' OR n.amount_unit LIKE '% por %'
