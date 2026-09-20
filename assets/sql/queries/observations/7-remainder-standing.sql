-- §7  Every remainder, and what its filing established about the set it sits in.
-- public.remainder_standing, each member against layers/remainder_scope.sqlc.
SELECT s.standing::text AS "standing!", count(z.layer) AS "remainders!",
       coalesce(string_agg(DISTINCT z.filing, ', ' ORDER BY z.filing), '') AS "filings!"
FROM unnest(enum_range(NULL::public.remainder_standing)) AS s(standing)
LEFT JOIN (
    SELECT * FROM layers.remainder_scope
) z ON z.standing = s.standing
GROUP BY s.standing
ORDER BY count(z.layer) DESC, s.standing
