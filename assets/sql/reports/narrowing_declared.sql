-- pm:Claim/pm:narrowsWhen on ranged pm:Demand, over the corpus.
SELECT count(*)                                                   AS ranged_demands,
       count(*) FILTER (WHERE r.demand_narrows IS NULL)           AS say_nothing,
       round(100.0 * count(*) FILTER (WHERE r.demand_narrows IS NULL)
             / nullif(count(*), 0))                               AS pct
FROM (
    -- pm:Claim on pm:Demand where low <> high.
SELECT d.*
FROM (
    -- from pm.layer; demandLow/Mode/High of pm:Layer/pm:Demand, and Claim/narrowsWhen.
SELECT l.filing, l.layer,
       l.demand_low  AS d_low,
       l.demand_mode AS d_mode,
       l.demand_high AS d_high,
       l.demand_unit AS d_unit,
       l.demand_low = l.demand_high AS is_a_point,
       l.demand_narrows,
       l.demand_narrows_kind,
       l.demand_narrows_absent
FROM pm.layer l
WHERE l.demand_low IS NOT NULL

) d
WHERE NOT d.is_a_point

) r
JOIN (
    -- from pm.filing where evidence = 'corpus'; the axis is documented on that column.
SELECT f.name AS filing, f.kind, f.evidence
FROM pm.filing f
WHERE f.evidence = 'corpus'

) s USING (filing)
