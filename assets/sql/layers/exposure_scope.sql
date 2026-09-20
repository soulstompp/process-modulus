-- layers/remainder.sqlc where exposure > 0, classified by layers/absorption.sqlc.
SELECT r.*, a.absorbable, a.unknown,
       CASE WHEN a.unknown    > 0 THEN 'a buffer nobody sized'::public.exposure_standing
            WHEN a.absorbable > 0 THEN 'a buffer with room in it'::public.exposure_standing
            ELSE                       'every buffer sized and empty'::public.exposure_standing END AS standing
FROM      (
    SELECT * FROM layers.remainder
) r
JOIN      (
    -- pm:Nameplate/pm:capacitySlack and pm:inventorySlack with pm:Layer/pm:timeSlack, summed across the row in the demand's unit.
SELECT s.filing, s.layer,
       sum(coalesce(s.high, 0))
         FILTER (WHERE (s.sized AND s.unit IS NOT DISTINCT FROM d.d_unit)
                    OR s.absent = 'notApplicable')                                 AS absorbable,
       count(*)
         FILTER (WHERE (NOT s.sized AND s.absent IS DISTINCT FROM 'notApplicable')
                    OR (s.sized AND s.unit IS DISTINCT FROM d.d_unit))        AS unknown
FROM      (
    SELECT * FROM entries.slacks
) s
LEFT JOIN (
    SELECT * FROM layers.demand
) d ON d.filing = s.filing AND d.layer = s.layer
GROUP BY s.filing, s.layer

) a USING (filing, layer)
WHERE r.exposure > 1e-9
