-- layers/remainder.sqlc against pm:Stack/pm:scope, pm:couplings/pm:absent and entries/spillovers.sqlc.
SELECT r.filing, r.layer,
       sc.extent,
       cs.answer AS search,
       sp.observed_in AS spilled_from,
       CASE WHEN sp.observed_in IS NOT NULL THEN 'takes a spillover'::public.remainder_standing
            WHEN sc.extent = 'unbounded'    THEN 'nobody bounded the set'::public.remainder_standing
            WHEN cs.answer  = 'unmeasured'  THEN 'set bounded, pairs untested'::public.remainder_standing
            ELSE 'bounded and the pairs answered'::public.remainder_standing END AS standing
FROM      (
    SELECT * FROM layers.remainder
) r
LEFT JOIN (
    SELECT * FROM epistemics.scopes
) sc ON sc.filing = r.filing
LEFT JOIN (
    SELECT * FROM epistemics.coupling_searches
) cs ON cs.filing = r.filing
LEFT JOIN ( SELECT DISTINCT borne_by, from_layer, observed_in FROM (
    SELECT * FROM entries.spillovers
) x ) sp ON sp.borne_by = r.filing AND sp.from_layer = r.layer
