-- pm:Couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    -- pm:Stack/pm:Couplings/pm:Coupling, each carrying its pm:observed.
SELECT c.filing, c.from_layer, c.to_layer,
       c.low, c.mode, c.high, c.unit, c.observation
FROM pm.coupling c

) c
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    -- pm:Stack/pm:layer, keyed and nothing more.
SELECT l.filing, l.layer
FROM pm.layer l

) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    -- pm:Stack/pm:Couplings/pm:Absent, one row per filing asked.
SELECT cs.filing, cs.absent AS answer, cs.note
FROM pm.coupling_search cs

) s  ON s.filing = b.filing
LEFT JOIN (
    -- pm:Stack/pm:scope, with its pm:basis.
SELECT ss.filing, ss.extent, ss.basis, ss.absent
FROM pm.stack_scope ss

) sc ON sc.filing = b.filing
