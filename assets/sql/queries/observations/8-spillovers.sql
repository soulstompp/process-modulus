-- §8  Layer pairs another document watched move together, held by a filing that has not looked.
-- entries/spillovers.sqlc, as referrals rather than findings.
SELECT s.borne_by                       AS "borne_by!",
       s.from_layer                     AS "from_layer!",
       s.to_layer                       AS "to_layer!",
       s.observed_in                    AS "observed_in!",
       coalesce(s.their_search::text, 'a coupling of its own') AS "their_search!",
       coalesce(s.their_extent, '')     AS "their_extent!"
FROM (
    SELECT * FROM entries.spillovers
) s
ORDER BY s.borne_by, s.from_layer, s.to_layer
