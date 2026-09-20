-- pm:couplings/pm:coupling, projected onto every other filing holding both of its ends.
SELECT c.filing        AS observed_in,
       b.filing        AS borne_by,
       c.from_layer,
       c.to_layer,
       c.mode          AS observed_mode,
       c.unit          AS observed_unit,
       s.answer        AS their_search,
       sc.extent       AS their_extent
FROM      (
    SELECT * FROM entries.couplings
) c
JOIN      (
    SELECT * FROM layers.every_layer
) b  ON b.layer = c.from_layer AND b.filing <> c.filing
JOIN      (
    SELECT * FROM layers.every_layer
) b2 ON b2.filing = b.filing AND b2.layer = c.to_layer
LEFT JOIN (
    SELECT * FROM epistemics.coupling_searches
) s  ON s.filing = b.filing
LEFT JOIN (
    SELECT * FROM epistemics.scopes
) sc ON sc.filing = b.filing
